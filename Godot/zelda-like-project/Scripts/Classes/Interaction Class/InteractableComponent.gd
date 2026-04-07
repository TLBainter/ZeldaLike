##[b][color=red]InteractableComponent[/color][/b] is a pluggable interaction zone that can be added to any [b]EntityClass[/b] entity.[br]
##Place as a child of the entity's [b]body[/b] node ([b]CharacterBody2D[/b]) for objects that move,[br]
##or directly under the entity root for static entities.[br]
##[br]
##Set [b]interact_type[/b] to auto-populate [b]context_key[/b], or override [b]context_key[/b] manually.[br]
##Use the [b]Interact Area[/b] exports to control the detection zone shape and position.
@tool
class_name InteractableComponent
extends Node2D

#region SIGNALS
##Forwarded to states; connect to this signal instead of the inner Area2D.
@warning_ignore("unused_signal")
signal interaction_finished
#endregion

#region ENUMS
enum InteractType {
	NONE,
	GRAB,
	LIFT,
	DIALOGUE,
	PICKUP,
	DOOR,
	CONTAINER,
	USABLE,
	SECRET,
	SHOP,
	GRAB_OR_LIFT,
	CUSTOM
}
#endregion

#region EXPORTS
@export_group("Interact Settings")
##The type of interaction this component provides.[br]
##Automatically sets [b]context_key[/b] -- override below if needed.
@export var interact_type: InteractType = InteractType.NONE:
	set(v):
		interact_type = v
		_sync_context_key()

##The context key sent to the context label UI.[br]
##Auto-populated from [b]interact_type[/b], but editable for custom types.
@export var context_key: String = "default"

@export_group("Interact Area")
##Shape type for the interaction detection zone.
@export_enum("Circle", "Capsule") var shape_type: int = 0:
	set(v):
		shape_type = v
		_rebuild_shape()

##Radius of the detection circle (or capsule end caps).
@export var shape_radius: float = 8.0:
	set(v):
		shape_radius = v
		_rebuild_shape()

##Height of the capsule body (Capsule shape only).
@export var shape_height: float = 16.0:
	set(v):
		shape_height = v
		_rebuild_shape()

##Local offset of the [b]Area2D[/b] relative to this component's position.[br]
##Use this to shift the detection bubble without moving the component root.
@export var area_offset: Vector2 = Vector2.ZERO:
	set(v):
		area_offset = v
		_apply_offset()

@export_group("References")
##The owning [b]EntityClass[/b]. Auto-resolved at runtime by walking up the tree if left null.
@export var owner_entity: EntityClass

@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else String(name)
	set(v): if debug: debug.debug_name = v
#endregion

#region INTERNALS
@onready var _area: Area2D = $InteractArea
@onready var _collider: CollisionShape2D = $InteractArea/InteractCollider
#endregion

#region FUNCTIONS

func _ready() -> void:
	_rebuild_shape()
	_apply_offset()
	if Engine.is_editor_hint():
		return
	if not owner_entity:
		owner_entity = _find_entity_parent()
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

##Called by states to trigger the interaction.[br]
##Override in subclasses (e.g., [b]InteractableComponent_Dialogue[/b]).
func interact(_user = null) -> void:
	pass

##Enable or disable the detect area.[br]
##Used by [b]DynamicInteractable[/b] during hold and release.
func set_active(active: bool) -> void:
	if _area:
		if not active and _area.monitoring:
			var overlapping := _area.get_overlapping_bodies()
			if debug_me:
				print(debug_name, ": set_active(false) ; evicting ", overlapping.size(), " overlapping bodies")
			for body in overlapping:
				_on_body_exited(body)
		elif not active:
			if debug_me:
				print(debug_name, ": set_active(false) ; monitoring already off, skipping eviction")
		_area.set_deferred("monitoring", active)
		_area.set_deferred("monitorable", active)

#region BODY DETECTION

func _on_body_entered(body: CharacterBody2D) -> void:
	if body is PlayerBody:
		if "current_interactable" in body:
			body.current_interactable = self
		if debug_me:
			print(debug_name, ": body_entered ; current_interactable set, requesting context refresh")
		if body.root and body.root.state_machine:
			body.root.state_machine.request_context_refresh()

func _on_body_exited(body: CharacterBody2D) -> void:
	if body is PlayerBody:
		if "current_interactable" in body and body.current_interactable == self:
			body.current_interactable = null
		if debug_me:
			print(debug_name, ": body_exited ; current_interactable cleared, requesting context refresh")
		if body.root and body.root.state_machine:
			body.root.state_machine.request_context_refresh()

#endregion

#region SHAPE

func _rebuild_shape() -> void:
	if not is_node_ready():
		return
	if not _collider:
		return
	if shape_type == 0:  # Circle
		if not _collider.shape is CircleShape2D:
			_collider.shape = CircleShape2D.new()
		_collider.shape.radius = shape_radius
	else:  # Capsule
		if not _collider.shape is CapsuleShape2D:
			_collider.shape = CapsuleShape2D.new()
		_collider.shape.radius = shape_radius
		_collider.shape.height = shape_height

func _apply_offset() -> void:
	if not is_node_ready():
		return
	if _area:
		_area.position = area_offset

#endregion

#region HELPERS

const INTERACT_CONTEXT_KEYS := {
	InteractType.GRAB:         "grab",
	InteractType.LIFT:         "lift",
	InteractType.DIALOGUE:     "speak",
	InteractType.PICKUP:       "lift",
	InteractType.DOOR:         "open",
	InteractType.CONTAINER:    "open",
	InteractType.SHOP:         "shop",
	InteractType.USABLE:       "use",
	InteractType.GRAB_OR_LIFT: "grab",
}

func _sync_context_key() -> void:
	context_key = INTERACT_CONTEXT_KEYS.get(interact_type, "default")

func _find_entity_parent() -> EntityClass:
	var p := get_parent()
	while p:
		if p is EntityClass:
			return p
		p = p.get_parent()
	return null

#endregion

#endregion
