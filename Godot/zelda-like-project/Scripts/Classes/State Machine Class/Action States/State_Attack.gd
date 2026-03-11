class_name StateAttack
extends State

#region CONSTANTS

const ATTACK_OFFSETS : Dictionary = {
	"down": { "position": Vector2(0, 6), "rotation": 0.0 },
	"up": { "position": Vector2(0, -6), "rotation": 180.0 },
	"left": { "position": Vector2(-6, 0), "rotation": 90.0 },
	"right": { "position": Vector2(6, 0), "rotation": -90.0 },
}

#endregion CONSTANTS

#region VARIABLES

@export_group("Transitions")
@export var no_action_state : Node

@export_group("Attack Settings")
@export var attack_area : Area2D
@export var energy_cost : int = 1

#=======INTERNAL VARIABLES=======#

var _hit_processed : bool = false
var _expected_anim : String = ""
var _attack_facing : String = ""

#endregion VARIABLES

#region FUNCTIONS

func enter() -> void:
	set_process(false)
	super()
	_hit_processed = false
	_expected_anim = ""
	_attack_facing = ""
	var character = get_character()
	if not character:
		_exit_to_no_action()
		return
	if character.energy and energy_cost > 0:
		if not character.energy.consume(energy_cost):
			if debug_me:
				print(debug_name, ": Not enough energy to attack.")
			_exit_to_no_action()
			return
	coordinator.context_locked = true
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		_attack_facing = character.anim.facing
		_expected_anim = "Attack1" + _attack_facing.capitalize().replace(" ", "")
	_rotate_attack_area(character)
	if character.anim and character.anim is CharacterAnimator:
		character.anim.play_directional_anim("Attack1", true)
	set_process(true)
	if debug_me:
		print(debug_name, ": Attack started. Facing: ", _attack_facing, " Anim: ", _expected_anim)

func exit() -> void:
	set_process(false)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	coordinator.context_locked = false
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	super()

func _process(_delta : float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	if _expected_anim == "":
		return
	var character = get_character()
	if not character or not character.anim:
		_exit_to_no_action()
		return
	#If our animation is no longer playing, exit.
	var cur_anim = character.anim.current_animation
	if cur_anim != _expected_anim and cur_anim != "":
		if debug_me:
			print(debug_name, ": Animation ended or interrupted. Current: '", cur_anim, "' Expected: '", _expected_anim, "'")
		_exit_to_no_action()
	elif cur_anim == "":
		#Animation finished (current_animation clears when done). Exit.
		if debug_me:
			print(debug_name, ": Animation finished.")
		_exit_to_no_action()

func pause() -> void:
	set_process(false)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	super()

func resume() -> void:
	set_process(true)
	super()

func _exit_to_no_action() -> void:
	if no_action_state:
		state_machine.change_state(no_action_state)

func _rotate_attack_area(character) -> void:
	if not attack_area or not character.anim:
		return
	var facing = character.anim.facing
	if ATTACK_OFFSETS.has(facing):
		var data = ATTACK_OFFSETS[facing]
		attack_area.position = data["position"]
		attack_area.rotation_degrees = data["rotation"]
	attack_area.set_deferred("monitoring", false)

func execute_hit() -> void:
	if _hit_processed:
		return
	_hit_processed = true
	if not attack_area:
		if debug_me:
			print(debug_name, ": No attack area assigned!")
		return
	var character = get_character()
	if not character or not character.body:
		return
	var space_state = character.body.get_world_2d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters2D.new()
	var col_shape : CollisionShape2D = null
	for child in attack_area.get_children():
		if child is CollisionShape2D:
			col_shape = child
			break
	if not col_shape or not col_shape.shape:
		if debug_me:
			print(debug_name, ": No collision shape found in attack area!")
		return
	shape_query.shape = col_shape.shape
	var player_pos = character.body.global_position
	var offset_data = ATTACK_OFFSETS.get(_attack_facing, ATTACK_OFFSETS["down"])
	var shape_pos = player_pos + offset_data["position"]
	var shape_rot = deg_to_rad(offset_data["rotation"]) + col_shape.rotation
	shape_query.transform = Transform2D(shape_rot, shape_pos)
	shape_query.collision_mask = attack_area.collision_mask
	shape_query.exclude = [character.body.get_rid()]
	if debug_me and debug_me_verbose:
		print("--- ATTACK HIT DEBUG ---")
		print("  Facing: ", _attack_facing)
		print("  Player pos: ", player_pos)
		print("  Offset: ", offset_data["position"], " Rotation: ", offset_data["rotation"])
		print("  Shape query pos: ", shape_pos)
		print("  Shape query rot (deg): ", rad_to_deg(shape_rot))
		print("  Shape type: ", col_shape.shape)
		print("  Shape local pos: ", col_shape.position, " local rot (deg): ", rad_to_deg(col_shape.rotation))
		print("  Collision mask: ", attack_area.collision_mask)
		print("  Area2D global pos: ", attack_area.global_position)
		print("  Area2D global rot (deg): ", rad_to_deg(attack_area.global_rotation))
	var results = space_state.intersect_shape(shape_query, 32)
	if debug_me_verbose:
		print("  Results count: ", results.size())
		for idx in range(results.size()):
			var r = results[idx]
			print("    Result ", idx, ": collider=", r["collider"], " (", r["collider"].name if r["collider"] else "null", ")")
	var processed_entities = []
	for result in results:
		var collider = result["collider"]
		if not collider or not is_instance_valid(collider):
			if debug_me_verbose:
				print("    Skipped invalid collider")
			continue
		var entity = _find_entity(collider)
		if debug_me_verbose:
			print("    Collider: ", collider.name, " → Entity: ", entity, " (", entity.name if entity else "null", ")")
		if entity and not entity in processed_entities:
			processed_entities.append(entity)
			_try_damage_entity(entity)
	if debug_me_verbose:
		print("--- END HIT DEBUG ---")

func _find_entity(node : Node):
	if "root" in node and node.root:
		return node.root
	var current = node
	for i in range(5):
		if current == null:
			break
		if current.has_method("take_damage"):
			return current
		if "health" in current:
			return current
		if "root" in current and current.root:
			return current.root
		current = current.get_parent()
	return null

func _try_damage_entity(entity) -> void:
	if not entity or not is_instance_valid(entity):
		return
	if entity is Player:
		return
	if entity.has_method("take_damage"):
		entity.take_damage(1)
		if debug_me:
			print(debug_name, ": Damaged ", entity, " for 1.")
	elif "health" in entity and entity.health:
		entity.health.hurt(1)
		if debug_me:
			print(debug_name, ": Damaged ", entity, " health for 1.")

func get_context_key() -> String:
	return "attack"

#endregion FUNCTIONS
