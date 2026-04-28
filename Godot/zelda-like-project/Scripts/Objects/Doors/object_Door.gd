@tool
@icon("res://Editor Tools/Icons/icon_door.svg")
##[b][color=yellow]Door[/color][/b] is a unified door: always a scene transition trigger, optionally requiring a key.[br]
##Set [b]direction[/b] to orient the door. Enable [b]locked[/b] to require a key before the player can pass.[br]
##The [b]DoorResource[/b] is inherited from the nearest [b]Level[/b] ancestor unless overridden locally.
class_name Door
extends InteractableComponent

#region ENUMS

enum WallDirection { UP, DOWN, LEFT, RIGHT }

#endregion ENUMS

#region EXPORTS

@export_group("Door Settings")
##Which wall this door is embedded in. Determines sprites and transition-target placement.
@export var direction: WallDirection = WallDirection.UP:
	set(v):
		direction = v
		_apply_layout()
		_update_visual()

##If true, a key is required to open this door before the player can pass through.
@export var locked: bool = false:
	set(v):
		locked = v
		notify_property_list_changed()
		_update_visual()
		if Engine.is_editor_hint() and is_inside_tree() \
		and not _target_scene_path.is_empty() and not _target_door_name.is_empty():
			_sync_partner_door()

##If true, this door requires the boss key and uses the level's boss_door_resource for visuals.
@export var boss_door: bool = false:
	set(v):
		boss_door = v
		if boss_door:
			locked = true
		notify_property_list_changed()
		if Engine.is_editor_hint() and is_inside_tree() \
		and not _target_scene_path.is_empty() and not _target_door_name.is_empty():
			_sync_partner_door()

##Pixels from the door to the spawn point used on arrival from another scene.
@export_range(10.0, 60.0) var distance: float = 30.0:
	set(v):
		distance = v
		_apply_layout()

@export_group("Locked Door Settings")
##RefID shown when the player interacts without a key.
@export var locked_ref_id: String = "doorLocked"
##RefID shown after the door finishes opening.
@export var unlocked_ref_id: String = "doorUnlocked"
##Override the Level ancestor's DoorResource. Leave null to inherit.
@export var door_resource: DoorResource:
	set(v):
		door_resource = v
		_update_visual()
##Seconds between animation frames during unlock and opening sequences.
@export var frame_time: float = 0.1

#endregion EXPORTS

#region VARIABLES

var _is_locked: bool = true
var _door_res: DoorResource

var _target_scene_path: String = ""
var _target_scene_obj: PackedScene = null
var _target_door_name: String = ""
var _target_door_rel_path: String = ""
var _triggered: bool = false
var _cached_door_names: PackedStringArray = []

#endregion VARIABLES

#region NODE REFERENCES

@onready var _door_sprite:          Sprite2D         = $DoorSprite
@onready var _door_block:           StaticBody2D     = $DoorBlock
@onready var _door_trans_collider:  Area2D           = $doorTransCollider
@onready var _trans_collider_shape: CollisionShape2D = $doorTransCollider/transCollider
@onready var _transition_target:    Node2D           = $transitionTarget
@onready var _debug_img:            Sprite2D         = $transitionTarget/transitionTargetDebugIMG

#endregion NODE REFERENCES

#region READY

func _ready() -> void:
	interact_type = InteractType.DOOR
	super._ready()

	if _debug_img:
		_debug_img.visible = Engine.is_editor_hint()

	if Engine.is_editor_hint():
		_apply_layout()
		_update_visual()
		if not _target_scene_path.is_empty():
			_refresh_door_cache()
		return

	add_to_group("transition_door")
	_apply_layout()
	_door_trans_collider.body_entered.connect(_on_trans_collider_body_entered)

	if locked:
		_door_res = door_resource if door_resource else _level_door_resource()
		_update_visual()
		_set_trans_trigger_enabled(false)
		doorManager.doors_restored.connect(_on_doors_restored)
		_on_doors_restored()
	else:
		_is_locked = false
		_door_res = door_resource if door_resource else _level_door_resource()
		_update_visual()
		set_active(false)
		if is_instance_valid(_door_block):
			_door_block.queue_free()

#endregion READY

#region VALIDATE PROPERTY

func _validate_property(property: Dictionary) -> void:
	var locked_only: Array[String] = ["locked_ref_id", "unlocked_ref_id", "door_resource", "frame_time"]
	if property.name in locked_only and not locked:
		property.usage = PROPERTY_USAGE_NO_EDITOR

#endregion VALIDATE PROPERTY

#region PUBLIC API

##Returns the cardinal exit direction derived from [member direction].
func get_exit_direction() -> Vector2:
	match direction:
		WallDirection.UP:    return Vector2.UP
		WallDirection.DOWN:  return Vector2.DOWN
		WallDirection.LEFT:  return Vector2.LEFT
		WallDirection.RIGHT: return Vector2.RIGHT
	return Vector2.UP

##Returns the direction from spawn point toward the transition target.
func get_target_direction_from_spawn() -> Vector2:
	return -get_exit_direction()

##Returns the global position of the transition trigger collider.
func get_spawn_position() -> Vector2:
	return _door_trans_collider.global_position

##Returns the global position of the transition target node.
func get_target_global_position() -> Vector2:
	return _transition_target.global_position

##Enables or disables the transition trigger collider using [code]set_deferred[/code].
func set_trigger_collider_enabled(enabled: bool) -> void:
	if _trans_collider_shape:
		_trans_collider_shape.set_deferred("disabled", not enabled)

##Clears the re-entry guard so this door can trigger again.
func reset_trigger() -> void:
	_triggered = false

#endregion PUBLIC API

#region INTERACT (LOCKED DOOR)

##Called by the interact state. Checks for a key and either starts the unlock or shows locked dialogue.
func interact(user: EntityClass = null) -> void:
	if not locked or not _is_locked:
		return
	var level := Level.get_level_ancestor(self)
	var key_id := _get_key_id(level)
	if user is Player and user.inventory.has_item(key_id):
		_start_unlock(user, key_id)
	else:
		_show_dialogue(locked_ref_id, user, func(): interaction_finished.emit())

func _get_key_id(level: Level) -> String:
	var in_dungeon := level and level.get_effective_type() == Level.LevelType.DUNGEON
	if boss_door:
		return (level.get_effective_name().to_lower() + "_" + ItemID.BOSS_KEY) if in_dungeon else ItemID.BOSS_KEY
	return (level.get_effective_name().to_lower() + "_key") if in_dungeon else ItemID.KEY

func _level_door_resource() -> DoorResource:
	var level := Level.get_level_ancestor(self)
	if not level:
		return null
	if boss_door:
		return level.get_effective_boss_door_resource()
	return level.get_effective_door_resource()

#endregion INTERACT (LOCKED DOOR)

#region UNLOCK SEQUENCE

func _start_unlock(user: EntityClass, key_id: String) -> void:
	if not boss_door:
		user.inventory.remove_item(key_id)
	if _door_res and _door_res.unlock_sound and not _door_res.unlock_sound.sounds.is_empty():
		audioManager.play(_door_res.unlock_sound.sounds.pick_random(), "Sound Effects")
	set_active(false)
	_animate(
		_door_res.get_unlocking_strip(direction) if _door_res else null,
		_door_res.unlocking_frames if _door_res else 1,
		_on_unlocking_done.bind(user)
	)

func _on_unlocking_done(user: EntityClass) -> void:
	if _door_res and _door_res.opening_sound and not _door_res.opening_sound.sounds.is_empty():
		audioManager.play(_door_res.opening_sound.sounds.pick_random(), "Sound Effects")
	_animate(
		_door_res.get_opening_strip(direction) if _door_res else null,
		_door_res.opening_frames if _door_res else 1,
		_on_opening_done.bind(user)
	)

func _on_opening_done(user: EntityClass) -> void:
	if _door_res and _door_res.opened_sound and not _door_res.opened_sound.sounds.is_empty():
		audioManager.play(_door_res.opened_sound.sounds.pick_random(), "Sound Effects")
	_apply_unlocked_state()
	doorManager.mark_unlocked(_get_door_id())
	var partner_id := _get_partner_door_id()
	if not partner_id.is_empty():
		doorManager.mark_unlocked(partner_id)
	_show_dialogue(unlocked_ref_id, user, func(): interaction_finished.emit())

#endregion UNLOCK SEQUENCE

#region ANIMATION

func _animate(strip: Texture2D, frame_count: int, callback: Callable) -> void:
	if not strip:
		callback.call()
		return
	_door_sprite.texture = strip
	_door_sprite.hframes = maxi(1, frame_count)
	_door_sprite.vframes = 1
	_door_sprite.frame = 0
	_advance_frame(1, maxi(1, frame_count), callback)

func _advance_frame(current: int, total: int, callback: Callable) -> void:
	if current >= total:
		callback.call()
		return
	get_tree().create_timer(frame_time).timeout.connect(
		func():
			_door_sprite.frame = current
			_advance_frame(current + 1, total, callback),
		CONNECT_ONE_SHOT
	)

#endregion ANIMATION

#region TRANSITION TRIGGER

func _on_trans_collider_body_entered(body: Node2D) -> void:
	if debug_me:
		print("[Door] '%s' trans collider entered by '%s' (parent='%s') _triggered=%s" % [
			name, body.name, body.get_parent().name, _triggered
		])
	var player: Node = body.get_parent()
	if not player.is_in_group("player"):
		return
	if _triggered:
		return
	_triggered = true
	if _target_scene_path.is_empty():
		push_warning("Door '%s': no target_scene_path assigned." % name)
		_triggered = false
		return
	if _target_door_name.is_empty():
		push_warning("Door '%s': no target_door_name set." % name)
		_triggered = false
		return
	if debug_me:
		print("[Door] '%s' triggered. exit_dir=%s target='%s'" % [name, get_exit_direction(), _target_door_name])
	call_deferred("_begin_transition", player, get_exit_direction())

func _begin_transition(player: Node, exit_dir: Vector2) -> void:
	var packed := load(_target_scene_path) as PackedScene
	if not packed:
		push_error("Door '%s': could not load scene '%s'." % [name, _target_scene_path])
		_triggered = false
		return
	get_node("/root/SceneTransitionManager").request_transition(player, packed, _target_door_name, exit_dir)

#endregion TRANSITION TRIGGER

#region STATE

func _apply_unlocked_state() -> void:
	_is_locked = false
	var unlocked_tex: Texture2D = _door_res.get_unlocked_sprite(direction) if _door_res else null
	if debug_me:
		print("[Door] '%s' _apply_unlocked_state: _door_res=%s unlocked_tex=%s sprite_valid=%s" % [
			name, _door_res, unlocked_tex, is_instance_valid(_door_sprite)
		])
	if unlocked_tex:
		_door_sprite.texture = unlocked_tex
		_door_sprite.hframes = 1
		_door_sprite.frame = 0
	else:
		_door_sprite.visible = false
	if is_instance_valid(_door_block):
		_door_block.queue_free()
	_set_trans_trigger_enabled(true)
	set_active(false)

func _update_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("DoorSprite")
	if not sprite:
		return
	var res := door_resource if door_resource else _level_door_resource()
	if not res:
		sprite.visible = false
		return
	var show_locked := locked if Engine.is_editor_hint() else _is_locked
	var tex: Texture2D = res.get_locked_sprite(direction) if show_locked \
		else res.get_unlocked_sprite(direction)
	if tex:
		sprite.texture = tex
		sprite.visible = true
	else:
		sprite.visible = false
	sprite.hframes = 1
	sprite.frame = 0

func _set_trans_trigger_enabled(enabled: bool) -> void:
	if debug_me:
		print("[Door] '%s' _set_trans_trigger_enabled(%s) shape_valid=%s" % [
			name, enabled, is_instance_valid(_trans_collider_shape)
		])
	if _trans_collider_shape:
		_trans_collider_shape.set_deferred("disabled", not enabled)

#endregion STATE

#region LAYOUT

func _apply_layout() -> void:
	if not is_node_ready():
		return
	if _door_sprite:
		match direction:
			WallDirection.UP:    _door_sprite.position = Vector2(0, -16)
			WallDirection.DOWN:  _door_sprite.position = Vector2(0, 16)
			WallDirection.LEFT:  _door_sprite.position = Vector2(-16, 0)
			WallDirection.RIGHT: _door_sprite.position = Vector2(16, 0)
	if is_instance_valid(_door_block):
		match direction:
			WallDirection.UP:    _door_block.position = Vector2(0, -10)
			WallDirection.DOWN:  _door_block.position = Vector2(0, 10)
			WallDirection.LEFT:  _door_block.position = Vector2(-10, 0)
			WallDirection.RIGHT: _door_block.position = Vector2(10, 0)
	if _transition_target:
		_transition_target.position = _compute_target_offset()
	if _door_trans_collider:
		match direction:
			WallDirection.UP:    _door_trans_collider.position = Vector2(0, -8)
			WallDirection.DOWN:  _door_trans_collider.position = Vector2(0, 8)
			WallDirection.LEFT:  _door_trans_collider.position = Vector2(-8, 0)
			WallDirection.RIGHT: _door_trans_collider.position = Vector2(8, 0)
	if _trans_collider_shape:
		_trans_collider_shape.rotation = PI / 2 \
			if direction in [WallDirection.LEFT, WallDirection.RIGHT] \
			else 0.0

func _compute_target_offset() -> Vector2:
	match direction:
		WallDirection.UP:    return Vector2(0, distance)
		WallDirection.DOWN:  return Vector2(0, -distance)
		WallDirection.LEFT:  return Vector2(distance, 0)
		WallDirection.RIGHT: return Vector2(-distance, 0)
	return Vector2.ZERO

#endregion LAYOUT

#region PERSISTENCE

func _on_doors_restored() -> void:
	if debug_me:
		print("[Door] '%s' _on_doors_restored: _is_locked=%s id='%s' manager_knows=%s" % [
			name, _is_locked, _get_door_id(), doorManager.is_unlocked(_get_door_id())
		])
	if not _is_locked:
		return
	if doorManager.is_unlocked(_get_door_id()):
		_apply_unlocked_state()

func _get_door_id() -> String:
	if not get_tree() or not get_tree().current_scene:
		return ""
	var root := get_tree().current_scene
	return root.scene_file_path + "::" + str(root.get_path_to(self))

func _get_partner_door_id() -> String:
	if _target_scene_path.is_empty() or _target_door_rel_path.is_empty():
		return ""
	return _target_scene_path + "::" + _target_door_rel_path

#endregion PERSISTENCE

#region DIALOGUE

func _show_dialogue(ref_id: String, user: EntityClass, on_closed: Callable) -> void:
	if ref_id.is_empty():
		on_closed.call()
		return
	var data := dialogueDB.get_dialogue_data(ref_id)
	if data.is_empty():
		on_closed.call()
		return
	if user is Player and user.player_ux and user.player_ux.dialogue_controller:
		var dc: DialogueUI = user.player_ux.dialogue_controller
		dc.start_dialogue(data, user.input)
		dc.dialogue_closed.connect(func(): on_closed.call(), CONNECT_ONE_SHOT)
	else:
		on_closed.call()

#endregion DIALOGUE

#region EDITOR TOOL — _set / _get

func _set(property: StringName, value: Variant) -> bool:
	if property == "target_scene":
		_target_scene_obj = value as PackedScene
		var raw := _target_scene_obj.resource_path if _target_scene_obj else ""
		_target_scene_path = _uid_to_res_path(raw)
		_cached_door_names.clear()
		_target_door_rel_path = ""
		notify_property_list_changed()
		if Engine.is_editor_hint() and is_inside_tree():
			call_deferred("_refresh_door_cache")
		if Engine.is_editor_hint() and is_inside_tree() \
		and not _target_scene_path.is_empty() and not _target_door_name.is_empty():
			_sync_partner_door()
		return true
	if property == "target_scene_path":
		_target_scene_path = _uid_to_res_path(value)
		_target_scene_obj = null
		_cached_door_names.clear()
		return true
	if property == "target_door_name":
		_target_door_name = value
		if Engine.is_editor_hint() and is_inside_tree() \
		and not str(value).is_empty() and not _target_scene_path.is_empty():
			_sync_partner_door()
		return true
	if property == "target_door_rel_path":
		_target_door_rel_path = value
		return true
	return false

func _get(property: StringName) -> Variant:
	if property == "target_scene":
		if _target_scene_obj == null and not _target_scene_path.is_empty():
			_target_scene_obj = load(_target_scene_path) as PackedScene
		return _target_scene_obj
	if property == "target_scene_path":
		return _target_scene_path
	if property == "target_door_name":
		return _target_door_name
	if property == "target_door_rel_path":
		return _target_door_rel_path
	return null

static func _uid_to_res_path(path: String) -> String:
	if not path.begins_with("uid://"):
		return path
	var uid: int = ResourceUID.text_to_id(path)
	if uid == ResourceUID.INVALID_ID:
		return path
	return ResourceUID.get_id_path(uid)

#endregion EDITOR TOOL — _set / _get

#region EDITOR TOOL — Partner door sync

func _sync_partner_door() -> void:
	if not is_inside_tree():
		return

	var current_scene_path: String = _uid_to_res_path(get_tree().edited_scene_root.scene_file_path)
	if current_scene_path.is_empty():
		push_warning("Door '%s': cannot write inverse — current scene is unsaved." % name)
		return
	if _target_scene_path.is_empty():
		push_warning("Door '%s': cannot write inverse — target_scene_path is empty." % name)
		return

	var target_packed := load(_target_scene_path) as PackedScene
	if not target_packed:
		push_warning("Door '%s': could not load '%s'." % [name, _target_scene_path])
		return
	var save_path: String = _uid_to_res_path(target_packed.resource_path)

	var target_root: Node = target_packed.instantiate()
	var target_door: Node = target_root.find_child(_target_door_name, true, false)
	if not target_door or not (target_door.get_script() != null \
	and target_door.get_script().resource_path.ends_with("object_Door.gd")):
		push_warning("Door '%s': door '%s' not found in '%s'." \
			% [name, _target_door_name, save_path.get_file()])
		target_root.free()
		return

	var my_rel_path := str(get_tree().edited_scene_root.get_path_to(self))
	_target_door_rel_path = str(target_root.get_path_to(target_door))

	target_door.set("target_scene_path", current_scene_path)
	target_door.set("target_door_name", name)
	target_door.set("target_door_rel_path", my_rel_path)
	target_door.set("locked", locked)
	target_door.set("boss_door", boss_door)

	var new_packed := PackedScene.new()
	if new_packed.pack(target_root) != OK:
		push_error("Door '%s': failed to pack '%s'." % [name, save_path.get_file()])
		target_root.free()
		return
	target_root.free()

	if ResourceSaver.save(new_packed, save_path) != OK:
		push_error("Door '%s': failed to save '%s'." % [name, save_path.get_file()])
		return

	if debug_me:
		print("[Door] Inverse set — '%s' in '%s' ↔ '%s' in '%s'." % [
			_target_door_name, save_path.get_file(), name, current_scene_path.get_file()
		])

	if save_path in EditorInterface.get_open_scenes():
		var active_root := EditorInterface.get_edited_scene_root()
		var active_path := _uid_to_res_path(active_root.scene_file_path) if active_root else ""
		if save_path != active_path:
			EditorInterface.call_deferred("reload_scene_from_path", save_path)

#endregion EDITOR TOOL — Partner door sync

#region EDITOR TOOL — Dynamic dropdown for target_door_name

func _refresh_door_cache() -> void:
	_cached_door_names.clear()
	if _target_scene_path.is_empty():
		notify_property_list_changed()
		return
	var target_packed := load(_target_scene_path) as PackedScene
	if not target_packed:
		notify_property_list_changed()
		return
	var instance := target_packed.instantiate()
	for node in instance.find_children("*", "", true, false):
		if node.get_script() != null \
		and node.get_script().resource_path.ends_with("object_Door.gd"):
			_cached_door_names.append(node.name)
	instance.free()
	notify_property_list_changed()

func _get_property_list() -> Array:
	var props: Array = [{
		"name":        "Transition Settings",
		"type":        TYPE_NIL,
		"hint_string": "",
		"usage":       PROPERTY_USAGE_GROUP,
	}]

	props.append({
		"name":        "target_scene",
		"type":        TYPE_OBJECT,
		"hint":        PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "PackedScene",
		"usage":       PROPERTY_USAGE_EDITOR,
	})
	props.append({
		"name":        "target_scene_path",
		"type":        TYPE_STRING,
		"hint":        PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage":       PROPERTY_USAGE_STORAGE,
	})
	props.append({
		"name":        "target_door_rel_path",
		"type":        TYPE_STRING,
		"hint":        PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage":       PROPERTY_USAGE_STORAGE,
	})

	if _target_scene_path.is_empty():
		return props

	if _cached_door_names.is_empty():
		props.append({
			"name":        "target_door_name",
			"type":        TYPE_STRING,
			"hint":        PROPERTY_HINT_NONE,
			"hint_string": "",
			"usage":       PROPERTY_USAGE_STORAGE,
		})
		return props

	props.append({
		"name":        "target_door_name",
		"type":        TYPE_STRING,
		"hint":        PROPERTY_HINT_ENUM,
		"hint_string": ",".join(_cached_door_names),
		"usage":       PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
	})
	return props

#endregion EDITOR TOOL — Dynamic dropdown for target_door_name
