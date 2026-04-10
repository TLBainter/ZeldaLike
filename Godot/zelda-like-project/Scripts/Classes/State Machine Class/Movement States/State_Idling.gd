##[b][color=red]StateIntialized[/color][/b] is the default Movement state.[br]
##While in this state, a character's velocity is 0 and they play an idle animation.[br]
##This state transitions to Move when InputComponent.on_move signal reports an input above the dead zone.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateIdling
extends State

#region FUNCTIONS

	#region enter/exit
func enter():
	super()
	coordinator.update_context(get_context_key())
	root.body.velocity = Vector2.ZERO
	if root.input: _safe_connect(root.input.on_move, _on_move)
	if not state_machine.is_active:
		return
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		if character.energy and character.energy.is_exhausted_state:
			character.anim.idle_prefix = AnimationNames.EXHAUSTED_IDLE
			character.anim.walk_prefix = AnimationNames.EXHAUSTED_WALK
		else:
			character.anim.idle_prefix = AnimationNames.IDLE
			character.anim.walk_prefix = AnimationNames.WALK
		character.anim.play_directional_anim(character.anim.idle_prefix)

func exit():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	super()
	#endregion enter/exit

func pause():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	if root.input: _safe_connect(root.input.on_move, _on_move)
	super()

##Transitions to the move state if beyond joystick deadzone.
func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength > GameConstants.JOYSTICK_DEADZONE:
		var _next : State = coordinator.get_transition("move")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "on_move+strength>0.15"))

##Trigger backstep when actionButton4 is pressed with no interactable and not exhausted.
##The dedicated dash input always triggers backstep regardless of interactable.
func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("actionButton4"):
		if coordinator.held_object:
			return null
		var character = get_character()
		if character and character.body.current_interactable:
			return null  # Let the action layer handle the interaction.
		if not _has_bat_form():
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition("backstep"), "actionButton4+idle+no_interactable")
	if event.is_action_pressed("dash"):
		if coordinator.held_object:
			return null
		if not _has_bat_form():
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition("backstep"), "dash+idle")
	return null

##Fetch the context key from the interactable nearby.
func get_context_key() -> String:
	if coordinator.held_object:
		return "drop"
	var character = get_character()
	if character and character.body.current_interactable:
		var component: InteractableComponent = character.body.current_interactable
		var interactable_owner = component.owner_entity if component else null
		if interactable_owner and interactable_owner is DynamicThing and interactable_owner.object_data:
			var priority = coordinator.resolve_interaction_priority(interactable_owner.object_data, false)
			if priority == StateCoordinator.InteractionPriority.LIFT:
				return "lift"
			elif priority == StateCoordinator.InteractionPriority.GRAB:
				return "grab"
		return component.context_key
	if _has_bat_form():
		return "Bat Step"
	return ""

func _has_bat_form() -> bool:
	var character = get_character()
	if not character or not character.inventory:
		return false
	return character.inventory.has_item(ItemID.BAT_FORM) or character.inventory.has_item(ItemID.BAT_FORM_UPGRADED)

#endregion FUNCTIONS
