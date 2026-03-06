##[b][color=red]StateLift[/color][/b] is the Action layer state for lifting a DynamicInteractable.[br]
##Freezes movement, plays the lift animation, and waits for animation_finished to transition to HoldingAction.[br]
##The object is visually moved to the hold offset above the player during the animation.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateLift
extends State

#region VARIABLES

@export_group("In-Layer Transitions")
##The state to enter once the lift animation finishes.
@export var holding_action_state : Node ## : State
##The state to return to if the lift fails.
@export var no_action_state : Node ## : State

@export_group("Lift Settings")
##The vertical offset above the player's body where the held object sits.
@export var hold_offset : Vector2 = Vector2(0, -12)

#endregion VARIABLES

#region FUNCTIONS

func enter() -> void:
	super()
	var character = get_character()
	if not character:
		if no_action_state:
			state_machine.change_state(no_action_state)
		return
	#Get the DynamicInteractable via the Interact node.
	var interact_node = character.body.current_interactable
	var interactable = interact_node.root if (interact_node and "root" in interact_node) else null
	if not interactable or not interactable is DynamicInteractable:
		if debug_me:
			printerr(debug_name, ": No valid DynamicInteractable to lift.")
		if no_action_state:
			state_machine.change_state(no_action_state)
		return
	#Store the held object on the coordinator.
	coordinator.held_object = interactable
	#Freeze movement during lift.
	coordinator.freeze_movement()
	if interactable.object_data and interactable.object_data.material and interactable.object_data.material.lift_sounds:
		if character.audio:
			character.audio.play_sound(interactable.object_data.material.lift_sounds.sl.pick_random())
	#Lock facing direction.
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		character.anim.play_directional_anim("Lift")
		var played = character.anim.play_directional_anim("Lift", true)
		if debug_me:
			print("Lift anim played: ", played, ", current animation: ", character.anim.current_animation)
		###===SIGNAL CONNECTION: wait for lift animation to finish===###
		if not character.anim.animation_finished.is_connected(_on_lift_finished):
			character.anim.animation_finished.connect(_on_lift_finished, CONNECT_ONE_SHOT)
		###===END SIGNAL CONNECTION===###
	#Disable collision on the held object.
	interactable.hold(hold_offset, character)
	if debug_me:
		print(debug_name, ": Lifting ", interactable)

func exit() -> void:
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		#Disconnect if still connected (safety).
		if character.anim.animation_finished.is_connected(_on_lift_finished):
			character.anim.animation_finished.disconnect(_on_lift_finished)
	super()

##Called when the lift animation finishes. Transitions to HoldingAction.
func _on_lift_finished(anim_name : String) -> void:
	if holding_action_state:
		state_machine.change_state(holding_action_state)

#endregion FUNCTIONS
