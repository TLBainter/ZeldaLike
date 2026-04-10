##[b][color=red]StateInteract[/color][/b] is the state you first enter when you begin an interaction.[br]
##You may remain in this state if the interaction is ongoing (such as dialogue), or you may exit the interaction immediately.
##[br]
##[b]LAYER[/b]: Action
class_name StateInteract
extends State

#region VARIABLES


##A reference to the InteractableComponent currently being interacted with.[br]
##Used to connect/disconnect the interaction_finished signal.
var _active_interactable : InteractableComponent

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	coordinator.freeze_movement()
	coordinator.update_context("")
	var character = get_character()
	if not character:
		push_error(debug_name + ": missing character reference in enter()")
		var _next : State = coordinator.get_transition("no_action")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "enter+no_character"))
		return
	_debug_log(str("Has pulled a character with a value of ", character))
	if character and character.body.current_interactable:
		_active_interactable = character.body.current_interactable
		var dir_to_interactable : Vector2 = (_active_interactable.global_position - character.body.global_position).normalized()
		if character.anim and character.anim is CharacterAnimator:
			character.anim.can_update_facing = false
			character.anim.force_face(dir_to_interactable)
		_debug_log(str("found a character's interactable with an ID of ", character.body.current_interactable))
		_safe_connect(_active_interactable.interaction_finished, _on_interaction_finished)
		_active_interactable.interact(character)
	else:
		_debug_log("No interactable found, returning to NoAction.")
		var _next2 : State = coordinator.get_transition("no_action")
		if _next2:
			state_machine.change_state(coordinator.try_transition(state_machine, _next2, "enter+no_interactable"))

func exit():
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	if _active_interactable: _safe_disconnect(_active_interactable.interaction_finished, _on_interaction_finished)
	_active_interactable = null
	coordinator.unfreeze_movement()
	coordinator.request_context_refresh()
	super()
			
func _on_interaction_finished():
	var _next : State = coordinator.get_transition("no_action")
	if _next:
		state_machine.change_state(coordinator.try_transition(state_machine, _next, "interaction_finished"))
#endregion FUNCTIONS
