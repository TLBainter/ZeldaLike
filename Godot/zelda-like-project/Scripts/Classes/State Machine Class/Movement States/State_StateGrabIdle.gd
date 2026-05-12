##[b][color=red]StateGrabIdle[/color][/b] is the [b]Movement layer[/b] state for the character's grabbing of an object while not moving.[br]
##Listens for directional input along the locked axis to transition to [i]Pushing[/i] or [i]Pulling[/i].[br]
##The character cannot turn (change facing) or move freely in this state.[br]
##[br]
##[b]Layer[/b]: Movement
class_name StateGrabIdle
extends State

#region VARIABLES

var _snap_cooldown : bool = false

#endregion VARIABLES

#region FUNCTION

func enter():
	super()
	root.body.velocity = Vector2.ZERO
	if root.input: _safe_connect(root.input.on_move, _on_move)
	coordinator.update_context("grab")
	var _no_action : State = coordinator.get_transition(StateID.NO_ACTION)
	if root.input and not root.input.is_action_button_held("actionButton4") and _no_action:
		coordinator.request_action_change(_no_action)
		return
	_snap_cooldown = true
	get_tree().create_timer(0.15).timeout.connect(_on_cooldown_finished)

func exit():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	super()

func pause():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	super()

func resume():
	if root.input: _safe_connect(root.input.on_move, _on_move)
	super()

func _on_move(move_input : Vector2, move_strength : float):
	if move_strength < 0.15:
		return
	if _snap_cooldown:
		return
	var character = get_character()
	if not character or not character.anim:
		return
	var facing_str : String = character.anim.facing
	if facing_str not in ["up", "down", "left", "right"]:
		return
	var facing_dir : Vector2 = facing_to_vector(facing_str)
	var dot : float = move_input.normalized().dot(facing_dir)
	var grabbed = coordinator.grabbed_object
	if not grabbed or not grabbed.object_data:
		return
	if dot > 0.5 and grabbed.object_data.pushable:
		var _push : State = coordinator.get_transition(StateID.PUSHING)
		if _push:
			state_machine.change_state(coordinator.try_transition(state_machine, _push, "on_move+dot>0.5+pushable"))
	if dot < -0.5 and grabbed.object_data.pullable:
		var _pull : State = coordinator.get_transition(StateID.PULLING)
		if _pull:
			state_machine.change_state(coordinator.try_transition(state_machine, _pull, "on_move+dot<-0.5+pullable"))
	pass

func _on_cooldown_finished():
	_snap_cooldown = false

func get_context_key() -> String:
	return "grab"

#endregion FUNCTIONS
