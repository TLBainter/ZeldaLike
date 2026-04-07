##[b][color=red]StateRun[/color][/b] is a movement state for moving at high speeds.[br]
##While running, you can activate the dash context action.[br]
##There are things you can't do while running, though, like grabbing things or speaking.
##[br]
##[b]LAYER[/b]: Movement
class_name StateRun
extends State

#region VARIABLES

var idle_state : State
var move_state : State
var dash_state : State

#endregion VARIABLES

#region FUNCTIONS

func init_state_refs() -> void:
	idle_state = coordinator.get_state(StateIdling)
	move_state = coordinator.get_state(StateMove)
	dash_state = coordinator.get_state(StateDash)

func enter():
	super()
	#Set run speed from stats.
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.run_speed
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	
func exit():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	super()

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < 0.15 and idle_state:
		state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "on_move+strength<0.15"))
	#TODO: Test this value to make sure it is reasonable for entering the running state.
	elif move_strength <= 0.49 and move_state:
		state_machine.change_state(coordinator.try_transition(state_machine, move_state, "on_move+strength<=0.49"))

func get_context_key() -> String:
	if coordinator.held_object:
		return "throw"
	return "dash"

func process_input(event : InputEvent) -> State:
	if (event.is_action_pressed("actionButton4") or event.is_action_pressed("dash")) and dash_state:
		if coordinator.held_object:
			return null
		if coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, dash_state, "dash+running+no_held")
	return null

#endregion FUNCTIONS
