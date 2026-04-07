##[b][color=red]StateInteract[/color][/b] is the state you first enter when you begin an interaction.[br]
##You may remain in this state if the interaction is ongoing (such as dialogue), or you may exit the interaction immediately.
##[br]
##[b]LAYER[/b]: Action
class_name StateInteract
extends State

#region VARIABLES

var no_action_state : State

#===========#

##A reference to the InteractableComponent currently being interacted with.[br]
##Used to connect/disconnect the interaction_finished signal.
var _active_interactable : InteractableComponent

#endregion VARIABLES

#region FUNCTIONS

func init_state_refs() -> void:
	no_action_state = coordinator.get_state(StateNoAction)

func enter():
	super()
	#Freeze movement during an interactions.
	coordinator.freeze_movement()
	coordinator.update_context("")
	#Get character value
	var character = get_character()
	if not character:
		push_error(debug_name + ": missing character reference in enter()")
		if no_action_state:
			state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "enter+no_character"))
		return
	if character and debug_me:
		print(debug_name, ": Has pulled a character with a value of ", character)
	if character and character.body.current_interactable:
		_active_interactable = character.body.current_interactable
		#Set the facing direction for the character.
		var dir_to_interactable : Vector2 = (_active_interactable.global_position - character.body.global_position).normalized()
		if character.anim and character.anim is CharacterAnimator:
			character.anim.can_update_facing = false
			character.anim.force_face(dir_to_interactable)
		if character.body.current_interactable and debug_me:
			print(debug_name, " found a character's interactable with an ID of ", character.body.current_interactable)
		elif not character.body.current_interactable and debug_me:
			printerr(debug_name, " could not find an interactable!")
		if not _active_interactable.interaction_finished.is_connected(_on_interaction_finished):
			_active_interactable.interaction_finished.connect(_on_interaction_finished)
	#Trigger the interaction.
		_active_interactable.interact(character)
	else:
		if debug_me:
			print(debug_name, ": No interactable found, returning to NoAction.")
		if no_action_state:
			state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "enter+no_interactable"))

func exit():
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	if _active_interactable and _active_interactable.interaction_finished.is_connected(_on_interaction_finished):
		_active_interactable.interaction_finished.disconnect(_on_interaction_finished)
	_active_interactable = null
	coordinator.unfreeze_movement()
	coordinator.request_context_refresh()
	super()
			
func _on_interaction_finished():
	if no_action_state:
		state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "interaction_finished"))
#endregion FUNCTIONS
