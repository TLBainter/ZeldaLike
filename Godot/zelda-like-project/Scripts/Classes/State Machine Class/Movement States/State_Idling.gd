##[b][color=red]StateIntialized[/color][/b] is the default Movement state.[br]
##While in this state, a character's velocity is 0 and they play an idle animation.[br]
##This state transitions to Move when InputComponent.onMove signal reports an input above the dead zone.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateIdling
extends State

#region VARIABLES

@export_group("Transitions")
##The state to enter when movement input is detected.
@export var move_state : State

#endregion VARIABLES

#region FUNCTIONS
	#region enter/exit
func enter():
	super()
	coordinator.update_context(get_context_key())
	root.body.velocity = Vector2.ZERO
	if root.input and not root.input.onMove.is_connected(_on_move):
		root.input.onMove.connect(_on_move)

func exit():
	if root.input and root.input.onMove.is_connected(_on_move):
		root.input.onMove.disconnect(_on_move)
	super()
	#endregion enter/exit

func pause():
	if root.input and root.input.onMove.is_connected(_on_move):
		root.input.onMove.disconnect(_on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	if root.input and not root.input.onMove.is_connected(_on_move):
		root.input.onMove.connect(_on_move)
	super()

##Transitions to the move state if beyond joystick deadzone.
func _on_move(move_input : Vector2, move_strength : float):
	if move_strength > 0.15 and move_state:
		state_machine.change_state(move_state)

##Fetch the context key from the interactable nearby.
func get_context_key() -> String:
	if coordinator.held_object:
		return "drop"
	var character = get_character()
	if character and character.body.current_interactable:
		var interact_node = character.body.current_interactable
		var owner = interact_node.root if "root" in interact_node else null
		if owner and owner is DynamicInteractable and owner.object_data:
			if owner.object_data.liftable:
				return "pickup"
			elif owner.object_data.pushable or owner.object_data.pullable:
				return "grab"
		return interact_node.context_key
	return ""

#endregion FUNCTIONS
