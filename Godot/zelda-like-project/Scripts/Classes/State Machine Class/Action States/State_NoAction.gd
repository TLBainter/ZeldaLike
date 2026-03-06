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
##The state to enter when the character is grabbing something (like a push/pull object).
@export var grab_state : State
##The state to enter when the character lifts something (like a pot or crate).
@export var lift_state : State
#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()

##Listens for action button presses to transition to action states.
func process_input(event : InputEvent) -> State:
	#Handle interaction when able
	if event.is_action_pressed("actionButton4") and interact_state:
		var character = get_character()
		if not character or not character.body.current_interactable:
			return null
		var interactable = character.body.current_interactable
		var owner = interactable.root if "root" in interactable else null
		if owner and owner is DynamicInteractable and owner.object_data:
			var data = owner.object_data
			var is_moving : bool = character.body.velocity.length() > 0.1
			# grab the object if it can be grabbed, lift if it can be lifted.
			#note some objects are grabbable and liftable.
			#In such cases, the player will only grab if they are moving while pressing the action button; otherwise, they'll lift it.
			if (data.pushable or data.pullable):
				if is_moving or not data.liftable:
					if grab_state:
						return grab_state
				elif data.liftable and lift_state:
					return lift_state
			elif data.liftable and lift_state:
				return lift_state
		elif interact_state:
			return interact_state
	return null

#endregion FUNCTIONS
