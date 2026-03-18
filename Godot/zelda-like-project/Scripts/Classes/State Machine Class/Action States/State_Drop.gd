##[b][color=red]StateDrop[/color][/b] is the Action layer state for dropping a held object.[br]
##Places the object at the player's feet, re-enables its collision, and transitions to NoAction.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateDrop
extends State

#region VARIABLES

@export_group("In-Layer Transitions")
##The state to return to after dropping.
@export var no_action_state : Node ## : State

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
		if debug_me:
			printerr(debug_name, ": Nothing to drop!")
		if no_action_state:
			state_machine.change_state(no_action_state)
		return
	#Calculate drop position in the facing direction.
	var facing_dir : Vector2 = _get_facing_vector(character.anim.facing) if character.anim else Vector2.DOWN
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
	#Play drop animation if available.
	if character.anim and character.anim is CharacterAnimator:
		character.anim.play_directional_anim("Drop")
	#Play drop sound.
	if held.object_data and held.object_data.material and held.object_data.material.drop_sounds:
		if character.audio:
			character.audio.play_sound(held.object_data.material.drop_sounds.sl.pick_random())
	#Clear held object.
	coordinator.held_object = null
	if debug_me:
		print(debug_name, ": Dropped object at ", drop_pos)
	#Transition to NoAction.
	if no_action_state:
		state_machine.change_state(no_action_state)

##Converts a facing string to a Vector2 direction.
func _get_facing_vector(facing : String) -> Vector2:
	match facing:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN

#endregion FUNCTIONS
