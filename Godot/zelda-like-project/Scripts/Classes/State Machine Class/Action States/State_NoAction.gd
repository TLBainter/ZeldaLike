##[b][color=red]StateNoAction[/color][/b] is the default Action Layer state.[br]
##The character is not performing any actions in this state.[br]
##Transitions to action states are triggered by input or events.[br]
##[br]
##[b]LAYER[/b]: Action
class_name StateNoAction
extends State

#region VARIABLES
@export_group("Transitions")
##The state to enter when the character initiates an attack.
@export var attack_state : State
##The state to enter when the character initiates an interactions.
@export var interact_state : State
#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()

##Listens for action button presses to transition to action states.
func process_input(event : InputEvent) -> State:
	#Handle interaction when able
	if event.is_action_pressed("actionButton4") and interact_state:
		var character = get_character()
		if character and character.body.current_interactable:
			return interact_state
	#TODO: Add transition logic for action states as they are implemented for the Action Layer.
	return null

#endregion FUNCTIONS
