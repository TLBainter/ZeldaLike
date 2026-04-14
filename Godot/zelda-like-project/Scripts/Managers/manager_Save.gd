##[b][color=cyan]SaveManager / saveManager[/color][/b] is an autoload that handles all game persistence.[br]
##It auto-saves whenever meaningful player state changes and exposes [b]save()[/b], [b]load_game()[/b],
##and [b]new_game()[/b] for manual control via the debug console.[br]
##[br]
##Call [b]register_player(player)[/b] from [b]Player._ready()[/b] to connect the player's component signals.
extends Node

#region CONSTANTS

const SAVE_DIR  : String = "user://.saves/"
const SAVE_PATH : String = "user://.saves/save.dat"
const FORMAT_VERSION : int = 1

#endregion CONSTANTS

#region VARIABLES

##Registered player node. Set via [method register_player].
var _player : Node = null

##True while a deferred save is queued to prevent redundant disk writes.
var _save_pending : bool = false

##True while [method _apply_data] is running; suppresses queued saves during stat restoration.
var _is_loading : bool = false

#endregion VARIABLES

#region READY

func _ready() -> void:
	SceneTransitionManager.transition_complete.connect(_on_transition_complete)
	containerManager.container_opened.connect(_on_container_opened)

#endregion READY

#region PUBLIC API

##Called by [b]Player._ready()[/b]. Stores the player reference and connects its component signals.[br]
func register_player(player : Node) -> void:
	if _is_loading:
		return
	_player = player
	_connect_player_signals(player)

##Writes the current game state to disk immediately.
func save() -> void:
	if not _player:
		push_warning("SaveManager: no player registered; skipping save.")
		return
	_ensure_save_dir()
	var data  : Dictionary = _collect_data()
	var bytes : PackedByteArray = var_to_bytes(data)
	var file  := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: could not open '%s' for writing." % SAVE_PATH)
		return
	file.store_buffer(bytes)

##Reads the save file and applies it to the player, then navigates to the last door.[br]
##Returns [b]false[/b] if no save file exists or the file is corrupted.
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: could not open '%s' for reading." % SAVE_PATH)
		return false
	var bytes : PackedByteArray = file.get_buffer(file.get_length())
	var data = bytes_to_var(bytes)
	if not data is Dictionary:
		push_error("SaveManager: save data is corrupted or unreadable.")
		return false
	_apply_data(data)
	return true

##Deletes the save file and restarts from the main scene.
func new_game() -> void:
	_is_loading  = false
	_save_pending = false
	_player = null
	containerManager.clear()
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove("save.dat")
	SceneTransitionManager.reset()
	var main_scene : String = ProjectSettings.get_setting("application/run/main_scene")
	get_tree().change_scene_to_file(main_scene)

##Returns [b]true[/b] if a save file exists on disk.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

##Returns [b]true[/b] while save data is being applied.[br]
func is_loading() -> bool:
	return _is_loading

#endregion PUBLIC API

#region AUTO-SAVE TRIGGERS

func _on_transition_complete() -> void:
	_is_loading = false
	save()

func _on_container_opened(_chest_id : String) -> void:
	save()

#endregion AUTO-SAVE TRIGGERS

#region DEBOUNCED SAVE

##Queues a save for the end of the current frame. Multiple calls in the same frame
##collapse into a single disk write.
func _queue_save() -> void:
	if _save_pending or _is_loading:
		return
	_save_pending = true
	call_deferred("_do_deferred_save")

func _do_deferred_save() -> void:
	_save_pending = false
	save()

#endregion DEBOUNCED SAVE

#region SIGNAL CONNECTIONS

func _connect_player_signals(player : Node) -> void:
	if player.health:
		player.health.health_changed.connect(func(_cur, _max, _chng): _queue_save())
	if player.magic:
		player.magic.magic_changed.connect(func(_cur, _max, _chng): _queue_save())
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
			# Use scene_file_path for a guaranteed res:// path; resource_path can return uid:// in Godot 4.
			"scene_path"    : current_scene.scene_file_path if current_scene else "",
			"door_name"     : SceneTransitionManager.get_last_door_name(),
			"exit_walk_dir" : SceneTransitionManager.get_last_exit_walk_dir(),
		},
		"health" : {
			"cur" : _player.health.cur_health,
			"max" : _player.health.max_health,
		},
		"magic" : {
			"cur"          : _player.magic.cur_magic,
			"total_shards" : _player.magic.total_shards,
		},
		"currency" : {
			"cur" : _player.currency.cur_notes,
			"max" : _player.currency.max_notes,
		},
		"inventory"   : _player.inventory.get_all_items().duplicate(),
		"containers"  : containerManager.get_all_opened(),
	}

#endregion COLLECT DATA

#region APPLY DATA

func _apply_data(data : Dictionary) -> void:
	if not _player:
		push_error("SaveManager: no player registered; cannot apply save data.")
		return

	if data.get("version", 0) != FORMAT_VERSION:
		push_error("SaveManager: save version mismatch (expected %d, got %d); aborting load." \
				% [FORMAT_VERSION, data.get("version", 0)])
		return

	_is_loading = true

	# --- Health ---
	var h : Dictionary = data.get("health", {})
	_player.health.max_health = h.get("max", _player.health.max_health)
	_player.health.cur_health = h.get("cur", _player.health.cur_health)

	# --- Magic ---
	# max_magic is always derived from total_shards; it is not stored in the save file.
	var m : Dictionary = data.get("magic", {})
	_player.magic.total_shards = m.get("total_shards", _player.magic.total_shards)
	_player.magic.max_magic    = _player.magic.total_shards
	_player.magic.cur_magic    = m.get("cur", _player.magic.cur_magic)

	# --- Currency ---
	var c : Dictionary = data.get("currency", {})
	_player.currency.max_notes = c.get("max", _player.currency.max_notes)
	_player.currency.cur_notes = c.get("cur", _player.currency.cur_notes)

	# --- Inventory ---
	var inv : Dictionary = data.get("inventory", {})
	_player.inventory.clear_inventory()
	for item_id : String in inv:
		_player.inventory.add_item(item_id, inv[item_id])

	# --- Containers ---
	containerManager.restore_opened(data.get("containers", {}))

	# --- Navigate to last door ---
	var t          : Dictionary = data.get("last_transition", {})
	var scene_path : String     = t.get("scene_path", "")
	var door_name  : String     = t.get("door_name", "")
	var exit_dir   : Vector2    = t.get("exit_walk_dir", Vector2.DOWN)

	if scene_path.is_empty() or door_name.is_empty():
		push_warning("SaveManager: no last transition data in save; skipping scene navigation.")
		_is_loading = false
		return

	var packed := load(scene_path) as PackedScene
	if not packed:
		push_error("SaveManager: could not load saved scene '%s'." % scene_path)
		_is_loading = false
		return

	# _is_loading stays true until _on_transition_complete fires after arrival.
	SceneTransitionManager.request_transition(_player, packed, door_name, exit_dir)

#endregion APPLY DATA

#region HELPERS

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

#endregion HELPERS
