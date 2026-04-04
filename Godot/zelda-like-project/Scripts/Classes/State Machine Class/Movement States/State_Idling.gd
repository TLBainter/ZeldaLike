##[b][color=red]StateIntialized[/color][/b] is the default Movement state.[br]
##While in this state, a character's velocity is 0 and they play an idle animation.[br]
##This state transitions to Move when InputComponent.on_move signal reports an input above the dead zone.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateIdling
extends State

#region VARIABLES

@export_group("Transitions")
##The state to enter when movement input is detected.
@export var move_state : State

#endregion VARIABLES

#region FUNCTIONS
	#region enter/exit
func enter():
	super()
	coordinator.update_context(get_context_key())
	root.body.velocity = Vector2.ZERO
	if not state_machine.is_active:
		if root.input and not root.input.on_move.is_connected(_on_move):
			root.input.on_move.connect(_on_move)
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
				return "pickup"
			elif priority == "grab":
				return "grab"
		return component.context_key
	return ""

#endregion FUNCTIONS
