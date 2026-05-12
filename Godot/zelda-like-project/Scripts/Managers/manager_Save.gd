##[b][color=cyan]SaveManager / saveManager[/color][/b] is an autoload that handles all game persistence.[br]
##Supports up to [constant SLOT_COUNT] save slots. Each slot stores player stats, world state, and metadata.[br]
##[br]
##Call [b]register_player(player)[/b] from [b]Player._ready()[/b] to connect the player's component signals.
extends Node

#region CONSTANTS

const SAVE_DIR           : String = "user://.saves/"
const SAVE_PATH_TEMPLATE : String = "user://.saves/save_%d.dat"
const FORMAT_VERSION     : int    = 1
const SLOT_COUNT         : int    = 6
## Path to the first gameplay scene. Update when a proper first level exists.
const GAME_START_SCENE   : String = "res://Scenes/Levels/Test/TestingArea.tscn"

#endregion CONSTANTS

#region VARIABLES

var _player            : Node       = null
var _active_slot       : int        = -1
var _play_time         : float      = 0.0
var _play_time_running : bool       = false
var _char_name         : String     = ""
var _difficulty        : String     = ""
var _save_pending      : bool       = false
var _is_loading        : bool       = false
var _pending_new_game_save : bool   = false
## Non-empty when load_game() was called with no player in scene (e.g. from main menu).
## Consumed by register_player() to apply player stats after the scene change lands.
var _pending_load_data : Dictionary = {}
## The last door through which the player entered a level that has it listed in level_entrances.
## Used on reload to always land in the parent level, not wherever the player last saved.
var _parent_entrance   : Dictionary = {}

#endregion VARIABLES

#region READY

func _ready() -> void:
	SceneTransitionManager.transition_complete.connect(_on_transition_complete)
	containerManager.container_opened.connect(_on_container_opened)
	doorManager.door_unlocked.connect(func(_id: String): save())
	destructibleManager.destructible_destroyed.connect(func(_id: String): _queue_save())
	enemyManager.enemy_killed.connect(func(_id: String): _queue_save())

#endregion READY

#region PROCESS

func _process(delta: float) -> void:
	if _play_time_running and _player != null:
		_play_time += delta

#endregion PROCESS

#region PUBLIC API

##Called by [b]Player._ready()[/b]. Stores the player reference and connects its component signals.[br]
##Also consumes any pending load data when [b]load_game()[/b] was called before a player existed.
func register_player(player : Node) -> void:
	_player = player
	_connect_player_signals(player)
	if SceneTransitionManager.is_transitioning:
		return
	if not _pending_load_data.is_empty():
		_apply_player_stats(_pending_load_data)

		# Tier 1: use the recorded parent entrance (the door through which we last entered the parent level).
		var pe         : Dictionary = _pending_load_data.get("parent_entrance", {})
		var scene_path : String     = pe.get("scene_path", "")
		var door_name  : String     = pe.get("door_name", "")
		_pending_load_data = {}

		if not scene_path.is_empty() and not door_name.is_empty():
			SceneTransitionManager.load_transition.call_deferred(player, load(scene_path) as PackedScene, door_name)
			return

		# Tier 2: no parent entrance saved — use the current level's default_entrance.
		var root  := get_tree().current_scene
		var level := _find_level_in_scene(root)
		if level and not level.default_entrance.is_empty():
			var default_door := level.get_node_or_null(level.default_entrance)
			if default_door and not root.scene_file_path.is_empty():
				SceneTransitionManager.load_transition.call_deferred(
					player, load(root.scene_file_path) as PackedScene, default_door.name)
				return

		# Tier 3: snap fallback (no door data at all).
		_is_loading = false
		_play_time_running = true
		save()
		return
	if _is_loading:
		return
	_play_time_running = true
	if _pending_new_game_save:
		_pending_new_game_save = false
		save()

##Writes the current game state to disk immediately.
func save() -> void:
	if _active_slot == -1:
		push_warning("SaveManager: no active slot; skipping save.")
		return
	if not is_instance_valid(_player):
		push_warning("SaveManager: no player registered; skipping save.")
		return
	_ensure_save_dir()
	var data  : Dictionary      = _collect_data()
	var bytes : PackedByteArray = var_to_bytes(data)
	var file  := FileAccess.open(_save_path(_active_slot), FileAccess.WRITE)
	if not file:
		push_error("SaveManager: could not open '%s' for writing." % _save_path(_active_slot))
		return
	file.store_buffer(bytes)

##Reads the save file for [param slot] without applying it.[br]
##Returns an empty [Dictionary] if the slot is empty or the file is corrupted.
func read_save_data(slot: int) -> Dictionary:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var bytes := file.get_buffer(file.get_length())
	var data = bytes_to_var(bytes)
	if not data is Dictionary:
		return {}
	return data

##Loads save [param slot] and transitions to the saved scene.[br]
##Works from any context, including the main menu (no player in scene).[br]
##Returns [b]false[/b] if no save exists or the file is corrupted.
func load_game(slot: int = -1) -> bool:
	var s : int = slot if slot >= 0 else _active_slot
	if s < 0:
		return false
	var data := read_save_data(s)
	if data.is_empty():
		return false
	if data.get("version", 0) != FORMAT_VERSION:
		push_error("SaveManager: save version mismatch (expected %d, got %d); aborting load." \
				% [FORMAT_VERSION, data.get("version", 0)])
		return false
	_active_slot = s
	_is_loading  = true
	var meta : Dictionary = data.get("metadata", {})
	_char_name  = meta.get("character_name", "")
	_difficulty = meta.get("difficulty", "")
	_play_time  = meta.get("play_time", 0.0)
	containerManager.restore_opened(data.get("containers", {}))
	doorManager.restore_unlocked(data.get("doors", {}))
	destructibleManager.restore_destroyed(data.get("destructibles", {}))
	enemyManager.restore_data(data.get("enemies", {}))
	enemyManager.on_game_reload()
	if _player:
		_apply_data(data)
	else:
		var t          : Dictionary = data.get("last_transition", {})
		var scene_path : String     = t.get("scene_path", "")
		if scene_path.is_empty():
			push_warning("SaveManager: no scene path in save; cannot navigate.")
			_is_loading = false
			return false
		_pending_load_data = data
		get_tree().change_scene_to_file(GAME_START_SCENE)
	return true

##Starts a fresh game in [param slot] with the given character name and difficulty.[br]
##Clears all world state and navigates to [constant GAME_START_SCENE].
func start_new_game(slot: int, char_name: String, difficulty: String) -> void:
	_is_loading          = false
	_save_pending        = false
	_play_time_running   = false
	_play_time           = 0.0
	_player              = null
	_active_slot         = slot
	_char_name           = char_name
	_difficulty          = difficulty
	_pending_new_game_save = true
	_pending_load_data   = {}
	_parent_entrance     = {}
	containerManager.clear()
	doorManager.clear()
	destructibleManager.clear()
	enemyManager.clear()
	SceneTransitionManager.reset()
	get_tree().change_scene_to_file(GAME_START_SCENE)

##Called by [b]SceneTransitionManager[/b] after a carried player is placed in the new scene.[br]
##Updates the tracked player reference without triggering load or save logic.[br]
##Necessary because the new scene may have an embedded Player whose [b]_ready[/b] fires first,[br]
##overwriting [member _player] with a node that is immediately [b]queue_free[/b]d.
func on_player_carried(player: Node) -> void:
	_player = player

##Deletes the save file for [param slot].
func delete_save(slot: int) -> void:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.remove("save_%d.dat" % slot)

##Returns [b]true[/b] if [param slot] has a save file on disk.[br]
##Pass [b]-1[/b] (default) to check the currently active slot.
func has_save(slot: int = -1) -> bool:
	var s : int = slot if slot != -1 else _active_slot
	if s == -1:
		return false
	return FileAccess.file_exists(_save_path(s))

##Returns [b]true[/b] if any of the [constant SLOT_COUNT] slots has a save file.
func has_any_save() -> bool:
	for i in SLOT_COUNT:
		if FileAccess.file_exists(_save_path(i)):
			return true
	return false

##Returns [b]true[/b] while save data is being applied.
func is_loading() -> bool:
	return _is_loading

##Debug console alias — starts a new game on slot 0 with default settings.
func new_game() -> void:
	start_new_game(0, "Debug", "Standard")

#endregion PUBLIC API

#region AUTO-SAVE TRIGGERS

func _on_transition_complete() -> void:
	_update_parent_entrance()
	_is_loading = false
	_play_time_running = _player != null
	save()

func _on_container_opened(_chest_id : String) -> void:
	save()

#endregion AUTO-SAVE TRIGGERS

#region DEBOUNCED SAVE

##Queues a save for the end of the current frame. Multiple calls in the same frame
##collapse into a single disk write.
func _queue_save() -> void:
	if _save_pending or _is_loading or not is_instance_valid(_player):
		return
	_save_pending = true
	call_deferred("_do_deferred_save")

func _do_deferred_save() -> void:
	_save_pending = false
	if not is_instance_valid(_player) or _is_loading:
		return
	save()

#endregion DEBOUNCED SAVE

#region SIGNAL CONNECTIONS

func _connect_player_signals(player : Node) -> void:
	if player.health:
		player.health.health_changed.connect(func(_cur, _max, _chng): _queue_save())
	if player.magic:
		player.magic.magic_changed.connect(func(_cur, _max, _chng): _queue_save())
	if player.energy:
		player.energy.energy_changed.connect(func(_cur, _max, _chng): _queue_save())
	if player.currency:
		player.currency.notes_changed.connect(func(_cur, _max, _chng): _queue_save())
	if player.inventory:
		player.inventory.inventory_changed.connect(func(_id, _qty): _queue_save())

#endregion SIGNAL CONNECTIONS

#region COLLECT DATA

func _collect_data() -> Dictionary:
	var current_scene := get_tree().current_scene
	return {
		"version"         : FORMAT_VERSION,
		"last_transition" : {
			"scene_path"    : current_scene.scene_file_path if current_scene else "",
			"door_name"     : SceneTransitionManager.get_last_door_name(),
			"exit_walk_dir" : SceneTransitionManager.get_last_exit_walk_dir(),
		},
		"parent_entrance" : _parent_entrance,
		"metadata" : {
			"character_name" : _char_name,
			"difficulty"     : _difficulty,
			"play_time"      : _play_time,
			"location_name"  : _get_location_name(),
			"max_health"     : _player.health.max_health,
			"max_energy"     : _player.energy.max_energy if _player.energy else 0,
			"total_shards"   : _player.magic.total_shards,
			"inventory"      : _player.inventory.get_all_items().duplicate(),
		},
		"health" : {
			"cur" : _player.health.cur_health,
			"max" : _player.health.max_health,
		},
		"magic" : {
			"cur"          : _player.magic.cur_magic,
			"total_shards" : _player.magic.total_shards,
		},
		"energy" : {
			"cur" : _player.energy.cur_energy if _player.energy else 0,
			"max" : _player.energy.max_energy if _player.energy else 0,
		},
		"currency" : {
			"cur" : _player.currency.cur_notes,
			"max" : _player.currency.max_notes,
		},
		"inventory"     : _player.inventory.get_all_items().duplicate(),
		"containers"    : containerManager.get_all_opened(),
		"doors"         : doorManager.get_all_unlocked(),
		"destructibles" : destructibleManager.get_all_destroyed(),
		"enemies"       : enemyManager.get_save_data(),
	}

func _get_location_name() -> String:
	var root := get_tree().current_scene
	if not root:
		return ""
	var level := _find_level_in_scene(root)
	return level.get_effective_name() if level else ""

#endregion COLLECT DATA

#region APPLY DATA

func _apply_data(data : Dictionary) -> void:
	if not _player:
		push_error("SaveManager: no player registered; cannot apply save data.")
		return
	_is_loading = true
	_apply_player_stats(data)

	# Prefer the parent entrance; fall back to last_transition for old saves.
	var pe         : Dictionary = data.get("parent_entrance", {})
	var scene_path : String     = pe.get("scene_path", "")
	var door_name  : String     = pe.get("door_name", "")
	if scene_path.is_empty() or door_name.is_empty():
		var t : Dictionary = data.get("last_transition", {})
		scene_path = t.get("scene_path", "")
		door_name  = t.get("door_name", "")

	if scene_path.is_empty() or door_name.is_empty():
		push_warning("SaveManager: no parent_entrance or last_transition data in save; skipping scene navigation.")
		_is_loading = false
		return
	var packed := load(scene_path) as PackedScene
	if not packed:
		push_error("SaveManager: could not load saved scene '%s'." % scene_path)
		_is_loading = false
		return
	# _is_loading stays true until _on_transition_complete fires after arrival.
	SceneTransitionManager.request_transition(_player, packed, door_name, Vector2.DOWN)

func _apply_player_stats(data : Dictionary) -> void:
	var h : Dictionary = data.get("health", {})
	_player.health.max_health = h.get("max", _player.health.max_health)
	_player.health.cur_health = h.get("cur", _player.health.cur_health)
	var low_hp : int = clampi(int(floor(_player.health.max_health * 0.25)), 4, 15)
	if _player.health.cur_health < low_hp:
		_player.health.cur_health = low_hp + 4

	var m : Dictionary = data.get("magic", {})
	_player.magic.total_shards = m.get("total_shards", _player.magic.total_shards)
	_player.magic.max_magic    = _player.magic.total_shards
	_player.magic.cur_magic    = _player.magic.max_magic

	if _player.energy:
		var e : Dictionary = data.get("energy", {})
		_player.energy.max_energy = e.get("max", _player.energy.max_energy)
		_player.energy.is_exhausted_state = false
		_player.energy.cur_energy = _player.energy.max_energy

	var c : Dictionary = data.get("currency", {})
	_player.currency.max_notes = c.get("max", _player.currency.max_notes)
	_player.currency.cur_notes = c.get("cur", _player.currency.cur_notes)

	var inv : Dictionary = data.get("inventory", {})
	_player.inventory.clear_inventory()
	for item_id : String in inv:
		_player.inventory.add_item(item_id, inv[item_id])

func _position_at_door(t : Dictionary) -> void:
	var door_name : String = t.get("door_name", "")
	if door_name.is_empty() or not _player:
		return
	var root := get_tree().current_scene
	if not root:
		return
	var door : Node = root.find_child(door_name, true, false)
	if door and door.has_method("get_spawn_position"):
		_player.body.global_position = door.get_spawn_position()

#endregion APPLY DATA

#region HELPERS

func _save_path(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _find_level_in_scene(root: Node) -> Level:
	if root is Level:
		return root as Level
	var results := root.find_children("*", "Level", true, false)
	if not results.is_empty():
		return results[0] as Level
	return null

## Checks whether the door we just arrived at is listed in the current level's
## [member Level.level_entrances]. If so, records it as the parent entrance for reload.
func _update_parent_entrance() -> void:
	var root := get_tree().current_scene
	if not root:
		return
	var level := _find_level_in_scene(root)
	if not level or level.level_entrances.is_empty():
		return
	var door_name := SceneTransitionManager.get_last_door_name()
	if door_name.is_empty():
		return
	for np: NodePath in level.level_entrances:
		var door := level.get_node_or_null(np)
		if door and door.name == door_name:
			_parent_entrance = {
				"scene_path": root.scene_file_path,
				"door_name":  door_name,
			}
			return

#endregion HELPERS
