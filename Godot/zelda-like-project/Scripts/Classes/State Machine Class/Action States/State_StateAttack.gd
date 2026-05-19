class_name StateAttack
extends State

#region VARIABLES

@export_group("Transitions")
@export var no_action_state : Node

@export_group("Attack Settings")
@export var attack_area : Area2D
@export var energy_cost : int = 1
@export var attack_config : AttackConfiguration = AttackConfiguration.new()


var _hit_processed : bool = false
var _attack_anim_name : String = ""
var _attack_facing : String = ""

#endregion VARIABLES

#region FUNCTIONS

func enter() -> void:
	set_process(false)
	super()
	_hit_processed = false
	_attack_anim_name = ""
	_attack_facing = ""
	var character = get_character()
	if not character:
		push_error(debug_name + ": missing character reference in enter()")
		_exit_to_no_action()
		return
	if character.energy and energy_cost > 0:
		if not character.energy.consume(energy_cost):
			_debug_log("Not enough energy to attack.")
			_exit_to_no_action()
			return
	if character.audio and character.audio is CharacterAudioControl:
		character.audio.play_attack_sound()
	coordinator.context_locked = true
	if character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false
		_attack_facing = character.anim.facing
		_attack_anim_name = "Attack1" + _attack_facing.capitalize().replace(" ", "")
	_rotate_attack_area(character)
	if character.anim and character.anim is CharacterAnimator:
		character.anim.play_directional_anim("Attack1", true)
	set_process(true)
	_debug_log(str("Attack started. Facing: ", _attack_facing, " Anim: ", _attack_anim_name))

func exit() -> void:
	set_process(false)
	if attack_area:
		attack_area.set_deferred("monitoring", false)
	coordinator.context_locked = false
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true
	if no_action_state is StateNoAction:
		var speed: float = 0.0
		if character and character.stats and character.stats.resource:
			speed = character.stats.resource.attack_speed
		(no_action_state as StateNoAction).mark_attack_used(speed)
	super()

func _process(_delta : float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	if _attack_anim_name == "":
		return
	var character = get_character()
	if not character or not character.anim:
		push_error(debug_name + ": missing character/anim reference in _process()")
		_exit_to_no_action()
		return
	var cur_anim = character.anim.current_animation
	if cur_anim != _attack_anim_name and cur_anim != "":
		_debug_log(str("Animation ended or interrupted. Current: '", cur_anim, "' Expected: '", _attack_anim_name, "'"))
		_exit_to_no_action()
	elif cur_anim == "":
		_debug_log(str("Animation finished: '", _attack_anim_name, "'"))
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
		state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "attack_animation_finished"))

func _rotate_attack_area(character) -> void:
	if not attack_area or not character.anim:
		return
	var facing = character.anim.facing
	if attack_config.offsets.has(facing):
		var data = attack_config.offsets[facing]
		attack_area.position = data["position"]
		attack_area.rotation_degrees = data["rotation"]
	attack_area.set_deferred("monitoring", false)

func execute_hit() -> void:
	if _hit_processed:
		return
	_hit_processed = true
	if not attack_area:
		_debug_log("No attack area assigned!")
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
		_debug_log("No collision shape found in attack area!")
		return
	shape_query.shape = col_shape.shape
	var player_pos = character.body.global_position
	var offset_data = attack_config.offsets.get(_attack_facing, attack_config.offsets.get("down", {}))
	var shape_pos = player_pos + offset_data["position"]
	var shape_rot = deg_to_rad(offset_data["rotation"]) + col_shape.rotation
	shape_query.transform = Transform2D(shape_rot, shape_pos)
	shape_query.collision_mask = attack_area.collision_mask
	shape_query.collide_with_areas = true
	shape_query.exclude = [character.body.get_rid()]
	if debug_me_verbose:
		print_rich("--- [b]ATTACK HIT DEBUG[/b] ---")
		print_rich("  Facing: [i]", _attack_facing, "[/i]")
		print_rich("  Player pos: [i]", player_pos, "[/i]")
		print_rich("  Offset: [i]", offset_data["position"], "[/i] Rotation: [i]", offset_data["rotation"], "[/i]")
		print_rich("  Shape query pos: [i]", shape_pos, "[/i]")
		print_rich("  Shape query rot (deg): [i]", rad_to_deg(shape_rot), "[/i]")
		print_rich("  Shape type: [i]", col_shape.shape, "[/i]")
		print_rich("  Shape local pos: [i]", col_shape.position, "[/i] local rot (deg): [i]", rad_to_deg(col_shape.rotation), "[/i]")
		print_rich("  Collision mask: [i]", attack_area.collision_mask, "[/i]")
		print_rich("  Area2D global pos: [i]", attack_area.global_position, "[/i]")
		print_rich("  Area2D global rot (deg): [i]", rad_to_deg(attack_area.global_rotation), "[/i]")
	var results = space_state.intersect_shape(shape_query, 32)
	if debug_me_verbose:
		print_rich("  Results count: [i]", results.size(), "[/i]")
		for idx in range(results.size()):
			var r = results[idx]
			print_rich("    Result [i]", idx, "[/i]: collider=[i]", r["collider"], "[/i] ([i]", r["collider"].name if r["collider"] else "null", "[/i])")
	var processed_entities = []
	for result in results:
		var collider = result["collider"]
		if not collider or not is_instance_valid(collider):
			if debug_me_verbose:
				print_rich("    [color=red][i]Skipped invalid collider[/i][/color]")
			continue
		if collider is WorldItem:
			collider.try_pickup(character.body)
			continue
		var entity = _find_entity(collider)
		if debug_me_verbose:
			print_rich("    Collider: [i]", collider.name, "[/i] -> Entity: [i]", entity, "[/i] ([i]", entity.name if entity else "null", "[/i])")
		if entity and not entity in processed_entities:
			processed_entities.append(entity)
			_try_damage_entity(entity)
	if debug_me_verbose:
		print_rich("--- [b]END HIT DEBUG[/b] ---")

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
		_debug_log(str("Damaged ", entity, " for 1."))
		_apply_melee_knockback(entity)

func _apply_melee_knockback(entity) -> void:
	var character : Character = get_character() as Character
	if not character or not character.body:
		return
	var attacker_pos : Vector2 = character.body.global_position
	var target_pos : Vector2
	if "body" in entity and entity.body:
		target_pos = entity.body.global_position
	elif entity is Node2D:
		target_pos = (entity as Node2D).global_position
	else:
		return
	var dir : Vector2 = (target_pos - attacker_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var a_class : int = character.get_weight_class()
	var t_class : int = entity.get_weight_class() if entity.has_method("get_weight_class") else 2
	if entity.has_method("receive_knockback"):
		var t_dist : float = _melee_kb_dist(t_class, a_class)
		entity.receive_knockback(dir, t_dist)
	var a_dist : float = _melee_kb_dist(a_class, t_class) * 0.25
	character.receive_knockback(-dir, a_dist)

static func _melee_kb_dist(attacker_class: int, target_class: int) -> float:
	match target_class - attacker_class:
		2:  return 24.0
		1:  return 12.0
		0:  return 6.0
		-1: return 3.0
		_:  return 6.0

static func _proj_kb_dist(weight_class: int) -> float:
	match weight_class:
		1: return 12.0
		2: return 6.0
		_: return 3.0

#endregion FUNCTIONS
