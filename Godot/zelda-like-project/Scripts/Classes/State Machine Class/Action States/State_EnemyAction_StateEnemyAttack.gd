##[b][color=red]StateEnemyAttack[/color][/b] - enemy version of the attack state.[br]
##Extends [b]StateAttack[/b] and overrides damage targeting so enemies hit the player (not other enemies).[br]
##Does NOT call super() in enter() to avoid playing the player's "Attack1" animation.[br]
##Uses [b]EnemyAttackComponent[/b] to select the per-attack Area2D and collision shape.
class_name StateEnemyAttack
extends StateAttack

##Attack data source. Wired in the scene to the EnemyAttackComponent node.
@export var attack_component : EnemyAttackComponent

##Resolved during enter() from the attack component.
var _attack_resource : AttackResource = null

func enter() -> void:
	set_process(false)
	_hit_processed = false
	_attack_anim_name = ""
	_attack_facing = ""
	_attack_resource = null
	var _dbg_player_pos := Vector2.ZERO
	var _dbg_enemy_pos := Vector2.ZERO
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " State [color=green][i]entered[/i][/color].")
	var character = get_character()
	if not character:
		push_error(debug_name + ": missing character reference in enter()")
		_exit_to_no_action()
		return
	if character.audio and character.audio is CharacterAudioControl:
		character.audio.play_attack_sound()
	coordinator.context_locked = true
	var _char_anim : CharacterAnimator = null
	if character.anim and character.anim is CharacterAnimator:
		_char_anim = character.anim as CharacterAnimator
	if not attack_component:
		_exit_to_no_action()
		return
	var _in_melee := false
	var _aligned := false
	var _enemy := root as Enemy
	if _enemy and _enemy.body:
		var _e_input : EnemyInputComponent = null
		if _enemy.input is EnemyInputComponent:
			_e_input = _enemy.input as EnemyInputComponent
		var _player_node := _e_input.get_player() if _e_input else null
		if _player_node:
			var _pb := _player_node.get("body") as Node2D
			var _player_pos : Vector2 = _pb.global_position if _pb else _player_node.global_position
			_dbg_player_pos = _player_pos
			_dbg_enemy_pos = _enemy.body.global_position
			if _char_anim:
				var _toward := (_player_pos - _enemy.body.global_position).normalized()
				if _toward != Vector2.ZERO:
					_char_anim.set_facing(_toward)
				_attack_facing = _char_anim.facing
				_char_anim.can_update_facing = false
			var _melee_res := attack_component.find_melee_attack()
			if _melee_res:
				_in_melee = attack_component.is_player_near_attack_area(_melee_res, _attack_facing, _player_pos)
			if not _in_melee:
				var _proj_res := attack_component.find_projectile_attack()
				if _proj_res and _proj_res.projectile_data:
					var _max_dist : float = (_proj_res.projectile_data as ProjectileAttackResource).max_distance
					_aligned = StateChase._is_shot_on_target(_enemy, _attack_facing, _max_dist, _player_pos)
	if not _in_melee and not _aligned:
		_exit_to_no_action()
		return
	_attack_resource = attack_component.get_best_attack(_attack_facing, _in_melee, _aligned)
	if not _attack_resource:
		_exit_to_no_action()
		return
	attack_component.set_active_shape(_attack_resource, _attack_facing)
	var anim_prefix := _attack_resource.animation_name
	if anim_prefix == "":
		_exit_to_no_action()
		return
	if character.anim and character.anim is CharacterAnimator:
		var char_anim := character.anim as CharacterAnimator
		if not char_anim.play_directional_anim(anim_prefix):
			_exit_to_no_action()
			return
		_attack_anim_name = char_anim.current_animation
	set_process(true)
	_debug_log(str("Enemy attack started.",
		"\n  Enemy pos: ", _dbg_enemy_pos,
		"\n  Player pos: ", _dbg_player_pos,
		"\n  Facing: ", _attack_facing,
		"\n  Anim: ", _attack_anim_name))

func exit() -> void:
	if attack_component and _attack_resource:
		var area := attack_component.get_area_for_attack(_attack_resource)
		if area:
			for child in area.get_children():
				if child is CollisionShape2D:
					(child as CollisionShape2D).disabled = true
	super()

func execute_hit() -> void:
	_debug_log(str("Attack hit frame triggered. Facing: ", _attack_facing))
	if _hit_processed:
		return
	_hit_processed = true
	if _attack_resource and (_attack_resource.attack_type == AttackResource.AttackType.PROJECTILE_DIRECTIONAL \
	or _attack_resource.attack_type == AttackResource.AttackType.PROJECTILE_AREA):
		var proj_character = get_character()
		if proj_character and proj_character.body and _attack_resource.projectile_data:
			var _enemy := root as Enemy
			var _e_input : EnemyInputComponent = null
			if _enemy and _enemy.input is EnemyInputComponent:
				_e_input = _enemy.input as EnemyInputComponent
			var _dir := facing_to_vector(_attack_facing)
			var _spawn_pos : Vector2 = proj_character.body.global_position + _dir * 12.0
			attack_component.spawn_projectile(
				_attack_resource.projectile_data,
				_spawn_pos,
				_dir,
				_attack_resource.get_damage_amount()
			)
			var shooter : Character = proj_character as Character
			if shooter and shooter.has_method("receive_knockback"):
				var shoot_class : int = shooter.get_weight_class()
				var recoil_dist : float = _proj_kb_dist(shoot_class) * 0.45
				shooter.receive_knockback(-_dir, recoil_dist)
		return
	if not attack_component:
		_debug_log("No attack component assigned!")
		return
	var area := attack_component.get_area_for_attack(_attack_resource)
	if not area:
		_debug_log("No attack area found for current resource!")
		return
	var character = get_character()
	if not character or not character.body:
		return
	var col_shape := attack_component.get_collision_shape(_attack_resource, _attack_facing)
	if not col_shape or not col_shape.shape:
		_debug_log("No collision shape found for facing: " + _attack_facing)
		return
	var space_state = character.body.get_world_2d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters2D.new()
	shape_query.shape = col_shape.shape
	shape_query.transform = area.global_transform * col_shape.transform
	shape_query.collision_mask = area.collision_mask
	shape_query.collide_with_areas = true
	shape_query.exclude = [character.body.get_rid()]
	var results = space_state.intersect_shape(shape_query, 32)
	var processed_entities : Array = []
	for result in results:
		var collider = result["collider"]
		if not collider or not is_instance_valid(collider):
			continue
		var entity = _find_entity(collider)
		if entity and not entity in processed_entities:
			processed_entities.append(entity)
			_try_damage_entity(entity)

func _try_damage_entity(entity) -> void:
	if not entity or not is_instance_valid(entity):
		return
	if entity is Enemy:
		return
	if not entity is Player:
		return
	# TODO: check blockable flag once player blocking is implemented
	# TODO: check parryable flag once parry system is implemented
	var damage_amount : int = _attack_resource.get_damage_amount() if _attack_resource else 1
	if entity.has_method("take_damage"):
		entity.take_damage(damage_amount)
		_debug_log(str("Damaged player for ", damage_amount, "."))
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
