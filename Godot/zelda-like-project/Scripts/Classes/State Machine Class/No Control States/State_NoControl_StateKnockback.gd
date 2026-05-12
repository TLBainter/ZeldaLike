##[b][color=red]StateKnockback[/color][/b] — entity is launched away from a hit source.[br]
##Phase 1: entity travels in [member _knockback_dir] at [constant KNOCKBACK_SPEED].[br]
##Phase 2 (rebound): triggered by wall collision during phase 1; entity bounces back
##a fraction of the remaining travel distance (not a fixed base like StateDash).[br]
##Invulnerability is active for the entire duration.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StateKnockback
extends State

##Travel speed in pixels/second during knockback and rebound.
const KNOCKBACK_SPEED : float = 200.0
##Fraction of remaining knockback distance used as rebound distance on wall hit.
const REBOUND_TRAVEL_FACTOR : float = 0.25

var _knockback_dir : Vector2 = Vector2.ZERO
var _knockback_dist : float = 0.0
var _traveled : float = 0.0
var _is_rebounding : bool = false
var _rebound_dist : float = 0.0
var _rebound_traveled : float = 0.0

#region SETUP

##Call before [method enter]. Sets the direction and total distance for this knockback.
func setup(direction: Vector2, distance: float) -> void:
	_knockback_dir = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	_knockback_dist = distance

#endregion SETUP

#region STATE LIFECYCLE

func _ready() -> void:
	set_physics_process(false)
	super()

func enter() -> void:
	super()
	_traveled = 0.0
	_is_rebounding = false
	_rebound_dist = 0.0
	_rebound_traveled = 0.0
	coordinator.freeze_all()
	var character = get_character()
	if root and root.get("subtype") == "Player":
		print("[KB enter] character=%s  dir=%s  dist=%s" % [character, _knockback_dir, _knockback_dist])
	if character:
		character.is_invulnerable = true
		character.is_knocked_back = true
		character.is_in_knockback = true
		if character.get("subtype") == "Player":
			print("[KB enter] is_knocked_back SET to true")
	elif root and root.get("subtype") == "Player":
		print("[KB enter] WARNING: get_character() returned null for Player root (type=%s)" % root.get("type"))
	if root and root.body:
		root.body.velocity = _knockback_dir * KNOCKBACK_SPEED
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_physics_process(false)
		return
	if not root or not root.body:
		_finish()
		return

	if _is_rebounding:
		_tick_rebound(delta)
	else:
		_tick_knockback(delta)

func exit() -> void:
	set_physics_process(false)
	var character = get_character()
	if character:
		character.is_invulnerable = false
		character.is_in_knockback = false
		if character.get("subtype") == "Player":
			print("[KB exit] is_knocked_back cleared after grace timer  traveled=%s/%s  rebounding=%s" % [_traveled, _knockback_dist, _is_rebounding])
		var char_ref = character
		get_tree().create_timer(0.15).timeout.connect(func():
			if is_instance_valid(char_ref):
				char_ref.is_knocked_back = false
		)
	coordinator.unfreeze_all()
	super()

#endregion STATE LIFECYCLE

#region PHASES

func _tick_knockback(delta: float) -> void:
	root.body.velocity = _knockback_dir * KNOCKBACK_SPEED
	root.body.move_and_slide()
	_traveled += delta * KNOCKBACK_SPEED

	var hit_wall : bool = root.body.get_slide_collision_count() > 0
	var dist_reached : bool = _traveled >= _knockback_dist

	if hit_wall or dist_reached:
		if hit_wall:
			_start_rebound()
		else:
			_finish()

func _start_rebound() -> void:
	_is_rebounding = true
	_rebound_traveled = 0.0
	var remaining := maxf(0.0, _knockback_dist - _traveled)
	_rebound_dist = remaining * REBOUND_TRAVEL_FACTOR
	root.body.velocity = -_knockback_dir * KNOCKBACK_SPEED

func _tick_rebound(delta: float) -> void:
	root.body.velocity = -_knockback_dir * KNOCKBACK_SPEED
	root.body.move_and_slide()
	_rebound_traveled += delta * KNOCKBACK_SPEED

	var hit_wall : bool = root.body.get_slide_collision_count() > 0
	var dist_reached : bool = _rebound_traveled >= _rebound_dist

	if hit_wall or dist_reached:
		_finish()

func _finish() -> void:
	_safe_transition(StateID.INITIALIZED)

##Forces this knockback into the rebound phase, as if the entity struck a wall.[br]
##No-ops if already rebounding.
func force_rebound() -> void:
	if _is_rebounding:
		return
	_start_rebound()

#endregion PHASES
