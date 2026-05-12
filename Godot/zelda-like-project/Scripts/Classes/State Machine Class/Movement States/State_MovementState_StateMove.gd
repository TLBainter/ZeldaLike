##[b][color=red]StateMove[/color][/b] is the initial movement state.[br]
##In this state, a character is moving at a moderate pace rather than running or idling.[br]
##Transitions to idle when joystick input is within the deadzone, or to running when joystick input is high.
##[br]
##[b]LAYER[/b]: Movement
class_name StateMove
extends MovementState

#region FUNCTIONS

func enter():
	super()
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.walk_speed
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		var _energy = character.get("energy")
		if _energy:
			character.anim.set_exhaustion_state(_energy.is_exhausted_state)

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < GameConstants.JOYSTICK_DEADZONE:
		_safe_transition(StateID.IDLE)
	elif move_strength > GameConstants.RUN_THRESHOLD:
		var character = get_character()
		if coordinator.context_locked:
			return
		var _energy = character.get("energy") if character else null
		if _energy and _energy.is_exhausted_state:
			return
		_safe_transition(StateID.RUN)

##Trigger backstep when actionButton4 is pressed with no interactable and not exhausted.
##The dedicated dash input always triggers backstep regardless of interactable.
func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("actionButton4"):
		if coordinator.held_object:
			return null
		var character = get_character()
		if character and character.body.get("current_interactable"):
			return null  # Let the action layer handle the interaction.
		if not _has_bat_form():
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.BACKSTEP), "actionButton4+walk+no_interactable")
	if event.is_action_pressed("dash"):
		if coordinator.held_object:
			return null
		if not _has_bat_form():
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.BACKSTEP), "dash+walk")
	return null

func _has_bat_form() -> bool:
	var character = get_character()
	var inv = character.get("inventory") if character else null
	if not inv:
		return false
	return inv.has_item(ItemID.BAT_FORM) or inv.has_item(ItemID.BAT_FORM_UPGRADED)

func get_context_key() -> String:
	if coordinator.held_object:
		return "drop"
	var character = get_character()
	if character and character.body.get("current_interactable"):
		var component: InteractableComponent = character.body.get("current_interactable")
		var interactable_owner = component.owner_entity if component else null
		if interactable_owner and interactable_owner is DynamicThing and interactable_owner.object_data:
			var data = interactable_owner.object_data
			var priority = coordinator.resolve_interaction_priority(data, true)
			if priority == StateCoordinator.InteractionPriority.GRAB:
				return "grab"
			elif priority == StateCoordinator.InteractionPriority.LIFT:
				return "lift"
		return component.context_key
	if _has_bat_form():
		return "Bat Step"
	return ""
#endregion FUNCTIONS
