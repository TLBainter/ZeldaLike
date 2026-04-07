##[b][color=red]StateIntialized[/color][/b] is the default Movement state.[br]
##While in this state, a character's velocity is 0 and they play an idle animation.[br]
##This state transitions to Move when InputComponent.on_move signal reports an input above the dead zone.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateIdling
extends State

#region VARIABLES

var move_state : State
var backstep_state : State

#endregion VARIABLES

#region FUNCTIONS

func init_state_refs() -> void:
	move_state = coordinator.get_state(StateMove)
	backstep_state = coordinator.get_state(StateBackstep)

	#region enter/exit
func enter():
	super()
	coordinator.update_context(get_context_key())
	root.body.velocity = Vector2.ZERO
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	if not state_machine.is_active:
		return
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		if character.energy and character.energy.is_exhausted_state:
			character.anim.idle_prefix = "ExhaustedIdle"
			character.anim.walk_prefix = "ExhaustedWalk"
		else:
			character.anim.idle_prefix = "Idle"
			character.anim.walk_prefix = "Walk"
		character.anim.play_directional_anim(character.anim.idle_prefix)

func exit():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	super()
	#endregion enter/exit

func pause():
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	super()

##Transitions to the move state if beyond joystick deadzone.
func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength > 0.15 and move_state:
		state_machine.change_state(coordinator.try_transition(state_machine, move_state, "on_move+strength>0.15"))

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
		return coordinator.try_transition(state_machine, backstep_state, "actionButton4+idle+no_interactable")
	if event.is_action_pressed("dash") and backstep_state:
		if coordinator.held_object:
			return null
		if coordinator.is_exhausted() or coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, backstep_state, "dash+idle")
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
			if priority == "lift":
				return "lift"
			elif priority == "grab":
				return "grab"
		return component.context_key
	return "backstep"

#endregion FUNCTIONS
