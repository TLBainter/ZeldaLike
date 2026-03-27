##[b][color=red]StateHoldingAction[/color][/b] is the Action layer state for when the character is holding an object above their head.[br]
##Unfreezes movement so the player can walk/run while holding.[br]
##On actionButton4 press: checks the current movement state to decide between Throw (running) and Drop (idle/move).[br]
##[br]
##[b]Layer[/b]: Action
class_name StateHoldingAction
extends State

#region VARIABLES

@export_group("In-Layer Transitions")
##The state to enter when throwing the held object (player is running).
@export var throw_state : Node ## : State
##The state to enter when dropping the held object (player is idle or walking).
@export var drop_state : Node ## : State
##Fallback if something goes wrong.
@export var no_action_state : Node ## : State

@export_group("Movement State References")
##Reference to the Run state on the Movement layer, used to check if player is running.
@export var run_state : Node ## : State (Movement layer)

@export_group("Hold Settings")
##The offset above the player's body where the object is held.
@export var hold_offset : Vector2 = Vector2(0, -12)

#===#
##Whether the player's input strength is above the run threshold.
var _is_running : bool = false

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	_is_running = false
	coordinator.unfreeze_movement()
	coordinator.lock_context()
	coordinator.update_context(get_context_key(), true)
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	if root.input and not root.input.onMove.is_connected(_on_move):
		root.input.onMove.connect(_on_move)
	if debug_me:
		print(debug_name, ": Now holding object. Movement unfrozen.")

func exit():
	if root.input and root.input.onMove.is_connected(_on_move):
		root.input.onMove.disconnect(_on_move)
	coordinator.unlock_context()
	super()

func _on_move(_move_input : Vector2, move_strength : float):
	var was_running = _is_running
	_is_running = move_strength > 0.49
	if _is_running != was_running:
		coordinator.update_context(get_context_key(), true)

func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("actionButton4"):
		if _is_running and throw_state:
			return throw_state
		elif drop_state:
			return drop_state
	return null

func get_context_key() -> String:
	if _is_running:
		return "throw"
	return "drop"

#endregion FUNCTIONS
