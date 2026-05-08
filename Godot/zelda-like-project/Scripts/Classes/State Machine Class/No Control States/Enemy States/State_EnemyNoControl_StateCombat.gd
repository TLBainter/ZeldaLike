##[b][color=red]StateCombat[/color][/b] — freezes movement and triggers the enemy attack on the Action layer.[br]
##After the attack finishes, movement is unfrozen during the inter-attack delay so the enemy repositions.[br]
##After the delay, evaluates: re-attack (player in range/aligned, cap not hit), chase, or default (Roam/Idle).
class_name StateCombat
extends State

##Wired in the scene editor to the StateEnemyAttack node on the Action layer.
@export var enemy_attack_state : Node

##Maximum consecutive ranged re-attacks before forcing a Chase transition.
##Prevents the enemy from projectile-camping indefinitely from one spot.
const MAX_RANGED_REATTACKS : int = 2

var _waiting_for_delay : bool = false
var _delay_timer : float = 0.0
var _ranged_reattack_count : int = 0

func enter() -> void:
	super()
	_waiting_for_delay = false
	_delay_timer = 0.0
	_ranged_reattack_count = 0
	coordinator.freeze_movement()
	# Keep input in Chase mode so player_lost fires if the player escapes during the delay.
	var input := _get_input()
	if input:
		input.set_mode(EnemyInputComponent.AIMode.CHASE)
		_safe_connect(input.player_lost, _on_player_lost)
		var enemy := root as Enemy
		var player := input.get_player()
		if player and enemy and enemy.body and enemy.anim is CharacterAnimator:
			var player_body := player.get("body") as Node2D
			var player_pos := player_body.global_position if player_body else player.global_position
			(enemy.anim as CharacterAnimator).set_facing(player_pos - enemy.body.global_position)
	_trigger_attack()
	set_process(true)

func exit() -> void:
	set_process(false)
	_waiting_for_delay = false
	var input := _get_input()
	if input:
		_safe_disconnect(input.player_lost, _on_player_lost)
		input.set_mode(input.default_mode)
	coordinator.unfreeze_movement()
	super()

func pause() -> void:
	set_process(false)
	var input := _get_input()
	if input:
		_safe_disconnect(input.player_lost, _on_player_lost)
	super()

func resume() -> void:
	var input := _get_input()
	if input:
		_safe_connect(input.player_lost, _on_player_lost)
	set_process(true)
	super()

func _process(delta : float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	if not coordinator.action_layer:
		return
	if _waiting_for_delay:
		_delay_timer -= delta
		if _delay_timer <= 0.0:
			_waiting_for_delay = false
			_evaluate_next_action()
		return
	var action_current = coordinator.action_layer.current_state
	if action_current == enemy_attack_state:
		return
	# Attack finished or was interrupted — begin delay before next decision.
	_start_delay()

func _trigger_attack() -> void:
	coordinator.freeze_movement()
	if enemy_attack_state is State:
		coordinator.request_action_change(enemy_attack_state as State)

func _on_player_lost() -> void:
	_debug_log("Player lost during combat — returning to default.")
	_go_to_default()

func _start_delay() -> void:
	_waiting_for_delay = true
	var enemy := root as Enemy
	var min_d : float = enemy.min_delay_between_attacks if enemy else 0.5
	var max_d : float = enemy.max_delay_between_attacks if enemy else 2.0
	if min_d > max_d:
		min_d = max_d
	_delay_timer = randf_range(min_d, max_d)
	if enemy and enemy.anim is CharacterAnimator:
		(enemy.anim as CharacterAnimator).play_directional_anim(
			(enemy.anim as CharacterAnimator).idle_prefix
		)
	# Unfreeze movement so the enemy can reposition during the inter-attack delay.
	coordinator.unfreeze_movement()
	_debug_log(str("unfreeze_movement — pos=",
		snapped(enemy.body.global_position, Vector2(0.1, 0.1)) if enemy and enemy.body else "?",
		" — waiting ", snapped(_delay_timer, 0.01), "s"))

##Computes the cardinal facing string toward [param player_pos] from the enemy body.
static func _facing_toward(enemy : Enemy, player_pos : Vector2) -> String:
	if not enemy.body:
		return "down"
	var to_player := player_pos - enemy.body.global_position
	if abs(to_player.x) > abs(to_player.y):
		return "right" if to_player.x > 0 else "left"
	return "down" if to_player.y > 0 else "up"

func _evaluate_next_action() -> void:
	var input := _get_input()
	if not input:
		_go_to_default()
		return
	var player := input.get_player()
	if not player:
		_go_to_default()
		return
	var enemy := root as Enemy
	if not enemy or not enemy.attack_component:
		_safe_transition(StateID.CHASE)
		return
	var player_body := player.get("body") as Node2D
	var player_pos : Vector2 = player_body.global_position if player_body else player.global_position
	var dist_to_player := enemy.body.global_position.distance_to(player_pos)
	if dist_to_player > input.lose_distance:
		_debug_log("Re-evaluating: player out of chase range — returning to default.")
		_go_to_default()
		return
	# Compute fresh cardinal facing toward the player's current position.
	var facing : String = _facing_toward(enemy, player_pos)
	var to_player_vec := player_pos - enemy.body.global_position
	# Re-attack if player is in melee range.
	var melee_res := enemy.attack_component.find_melee_attack()
	if melee_res and enemy.attack_component.is_player_near_attack_area(melee_res, facing, player_pos):
		_debug_log("Re-evaluating: melee range met — re-attacking.")
		if enemy.anim is CharacterAnimator:
			(enemy.anim as CharacterAnimator).set_facing(to_player_vec)
		_trigger_attack()
		return
	# Too close for a ranged-only enemy — go to Chase so retreat can begin.
	if dist_to_player < EnemyInputComponent.MIN_COMBAT_RANGE and not melee_res:
		_debug_log("Re-evaluating: too close for ranged attack — transitioning to Chase.")
		_safe_transition(StateID.CHASE)
		return
	# Re-attack only if a projectile in the cardinal facing direction would hit the player.
	var proj_res := enemy.attack_component.find_projectile_attack()
	if proj_res and proj_res.projectile_data and enemy.body:
		var dist : float = enemy.body.global_position.distance_to(player_pos)
		var max_dist : float = (proj_res.projectile_data as ProjectileAttackResource).max_distance
		if dist <= max_dist and StateChase._is_shot_on_target(enemy, facing, max_dist, player_pos):
			if _ranged_reattack_count < MAX_RANGED_REATTACKS:
				_ranged_reattack_count += 1
				_debug_log(str("Re-evaluating: shot on target — re-attacking (", _ranged_reattack_count, "/", MAX_RANGED_REATTACKS, ")."))
				if enemy.anim is CharacterAnimator:
					(enemy.anim as CharacterAnimator).set_facing(to_player_vec)
				_trigger_attack()
				return
			else:
				_debug_log("Re-evaluating: ranged re-attack cap reached — transitioning to Chase.")
				_safe_transition(StateID.CHASE)
				return
	# Point-blank with no available attack — return to Chase to reposition safely.
	if dist_to_player <= StateChase.MIN_ENGAGEMENT_DIST and not melee_res:
		_debug_log("Re-evaluating: point-blank, no melee — transitioning to Chase.")
		_safe_transition(StateID.CHASE)
		return
	_debug_log("Re-evaluating: no clear shot — transitioning to Chase.")
	_safe_transition(StateID.CHASE)

func _go_to_default() -> void:
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
