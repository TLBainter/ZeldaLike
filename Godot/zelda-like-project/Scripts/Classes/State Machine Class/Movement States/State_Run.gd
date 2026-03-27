##[b][color=red]StateRun[/color][/b] is a movement state for moving at high speeds.[br]
##While running, you can activate the roll context action.[br]
##There are things you can't do while running, though, like grabbing things or speaking.
##[br]
##[b]LAYER[/b]: Movement
class_name StateRun
extends State

#region VARIABLES

##The state to enter when no longer moving.
@export var idle_state : State

##The state to enter when moving at a slower pace due to decreased joystick input strength.
@export var move_state : State

##The state to enter when rolling due to action button press.
@export var roll_state : State

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	if root.input and not root.input.onMove.is_connected(_on_move):
		root.input.onMove.connect(_on_move)
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	
func exit():
	if root.input and root.input.onMove.is_connected(_on_move):
		root.input.onMove.disconnect(_on_move)
	super()

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < 0.15 and idle_state:
		state_machine.change_state(idle_state)
	#TODO: Test this value to make sure it is reasonable for entering the running state.
	elif move_strength <= 0.49 and move_state:
		state_machine.change_state(move_state)

func get_context_key() -> String:
	if coordinator.held_object:
		return "throw"
	return "roll"

func process_input(event : InputEvent) -> State:
	#TODO: Add roll input action and conenct to roll_State once Roll is implemented.
	if event.is_action_pressed("actionButton4") and roll_state:
		if coordinator.held_object:
			return null
		if roll_state:
			return roll_state
		#INFO: This is for debugging purposes while roll state is still not created.
		input_consumed = true
	return null

#endregion FUNCTIONS
