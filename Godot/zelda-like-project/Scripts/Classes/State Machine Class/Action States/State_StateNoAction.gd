##[b][color=red]StateNoAction[/color][/b] is the default Action Layer state.[br]
##The character is not performing any actions in this state.[br]
##Transitions to action states are triggered by input or events.[br]
##[br]
##[b]LAYER[/b]: Action
class_name StateNoAction
extends State

#region VARIABLES

var _attack_ready_at_ms: int = 0

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	_debug_log("entered; requesting context refresh")
	coordinator.request_context_refresh()

func mark_attack_used(cooldown_seconds: float) -> void:
	_attack_ready_at_ms = Time.get_ticks_msec() + int(cooldown_seconds * 1000.0)

func _is_attack_ready() -> bool:
	return Time.get_ticks_msec() >= _attack_ready_at_ms

##Listens for action button presses to transition to action states.
func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("block"):
		var character = get_character()
		var energy = character.get("energy") if character else null
		if energy and energy.is_exhausted_state:
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.BLOCK), "block+pressed")
	#region Light Attack
	if event.is_action_pressed("attackLight") and _is_attack_ready():
		return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.ATTACK), "attackLight+pressed")
	#endregion Light Attack
	#region Context Button
	if event.is_action_pressed("actionButton4"):
		var character = get_character()
		var _body_interactable = character.body.get("current_interactable") if character else null
		if not character or not _body_interactable:
			return null
		var interactable: InteractableComponent = _body_interactable
		var interactable_owner = interactable.owner_entity if interactable else null
		if interactable_owner and interactable_owner is DynamicThing and interactable_owner.object_data:
			if character.energy and character.energy.is_exhausted_state:
				return null
			var data = interactable_owner.object_data
			var move_input = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
			var is_moving : bool = move_input.length() > GameConstants.JOYSTICK_DEADZONE
			if debug_me_verbose:
				print("NoAction ROUTING: is_moving=", is_moving, " velocity=", character.body.velocity, " vel_length=", character.body.velocity.length())
				print("  pushable=", data.pushable, " pullable=", data.pullable, " liftable=", data.liftable)
			var priority = coordinator.resolve_interaction_priority(data, is_moving)
			if priority == StateCoordinator.InteractionPriority.GRAB:
				return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.GRAB), "actionButton4+DynamicThing+grab")
			elif priority == StateCoordinator.InteractionPriority.LIFT:
				return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.LIFT), "actionButton4+DynamicThing+lift")
		elif interactable.interact_type != InteractableComponent.InteractType.NONE:
			return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.INTERACT), "actionButton4+not_DynamicThing")
	#endregion Context Button
	return null

#endregion FUNCTIONS
