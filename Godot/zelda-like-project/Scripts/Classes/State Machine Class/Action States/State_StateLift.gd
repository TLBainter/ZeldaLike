##[b][color=red]StateLift[/color][/b] is the Action layer state for lifting a DynamicThing.[br]
##Freezes movement, plays the lift animation, and waits for animation_finished to transition to HoldingAction.[br]
##The object is visually moved to the hold offset above the player during the animation.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateLift
extends State

#region VARIABLES

@export_group("Lift Settings")
##The vertical offset above the player's body where the held object sits.
@export var hold_offset : Vector2 = Vector2(0, -20)

#endregion VARIABLES

#region FUNCTIONS

func enter() -> void:
	super()
	var character = get_character()
	if not character:
		push_error(debug_name + ": missing character reference in enter()")
		_safe_transition(StateKeys.NO_ACTION)
		return
	var component: InteractableComponent = character.body.current_interactable
	var interactable = component.owner_entity if component else null
	if not interactable or not interactable is DynamicThing:
		push_error(debug_name + ": no valid DynamicThing to lift in enter()")
		_safe_transition(StateKeys.NO_ACTION)
		return
	coordinator.lift_object(interactable)
	coordinator.freeze_movement()
	if interactable.object_data and interactable.object_data.material and interactable.object_data.material.lift_sounds:
		if character.audio:
			character.audio.play_sound(interactable.object_data.material.lift_sounds.sl.pick_random())
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		var played = character.anim.play_directional_anim(AnimationNames.LIFT, true)
		_debug_log(str("Lift anim played: ", played, ", current animation: ", character.anim.current_animation))
		###===SIGNAL CONNECTION: wait for lift animation to finish===###
		if not character.anim.animation_finished.is_connected(_on_lift_finished):
			character.anim.animation_finished.connect(_on_lift_finished, CONNECT_ONE_SHOT)
		###===END SIGNAL CONNECTION===###
	if interactable.body:
		coordinator.set_meta("pre_lift_pos", interactable.body.global_position)
		coordinator.set_meta("lift_y_offset", interactable.body.global_position.y - character.body.global_position.y)
		if debug_me_verbose:
			print("LIFT: Original object body pos: ", interactable.body.global_position)
			print("LIFT: Player body pos: ", character.body.global_position)
			print("LIFT: Difference (obj - player): ", interactable.body.global_position - character.body.global_position)
	interactable.hold(hold_offset, character)
	_debug_log(str("Lifting ", interactable))

func exit() -> void:
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		_safe_disconnect(character.anim.animation_finished, _on_lift_finished)
	super()

##Called when the lift animation finishes. Transitions to HoldingAction.
func _on_lift_finished(anim_name : String) -> void:
	if not AnimationNames.LIFT in anim_name:
		var character = get_character()
		if character and character.anim:
			if not character.anim.animation_finished.is_connected(_on_lift_finished):
				character.anim.animation_finished.connect(_on_lift_finished, CONNECT_ONE_SHOT)
		return
	_safe_transition(StateKeys.HOLDING_ACTION)

#endregion FUNCTIONS
