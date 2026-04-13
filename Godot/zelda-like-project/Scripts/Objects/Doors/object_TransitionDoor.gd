##[b][color=yellow]TransitionDoor[/color][/b] is the script for a door that transitions the player to another scene.
@tool
class_name TransitionDoor
extends Node2D

#region EXPORTS
@export_group("Transition Settings")
## The target scene and door name are managed via [method _get_property_list] so the inspector
## shows a drag-drop [PackedScene] slot while the .tscn file stores only a string path —
## avoiding the circular resource dependency a plain @export PackedScene creates on
## bidirectionally-linked doors.

## Runtime path (res://…). Persisted to .tscn via [method _get_property_list]; never shown in inspector.
var _target_scene_path : String = ""
## Editor display cache — holds the [PackedScene] object for the inspector drag-drop slot.
## NOT persisted; reconstructed lazily from [member _target_scene_path].
var _target_scene_obj  : PackedScene = null

## The name of the [TransitionDoor] node in the target scene the player arrives at.
var _target_door_name : String = ""

@export_group("Arrival Settings")
##Local position of the transition target point.
@export var point_location : Vector2 = Vector2(0, 25) :
	set(value):
		point_location = value
		if is_node_ready() and transition_target:
			transition_target.position = value

@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
#endregion EXPORTS

#region NODE REFERENCES
@onready var door_trans_collider  : Area2D          = $doorTransCollider
@onready var trans_collider_shape : CollisionShape2D = $doorTransCollider/transCollider
@onready var transition_target    : Node2D           = $transitionTarget
@onready var debug_img            : Sprite2D         = $transitionTarget/transitionTargetDebugIMG
#endregion NODE REFERENCES

#region READY
func _ready() -> void:
	# Debug sprite visible in editor only
	if debug_img:
		debug_img.visible = Engine.is_editor_hint()

	if Engine.is_editor_hint():
		# Apply point_location so the target moves in the editor viewport on first load
		if transition_target:
			transition_target.position = point_location
		return

	add_to_group("transition_door")
	transition_target.position = point_location
	door_trans_collider.body_entered.connect(_on_trans_collider_body_entered)

	if debug_me:
		print("[TransitionDoor] '%s' ready. target_door_name='%s'" % [name, _target_door_name])
#endregion READY

#region SIGNAL HANDLER
## GDScript-level re-entry guard. Set before any physics calls so it's safe
## to check even during body_entered (which fires mid-physics-flush).
var _triggered : bool = false

func _on_trans_collider_body_entered(body : Node2D) -> void:
	# body_entered fires with CharacterBody2D; the Player Node2D is its parent
	var player : Node = body.get_parent()
	if not player.is_in_group("player"):
		return

	if _triggered:
		return
	_triggered = true

	if _target_scene_path.is_empty():
		push_warning("TransitionDoor '%s': no target_scene_path assigned." % name)
		_triggered = false
		return
	if _target_door_name.is_empty():
		push_warning("TransitionDoor '%s': no target_door_name set." % name)
		_triggered = false
		return

	if debug_me:
		print("[TransitionDoor] '%s' triggered. exit_dir=%s target='%s'" % [name, get_exit_direction(), _target_door_name])

	call_deferred("_begin_transition", player, get_exit_direction())

func _begin_transition(player : Node, exit_dir : Vector2) -> void:
	var packed := load(_target_scene_path) as PackedScene
	if not packed:
		push_error("TransitionDoor '%s': could not load scene '%s'." % [name, _target_scene_path])
		_triggered = false
		return
	get_node("/root/SceneTransitionManager").request_transition(player, packed, _target_door_name, exit_dir)
#endregion SIGNAL HANDLER

#region PUBLIC API
##Enables or disables the transition trigger collider using [code]set_deferred[/code].
func set_trigger_collider_enabled(enabled : bool) -> void:
	if trans_collider_shape:
		trans_collider_shape.set_deferred("disabled", not enabled)

##Clears the re-entry guard so this door can trigger again.[br]
func reset_trigger() -> void:
	_triggered = false

##Returns the global position of the transition trigger — used as the player spawn point on arrival.
func get_spawn_position() -> Vector2:
	return door_trans_collider.global_position

##Returns the global position of the transition target — the point the player walks toward on arrival.
func get_target_global_position() -> Vector2:
	return transition_target.global_position

##Returns the normalised direction from the transition target toward the spawn point.[br]
func get_exit_direction() -> Vector2:
	var raw_dir := door_trans_collider.global_position - transition_target.global_position
	if raw_dir == Vector2.ZERO:
		return Vector2.UP
	if abs(raw_dir.x) >= abs(raw_dir.y):
		return Vector2(sign(raw_dir.x), 0)
	return Vector2(0, sign(raw_dir.y))

##Returns the normalised direction from the spawn point toward the transition target.[br]
func get_target_direction_from_spawn() -> Vector2:
	var delta := transition_target.global_position - door_trans_collider.global_position
	if delta == Vector2.ZERO:
		return Vector2.DOWN
	# Snap to cardinal
	if abs(delta.x) >= abs(delta.y):
		return Vector2(sign(delta.x), 0)
	return Vector2(0, sign(delta.y))
#endregion PUBLIC API

#region EDITOR TOOL — _set / _get for _get_property_list properties
## Required in Godot 4: properties added via _get_property_list() are routed through _set/_get.
func _set(property : StringName, value : Variant) -> bool:
	if property == "target_scene":
		_target_scene_obj  = value as PackedScene
		# resource_path can return uid:// in Godot 4 — always store as res://.
		var raw := _target_scene_obj.resource_path if _target_scene_obj else ""
		_target_scene_path = _uid_to_res_path(raw)
		notify_property_list_changed()   # rebuild target_door_name dropdown
		if Engine.is_editor_hint() and is_inside_tree() \
		and not _target_scene_path.is_empty() and not _target_door_name.is_empty():
			_write_inverse()
		return true
	if property == "target_scene_path":
		# Called when the scene is loaded from disk. Normalize uid:// → res://.
		# Do NOT call notify_property_list_changed() here — it causes a setter
		# feedback loop where Godot round-trips all stored properties through _set().
		_target_scene_path = _uid_to_res_path(value)
		_target_scene_obj  = null   # clear cache; re-populated lazily in _get
		return true
	if property == "target_door_name":
		_target_door_name = value
		if Engine.is_editor_hint() and is_inside_tree() \
		and not str(value).is_empty() and not _target_scene_path.is_empty():
			_write_inverse()
		return true
	return false

func _get(property : StringName) -> Variant:
	if property == "target_scene":
		if _target_scene_obj == null and not _target_scene_path.is_empty():
			_target_scene_obj = load(_target_scene_path) as PackedScene
		return _target_scene_obj
	if property == "target_scene_path":
		return _target_scene_path
	if property == "target_door_name":
		return _target_door_name
	return null

## Converts a uid:// identifier to its res:// filesystem path.
## resource_path on a freshly-loaded resource returns uid:// in some Godot 4 builds;
## ResourceSaver.save() requires a res:// path so we always normalise before storing.
static func _uid_to_res_path(path : String) -> String:
	if not path.begins_with("uid://"):
		return path
	var uid : int = ResourceUID.text_to_id(path)
	if uid == ResourceUID.INVALID_ID:
		return path
	return ResourceUID.get_id_path(uid)
#endregion EDITOR TOOL — _set / _get for _get_property_list properties

#region EDITOR TOOL — Inverse connection writer
## Writes the reverse connection back to the target door's scene file automatically.
func _write_inverse() -> void:
	if not is_inside_tree():
		return

	var current_scene_path : String = _uid_to_res_path(get_tree().edited_scene_root.scene_file_path)
	if current_scene_path.is_empty():
		push_warning("TransitionDoor '%s': cannot write inverse — current scene is unsaved." % name)
		return

	if _target_scene_path.is_empty():
		push_warning("TransitionDoor '%s': cannot write inverse — target_scene_path is empty." % name)
		return

	var target_packed := load(_target_scene_path) as PackedScene
	if not target_packed:
		push_warning("TransitionDoor '%s': could not load '%s'." % [name, _target_scene_path])
		return
	# Normalise save path: resource_path may still be uid:// on some Godot 4 builds.
	var save_path : String = _uid_to_res_path(target_packed.resource_path)

	var target_root : Node = target_packed.instantiate()

	var target_door : Node = target_root.find_child(_target_door_name, true, false)
	if not target_door or not (target_door.get_script() != null \
	and target_door.get_script().resource_path.ends_with("object_TransitionDoor.gd")):
		push_warning("TransitionDoor '%s': door '%s' not found in '%s'." \
			% [name, _target_door_name, save_path.get_file()])
		target_root.free()
		return

	target_door.set("target_scene_path", current_scene_path)
	target_door.set("target_door_name", name)

	var new_packed := PackedScene.new()
	if new_packed.pack(target_root) != OK:
		push_error("TransitionDoor '%s': failed to pack '%s'." % [name, save_path.get_file()])
		target_root.free()
		return
	target_root.free()

	if ResourceSaver.save(new_packed, save_path) != OK:
		push_error("TransitionDoor '%s': failed to save '%s'." % [name, save_path.get_file()])
		return

	if debug_me:
		print("[TransitionDoor] Inverse set — '%s' in '%s' ↔ '%s' in '%s'." % [
			_target_door_name, save_path.get_file(), name, current_scene_path.get_file()
		])
#endregion EDITOR TOOL — Inverse connection writer

#region EDITOR TOOL — Dynamic dropdown for target_door_name
func _get_property_list() -> Array:
	var props : Array = [{
		"name"        : "Transition Settings",
		"type"        : TYPE_NIL,
		"hint_string" : "",
		"usage"       : PROPERTY_USAGE_GROUP,
	}]

	# Inspector drag-drop slot — shown but NOT saved (string path is saved instead).
	props.append({
		"name"        : "target_scene",
		"type"        : TYPE_OBJECT,
		"hint"        : PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string" : "PackedScene",
		"usage"       : PROPERTY_USAGE_EDITOR,
	})
	# String path — saved to .tscn but NOT shown in inspector.
	props.append({
		"name"        : "target_scene_path",
		"type"        : TYPE_STRING,
		"hint"        : PROPERTY_HINT_NONE,
		"hint_string" : "",
		"usage"       : PROPERTY_USAGE_STORAGE,
	})

	if _target_scene_path.is_empty():
		return props

	var target_packed := load(_target_scene_path) as PackedScene
	if not target_packed:
		return props

	# Instantiate the scene temporarily to discover its TransitionDoor nodes.
	var instance := target_packed.instantiate()
	var names : PackedStringArray = []
	for node in instance.find_children("*", "", true, false):
		if node.get_script() != null \
		and node.get_script().resource_path.ends_with("object_TransitionDoor.gd"):
			names.append(node.name)
	instance.free()

	if names.is_empty():
		return props

	props.append({
		"name"        : "target_door_name",
		"type"        : TYPE_STRING,
		"hint"        : PROPERTY_HINT_ENUM,
		"hint_string" : ",".join(names),
		"usage"       : PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
	})
	return props
#endregion EDITOR TOOL
