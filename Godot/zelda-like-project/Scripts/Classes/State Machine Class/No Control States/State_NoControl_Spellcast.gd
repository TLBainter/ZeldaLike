##[b][color=red]SpellcastState[/color][/b] - base NoControl state for all player spells.[br]
##Freezes movement and action layers on enter; restores them on exit.[br]
##Subclasses override [method _on_interrupted] and [method _on_cancelled] for spell-specific cleanup.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name SpellcastState
extends State

@export_group("Settings")
@export var can_update_facing: bool = false
@export var can_cancel: bool = true
@export var can_be_interrupted: bool = true
@export var can_move: bool = false
@export var magic_cost: int = 0

var _cast_rejected: bool = false

#region STATE LIFECYCLE

func _ready() -> void:
	set_physics_process(false)
	super()

func enter() -> void:
	_cast_rejected = false
	if magic_cost > 0 and root and root.magic:
		if not root.magic.consume(magic_cost):
			_cast_rejected = true
			_safe_transition(StateID.INITIALIZED)
			return
	coordinator.freeze_action()
	if not can_move:
		coordinator.freeze_movement()
	if not can_update_facing:
		lock_facing()
	if can_be_interrupted and root.health:
		_safe_connect(root.health.health_changed, _on_health_changed)
	if can_cancel and root.input:
		_safe_connect(root.input.action_button_pressed, _on_action_button_pressed)

func exit() -> void:
	coordinator.unfreeze_action()
	if not can_move:
		coordinator.unfreeze_movement()
	if not can_update_facing:
		unlock_facing()
	if can_be_interrupted and root.health:
		_safe_disconnect(root.health.health_changed, _on_health_changed)
	if can_cancel and root.input:
		_safe_disconnect(root.input.action_button_pressed, _on_action_button_pressed)
	super()

func pause() -> void:
	if can_be_interrupted and root.health:
		_safe_disconnect(root.health.health_changed, _on_health_changed)
	if can_cancel and root.input:
		_safe_disconnect(root.input.action_button_pressed, _on_action_button_pressed)
	super()

func resume() -> void:
	if can_be_interrupted and root.health:
		_safe_connect(root.health.health_changed, _on_health_changed)
	if can_cancel and root.input:
		_safe_connect(root.input.action_button_pressed, _on_action_button_pressed)
	super()

#endregion STATE LIFECYCLE

#region INTERRUPT / CANCEL

func _on_health_changed(_cur: int, _max: int, _change: int) -> void:
	_on_interrupted()

func _on_action_button_pressed(btn: String) -> void:
	if btn == "actionButton4":
		_on_cancelled()

func _on_interrupted() -> void:
	_safe_transition(StateID.INITIALIZED)

func _on_cancelled() -> void:
	_safe_transition(StateID.INITIALIZED)

#endregion INTERRUPT / CANCEL
