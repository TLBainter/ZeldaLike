##[b][color=red]StateKnockback[/color][/b] — entity is launched away from a hit source.[br]
##Phase 1: entity travels in [member _knockback_dir] at [constant KNOCKBACK_SPEED].[br]
##Phase 2 (rebound): triggered by wall or body collision during phase 1; entity bounces back
##using the same formula as StateDashRebound.[br]
##Invulnerability is active for the entire duration.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StateKnockback
extends State

##Travel speed in pixels/second during knockback and rebound.
const KNOCKBACK_SPEED : float = 200.0
##Fixed base added to the rebound distance (mirrors StateDash.REBOUND_BASE_DIST).
const REBOUND_BASE_DIST : float = 16.0
##Fraction of knockback distance traveled that is added to rebound distance.
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
	if character:
		character.is_invulnerable = true
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
	_rebound_dist = REBOUND_BASE_DIST + _traveled * REBOUND_TRAVEL_FACTOR
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

#endregion PHASES
