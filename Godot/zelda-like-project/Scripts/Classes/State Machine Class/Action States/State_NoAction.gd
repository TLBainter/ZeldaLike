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
	#region Light Attack
	if event.is_action_pressed("attackLight"):
		if attack_state:
			return attack_state
	#endregion Light Attack
	#region Context Button
	if event.is_action_pressed("actionButton4") and interact_state:
		var character = get_character()
		if not character or not character.body.current_interactable:
			return null
		var interactable: InteractableComponent = character.body.current_interactable
		var interactable_owner = interactable.owner_entity if interactable else null
		if interactable_owner and interactable_owner is DynamicThing and interactable_owner.object_data:
			#Don't allow this transition if character is exhausted
			if character.energy and character.energy.is_exhausted_state:
				return null
			var data = interactable_owner.object_data
			var move_input = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
			var is_moving : bool = move_input.length() > 0.15
			if debug_me_verbose:
				print("NoAction ROUTING: is_moving=", is_moving, " velocity=", character.body.velocity, " vel_length=", character.body.velocity.length())
				print("  pushable=", data.pushable, " pullable=", data.pullable, " liftable=", data.liftable)
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
	#endregion Context Button
	return null

#endregion FUNCTIONS
