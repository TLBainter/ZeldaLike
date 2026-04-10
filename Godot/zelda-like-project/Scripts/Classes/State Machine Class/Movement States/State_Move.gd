##[b][color=red]StateMove[/color][/b] is the initial movement state.[br]
##In this state, a character is moving at a moderate pace rather than running or idling.[br]
##Transitions to idle when joystick input is within the deadzone, or to running when joystick input is high.
##[br]
##[b]LAYER[/b]: Movement
class_name StateMove
extends State

#region FUNCTIONS

func enter():
	super()
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.walk_speed
	if root.input: _safe_connect(root.input.on_move, _on_move)
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		if character.energy and character.energy.is_exhausted_state:
			character.anim.idle_prefix = AnimationNames.EXHAUSTED_IDLE
			character.anim.walk_prefix = AnimationNames.EXHAUSTED_WALK
		else:
			character.anim.idle_prefix = AnimationNames.IDLE
			character.anim.walk_prefix = AnimationNames.WALK
	
func exit():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	super()

func pause():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	if root.input: _safe_connect(root.input.on_move, _on_move)

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < GameConstants.JOYSTICK_DEADZONE:
		var _next : State = coordinator.get_transition("idle")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "on_move+strength<0.15"))
	elif move_strength > GameConstants.RUN_THRESHOLD:
		var character = get_character()
		if coordinator.context_locked:
			return
		if character and character.energy and character.energy.is_exhausted_state:
			return
		var _next : State = coordinator.get_transition("run")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "on_move+strength>0.49"))

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
		return coordinator.try_transition(state_machine, coordinator.get_transition("backstep"), "actionButton4+walk+no_interactable")
	if event.is_action_pressed("dash"):
		if coordinator.held_object:
			return null
		if not _has_bat_form():
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition("backstep"), "dash+walk")
	return null

func _has_bat_form() -> bool:
	var character = get_character()
	if not character or not character.inventory:
		return false
	return character.inventory.has_item(ItemID.BAT_FORM) or character.inventory.has_item(ItemID.BAT_FORM_UPGRADED)

func get_context_key() -> String:
	if coordinator.held_object:
		return "drop"
	var character = get_character()
	if character and character.body.current_interactable:
		var component: InteractableComponent = character.body.current_interactable
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
