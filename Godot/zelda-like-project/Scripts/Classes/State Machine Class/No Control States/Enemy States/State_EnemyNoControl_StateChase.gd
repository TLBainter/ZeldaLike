##[b][color=red]StateChase[/color][/b] — the enemy follows the player and enters Combat when in melee range.[br]
##Uses [b]EnemyInputComponent[/b] to drive movement via the shared on_move signal pipeline.
class_name StateChase
extends State

##Minimum distance (px) before a ranged-only enemy is considered at point-blank range.
##Below this distance the enemy forces Combat to freeze movement and break sticky-collision tracking.
const MIN_ENGAGEMENT_DIST : float = 20.0
##Seconds after entering Chase before combat re-evaluation is allowed.
##Prevents the frame-perfect Combat→Chase→Combat loop when the enemy is inside the nav
##agent's target_desired_distance zone and StateChase would otherwise immediately retrigger Combat.
const COMBAT_REENTRY_COOLDOWN : float = 0.35
##How long (seconds) the enemy must be retreating without adequate progress before giving up.
const RETREAT_STUCK_THRESHOLD : float = 0.8
##Minimum pixels moved during [constant RETREAT_STUCK_THRESHOLD] seconds to be considered not stuck.
const RETREAT_STUCK_MIN_DIST : float = 8.0

var _reentry_timer : float = 0.0
var _retreat_stuck_timer : float = 0.0
var _retreat_check_pos : Vector2 = Vector2.ZERO

func enter() -> void:
	super()
	_reentry_timer = COMBAT_REENTRY_COOLDOWN
	var input := _get_input()
	if not input:
		return
	input.set_mode(EnemyInputComponent.AIMode.CHASE)
	_safe_connect(input.player_lost, _on_player_lost)
	set_physics_process(true)

func exit() -> void:
	set_physics_process(false)
	_retreat_stuck_timer = 0.0
	_retreat_check_pos = Vector2.ZERO
	var input := _get_input()
	if input:
		_safe_disconnect(input.player_lost, _on_player_lost)
		input.set_mode(input.default_mode)
	super()

func pause() -> void:
	set_physics_process(false)
	_retreat_stuck_timer = 0.0
	_retreat_check_pos = Vector2.ZERO
	var input := _get_input()
	if input:
		_safe_disconnect(input.player_lost, _on_player_lost)
	super()

func resume() -> void:
	var input := _get_input()
	if input:
		_safe_connect(input.player_lost, _on_player_lost)
	set_physics_process(true)
	super()

func _physics_process(delta : float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_physics_process(false)
		return
	if _reentry_timer > 0.0:
		_reentry_timer -= delta
		return
	var enemy := root as Enemy
	if not enemy or not enemy.attack_component:
		return
	var input := _get_input()
	if not input:
		return
	var player := input.get_player()
	if not player:
		return
	var player_body := player.get("body") as Node2D
	var player_pos : Vector2 = player_body.global_position if player_body else player.global_position
	if input.is_retreating and enemy.body:
		if _retreat_check_pos == Vector2.ZERO:
			_retreat_check_pos = enemy.body.global_position
		_retreat_stuck_timer += delta
		if _retreat_stuck_timer >= RETREAT_STUCK_THRESHOLD:
			var moved : float = enemy.body.global_position.distance_to(_retreat_check_pos)
			_retreat_check_pos = enemy.body.global_position
			_retreat_stuck_timer = 0.0
			if moved < RETREAT_STUCK_MIN_DIST:
				_debug_log("Retreat stuck — forcing COMBAT.")
				_safe_transition(StateID.COMBAT)
				return
	else:
		_retreat_stuck_timer = 0.0
		_retreat_check_pos = Vector2.ZERO
	var facing : String = StateCombat._facing_toward(enemy, player_pos)
	var melee_res := enemy.attack_component.find_melee_attack()
	if melee_res and enemy.attack_component.is_player_near_attack_area(melee_res, facing, player_pos):
		_debug_log("Melee range met — transitioning to COMBAT.")
		_safe_transition(StateID.COMBAT)
		return
	var proj_res := enemy.attack_component.find_projectile_attack()
	if proj_res and proj_res.projectile_data:
		var max_dist : float = (proj_res.projectile_data as ProjectileAttackResource).max_distance
		if _is_shot_on_target(enemy, facing, max_dist, player_pos):
			_debug_log("Shot on target — transitioning to COMBAT.")
			_safe_transition(StateID.COMBAT)

func _on_player_lost() -> void:
	var input := _get_input()
	if input and input.default_mode == EnemyInputComponent.AIMode.ROAM:
		_safe_transition(StateID.ROAM)
	else:
		_safe_transition(StateID.IDLE)

func _get_input() -> EnemyInputComponent:
	var enemy := root as Enemy
	if enemy and enemy.input is EnemyInputComponent:
		return enemy.input as EnemyInputComponent
	return null

##Returns true if no wall (collision layer 32) blocks the straight line from the enemy body to [param player_pos].
static func _has_line_of_sight(enemy : Enemy, player_pos : Vector2) -> bool:
	if not enemy.body:
		return false
	var space := enemy.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		enemy.body.global_position, player_pos, 32, [enemy.body.get_rid()]
	)
	return space.intersect_ray(query).is_empty()

##Returns true if the player centre is within 8 px of the firing axis, within [param max_dist],
##and no wall (collision layer 32) blocks the line to [param player_pos].
static func _is_shot_on_target(enemy : Enemy, facing : String, max_dist : float, player_pos : Vector2) -> bool:
	if not enemy.body:
		return false
	var fire_dir : Vector2
	match facing:
		"up":    fire_dir = Vector2.UP
		"left":  fire_dir = Vector2.LEFT
		"right": fire_dir = Vector2.RIGHT
		_:       fire_dir = Vector2.DOWN
	var to_player := player_pos - enemy.body.global_position
	var forward_dist := to_player.dot(fire_dir)
	if forward_dist <= 0.0 or forward_dist > max_dist:
		return false
	var perp_dist := (to_player - fire_dir * forward_dist).length()
	if perp_dist > 8.0:
		return false
	var space := enemy.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		enemy.body.global_position, player_pos, 32, [enemy.body.get_rid()]
	)
	return space.intersect_ray(query).is_empty()
