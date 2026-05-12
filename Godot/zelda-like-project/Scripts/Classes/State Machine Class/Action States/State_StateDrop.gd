##[b][color=red]StateDrop[/color][/b] is the Action layer state for dropping a held object.[br]
##Places the object at the player's feet, re-enables its collision, and transitions to NoAction.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateDrop
extends State

#region VARIABLES

@export_group("Drop Settings")
##Offset from the player's body position where the object is placed on drop.[br]
##Typically a small distance in the facing direction.
@export var drop_distance : float = 12.0

#endregion VARIABLES

#region FUNCTIONS

func enter() -> void:
	super()
	var character = get_character()
	var held = coordinator.held_object
	if not character or not held:
		push_error(debug_name + ": missing character or held object in enter()")
		_safe_transition(StateID.NO_ACTION)
		return
	var drop_pos : Vector2 = character.body.global_position
	match character.anim.facing if character.anim else "down":
		"right":
			drop_pos.x += 12
			drop_pos.y -= 6
		"left":
			drop_pos.x -= 12
			drop_pos.y -= 6
		"down":
			drop_pos.y += 6
		"up":
			drop_pos.y -= 21
	held.release(drop_pos)
	if debug_me_verbose:
		var pre_lift = coordinator.get_meta("pre_lift_pos") if coordinator.has_meta("pre_lift_pos") else Vector2.ZERO
		print("--- DROP POSITION DEBUG ---")
		print("  Pre-lift object pos: ", pre_lift)
		print("  Player body pos: ", character.body.global_position)
		print("  Player-to-original offset: ", pre_lift - character.body.global_position)
		print("  Calculated drop pos: ", drop_pos)
		print("  Drop vs original diff: ", drop_pos - pre_lift)
		print("--- END DROP POSITION DEBUG ---")
		print("  After release body pos: ", held.body.global_position)
		print("  After release sprite pos: ", held.root.sprite.position if held.root and held.root.sprite else "no sprite")
		print("--- END DROP DEBUG ---")
	if character.anim and character.anim is CharacterAnimator:
		character.anim.play_directional_anim("Drop")
	if held.object_data and held.object_data.material and held.object_data.material.drop_sounds:
		if character.audio:
			character.audio.play_sound(held.object_data.material.drop_sounds.sounds.pick_random())
	coordinator.release_held()
	_debug_log(str("Dropped object at ", drop_pos))
	_safe_transition(StateID.NO_ACTION)

#endregion FUNCTIONS
