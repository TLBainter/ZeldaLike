##[b][color=red]StateHoldingAction[/color][/b] is the Action layer state for when the character is holding an object above their head.[br]
##Unfreezes movement so the player can walk/run while holding.[br]
##On actionButton4 press: checks the current movement state to decide between Throw (running) and Drop (idle/move).[br]
##[br]
##[b]Layer[/b]: Action
class_name StateHoldingAction
extends State

#region VARIABLES

var throw_state : State
var drop_state : State
var no_action_state : State
var run_state : State

@export_group("Hold Settings")
##The offset above the player's body where the object is held.
@export var hold_offset : Vector2 = Vector2(0, -12)

#===#
##Whether the player's input strength is above the run threshold.
var _is_running : bool = false

#endregion VARIABLES

#region FUNCTIONS

func init_state_refs() -> void:
	throw_state = coordinator.get_state(StateThrow)
	drop_state = coordinator.get_state(StateDrop)
	no_action_state = coordinator.get_state(StateNoAction)
	run_state = coordinator.get_state(StateRun)

func enter():
	super()
	_is_running = false
	coordinator.unfreeze_movement()
	coordinator.lock_context()
	coordinator.update_context(get_context_key(), true)
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	if debug_me:
		print(debug_name, ": Now holding object. Movement unfrozen.")

func exit():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	coordinator.unlock_context()
	super()

func pause():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	super()

func resume():
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	super()

func _on_move(_move_input : Vector2, move_strength : float):
	var was_running = _is_running
	_is_running = move_strength > 0.49
	if _is_running != was_running:
		coordinator.update_context(get_context_key(), true)

func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("actionButton4"):
		if _is_running and throw_state:
			return coordinator.try_transition(state_machine, throw_state, "actionButton4+pressed+running")
		elif drop_state:
			return coordinator.try_transition(state_machine, drop_state, "actionButton4+pressed+not_running")
	return null

func get_context_key() -> String:
	if _is_running:
		return "throw"
	return "drop"

#endregion FUNCTIONS
