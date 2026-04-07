##[b][color=red]StateMove[/color][/b] is the initial movement state.[br]
##In this state, a character is moving at a moderate pace rather than running or idling.[br]
##Transitions to idle when joystick input is within the deadzone, or to running when joystick input is high.
##[br]
##[b]LAYER[/b]: Movement
class_name StateMove
extends State

#region VARIABLES

var idle_state : State
var run_state : State
var dash_state : State
var backstep_state : State

#endregion VARIABLES

#region FUNCTIONS

func init_state_refs() -> void:
	idle_state = coordinator.get_state(StateIdling)
	run_state = coordinator.get_state(StateRun)
	dash_state = coordinator.get_state(StateDash)
	backstep_state = coordinator.get_state(StateBackstep)

func enter():
	super()
	#Set walk speed from stats.
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.walk_speed
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		if character.energy and character.energy.is_exhausted_state:
			character.anim.idle_prefix = "ExhaustedIdle"
			character.anim.walk_prefix = "ExhaustedWalk"
		else:
			character.anim.idle_prefix = "Idle"
			character.anim.walk_prefix = "Walk"
	
func exit():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	super()

func pause():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < 0.15 and idle_state:
		state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "on_move+strength<0.15"))
	elif move_strength > 0.49 and run_state:
		var character = get_character()
		if coordinator.context_locked:
			return
		if character and character.energy and character.energy.is_exhausted_state:
			return
		state_machine.change_state(coordinator.try_transition(state_machine, run_state, "on_move+strength>0.49"))

##Trigger backstep when actionButton4 is pressed with no interactable and not exhausted.
##The dedicated dash input always triggers backstep regardless of interactable.
func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("actionButton4") and backstep_state:
		if coordinator.held_object:
			return null
		var character = get_character()
		if character and character.body.current_interactable:
			return null  # Let the action layer handle the interaction.
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, backstep_state, "actionButton4+walk+no_interactable")
	if event.is_action_pressed("dash") and backstep_state:
		if coordinator.held_object:
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, backstep_state, "dash+walk")
	return null

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
			if priority == "grab":
				return "grab"
			elif priority == "lift":
				return "lift"
		return component.context_key
	return "backstep"
#endregion FUNCTIONS
