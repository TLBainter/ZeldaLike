##[b][color=red]StateGrab[/color][/b] is the Action layer state for when the character is grabbing a [b]DynamicThing[/b].[br]
##While in this state, the character holds onto the object. The movement layer switches to [i]GrabIdle[/i],[br]
##handling transitions to [i]Pushing[/i] or [i]Pulling[/i] based on availability and input.[br]
##Releasing actionButton4/Context Button while in [b]GrabIdle[/b] releases the grab.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateGrab
extends State

#region FUNCTIONS

func enter():
	super()
	var character = get_character()
	if not character:
		push_error(debug_name + ": failed to get a character reference in enter()")
		var _next : State = coordinator.get_transition("no_action")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "enter+no_character"))
		return
	var component: InteractableComponent = character.body.current_interactable
	var interactable = component.owner_entity if component else null
	if interactable and interactable is DynamicThing:
		coordinator.grabbed_object = interactable
	else:
		push_error(debug_name + ": found no valid DynamicThing to grab in enter()")
		var _next2 : State = coordinator.get_transition("no_action")
		if _next2:
			state_machine.change_state(coordinator.try_transition(state_machine, _next2, "enter+no_DynamicThing"))
		return
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		character.anim.play_directional_anim(AnimationNames.GRAB)
	coordinator.freeze_movement()
	var _grab_idle : State = coordinator.get_transition("grab_idle")
	coordinator.request_movement_change(_grab_idle)
	if debug_me:
		print_rich(debug_name, ": [color=green][i]grabbed[/i][/color] [b]", interactable.name, "[/b].")

func process_input(event : InputEvent) -> State:
	if event.is_action_released("actionButton4"):
		var movement_state = coordinator.movement_layer.current_state
		if movement_state == coordinator.get_transition("grab_idle"):
			return coordinator.try_transition(state_machine, coordinator.get_transition("no_action"), "actionButton4+released+at_GrabIdle")
		input_consumed = true
	return null

func exit():
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	coordinator.grabbed_object = null
	coordinator.unfreeze_movement()
	var _idle : State = coordinator.get_transition("idle")
	coordinator.request_movement_change(_idle)
	if debug_me:
		print_rich(debug_name, ": [color=red][i]released grab on[/i][/color] [b]", character.body.current_interactable, "[/b]")
	super()

#endregion FUNCTIONS
