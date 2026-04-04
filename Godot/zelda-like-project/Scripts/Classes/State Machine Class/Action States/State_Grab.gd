##[b][color=red]StateGrab[/color][/b] is the Action layer state for when the character is grabbing a [b]DynamicThing[/b].[br]
##While in this state, the character holds onto the object. The movement layer switches to [i]GrabIdle[/i],[br]
##handling transitions to [i]Pushing[/i] or [i]Pulling[/i] based on availability and input.[br]
##Releasing actionButton4/Context Button while in [b]GrabIdle[/b] releases the grab.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateGrab
extends State

#region VARIABLES

@export_group("In-Layer Transitions")
##The state to return to when the grab is released.
@export var no_action_state : State
@export_group("Cross-Layer Transitions")
##The GrabIdle state on the [b]Movement layer[/b] to switch to when grabbing.
@export var grab_idle_state : State
##The idling state on the [b]Movement layer[/b] to return to when releasing.
@export var idle_state : State

#endregion VARIABLEs

#region FUNCTIONS

func enter():
	super()
	var character = get_character()
	if not character:
		if debug_me:
			printerr(debug_name, " failed to get a character reference!")
		if no_action_state:
			state_machine.change_state(no_action_state)
		return
	#Store the values for the interactable being interacted with to trigger entering this state.
	var component: InteractableComponent = character.body.current_interactable
	var interactable = component.owner_entity if component else null
	if interactable and interactable is DynamicThing:
		coordinator.grabbed_object = interactable
	else:
		if debug_me:
			printerr(debug_name, " found no valid DynamicThing to grab!")
		if no_action_state:
			state_machine.change_state(no_action_state)
		return
	#Lock the facing direction so the character doesn't rotate while grabbing.
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		character.anim.play_directional_anim("Grab")
	#Freeze normal movement and switch to grab idle state.
	coordinator.freeze_movement()
	coordinator.request_movement_change(grab_idle_state)
	if debug_me:
		print_rich(debug_name, ": grabbed [b]", interactable, "[/b].")
	##Listen for actionButton4 release.[br]
	##Only allow release when the [b]Movement layer[/b] is in [i]GrabIdle[/i][br]
	##to prevent mid-push/pull release.

func process_input(event : InputEvent) -> State:
	if event.is_action_released("actionButton4"):
		#Check if the movement layer is in GrabIdle
		var movement_state = coordinator.movement_layer.current_state
		if movement_state == grab_idle_state:
			return no_action_state
		#If you are mid push/pull, consume input but do not release.
		input_consumed = true
	return null

func exit():
	var character = get_character()
	#Unlock facing direction
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	#Clear grabbed object
	coordinator.grabbed_object = null
	#Unfreeze movement (whoops)
	coordinator.unfreeze_movement()
	#return movement to idling
	if idle_state:
		coordinator.request_movement_change(idle_state)
	#call super exit
	if debug_me:
		print_rich(debug_name, " released grab on [b]", character.body.current_interactable, "[/b]")
	super()

#endregion FUNCTIONS
