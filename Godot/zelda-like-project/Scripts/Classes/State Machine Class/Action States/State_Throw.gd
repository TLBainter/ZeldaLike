##[b][color=red]StateThrow[/color][/b] is the Action layer state for throwing a held object.[br]
##Launches the object as a projectile in the facing direction. Distance is affected by weight.[br]
##Waits for the projectile to land, then transitions to NoAction.[br]
##[br]
##[b]Layer[/b]: Action
class_name StateThrow
extends State

#region VARIABLES

@export_group("In-Layer Transitions")
##The state to return to after the throw completes.
@export var no_action_state : Node ## : State

##Reference to the active projectile component (created dynamically).
var _projectile : ProjectileComponent

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	var character = get_character()
	var held = coordinator.held_object
	if not character or not held:
		push_error(debug_name + ": missing character or held object in enter()")
		if no_action_state:
			state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "enter+no_character_or_held"))
		return
	if character.energy:
		if not character.energy.consume(1):
			if debug_me:
				print(debug_name, ": Not enough energy to throw, dropping instead.")
			if no_action_state:
				state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "enter+insufficient_energy"))
			return
	#Freeze movement during the throw.
	coordinator.freeze_movement()
	#Calculate throw direction from facing.
	var facing_dir : Vector2 = facing_to_vector(character.anim.facing) if character.anim else Vector2.DOWN
	#Detach the object from the player's hold position.
	held.release(held.body.global_position + (facing_dir * 8.0), false) 
	#Play throw animation.
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		character.anim.play_directional_anim("Throw")
	#Play throw sound.
	if held.object_data and held.object_data.material and held.object_data.material.throw_sounds:
		if character.audio:
			character.audio.play_sound(held.object_data.material.throw_sounds.sl.pick_random())
	#Create and launch the projectile component.
	_projectile = ProjectileComponent.new()
	_projectile.debug_me = debug_me
	_projectile.debug_me_verbose = debug_me_verbose
	_projectile.debug_name = debug_name + "/Projectile"
	held.add_child(_projectile)
	###===SIGNAL CONNECTION: wait for projectile to land===###
	if not _projectile.projectile_landed.is_connected(_on_projectile_landed):
		_projectile.projectile_landed.connect(_on_projectile_landed, CONNECT_ONE_SHOT)
	###===END SIGNAL CONNECTION===###
	#Seed drop scatter so breaks use throw direction (away from player) instead of circular default.
	if held is DynamicThing:
		held._damaged_by_attack = true
		held._last_damage_source_pos = character.body.global_position
	var data = held.object_data
	var base_distance : float = data.throw_distance if data else 80.0
	var throw_speed : float = data.throw_speed if data else 150.0
	var arc : float = data.throw_arc_height if data else 8.0
	var throw_distance : float = _calculate_throw_distance(held, base_distance)
	_projectile.launch(held, facing_dir, throw_distance, throw_speed, arc)
	#Clear the held object from the coordinator.
	coordinator.held_object = null
	if debug_me:
		print(debug_name, ": Threw object ", facing_dir, " distance=", throw_distance)

func exit():
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	coordinator.unfreeze_movement()
	#Clean up projectile reference.
	_projectile = null
	super()

##Called when the projectile lands or hits something.
func _on_projectile_landed(broke : bool):
	if debug_me:
		print(debug_name, ": Projectile landed. Broke: ", broke)
	#Clean up the projectile node.
	if _projectile and is_instance_valid(_projectile):
		_projectile.queue_free()
		_projectile = null
	if no_action_state:
		state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "projectile_landed"))

##Calculates throw distance based on object weight.[br]
##Light (10): full distance. Medium (30): ~66%. Heavy (60): ~33%.
func _calculate_throw_distance(held, base_distance : float = 80.0) -> float:
	var weight : int = 10
	if held.stats and held.stats.resource:
		weight = held.stats.resource.weight
	var weight_factor : float = clampf(1.0 - (float(weight) / 80.0), 0.25, 1.0)
	return base_distance * weight_factor

#endregion FUNCTIONS
