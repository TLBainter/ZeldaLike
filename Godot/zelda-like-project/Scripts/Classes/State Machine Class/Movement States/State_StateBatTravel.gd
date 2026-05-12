##[b][color=red]StateBatTravel[/color][/b] is the bat travel movement state.[br]
##Entered when the player interacts with a [BatTravelCircle] inside a [BatTravelRoute].[br]
##[br]
##Travel has two phases:[br]
##[b]1. Approach[/b]; player moves linearly from their actual position to the curve's second
##   control point (the first interior waypoint). Avoids snapping to the entry endpoint.[br]
##[b]2. Curve[/b]; player follows the baked [Curve2D] from the second point onward, arriving
##   exactly at the center of the destination circle.[br]
##[br]
##No energy cost. No dodge cooldown. Invulnerable while traveling.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateBatTravel
extends State

#region VARIABLES

const SMOKE_VFX_SCENE = preload("res://Scenes/VFX/Particle Systems/vfx_bat_smoke.tscn")

var _route: BatTravelRoute
var _smoke_vfx : GPUParticles2D = null
##true = traveling from Circle A to Circle B. false = B to A.
var _forward: bool = true
var _baked_length: float = 0.0
var _travel_speed: float = 200.0
var _original_mask: int = -1

##World position the player starts from (their actual global_position at enter()).
var _approach_start: Vector2 = Vector2.ZERO
##World position of the curve's second control point (the join to the main curve).
var _approach_target: Vector2 = Vector2.ZERO
##Total distance of the approach segment.
var _approach_dist: float = 0.0
##Distance traveled so far during the approach phase.
var _approach_traveled: float = 0.0
##True while the player is still in the approach phase.
var _in_approach: bool = false

##Baked-curve offset at which the curve phase begins (at the second control point).
var _progress: float = 0.0

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	set_physics_process(false)
	super()

##Called by [BatTravelCircle] before requesting the state change.[br]
##[param is_start]: true if the player entered Circle A (travels A->B), false for B->A.
func setup(route: BatTravelRoute, is_start: bool) -> void:
	_route = route
	_forward = is_start

##Returns true while this state is actively traveling along [param route].[br]
##Used by [BatTravelCircle] to drive its EXTRA_QUICK animation tier.
func is_traveling_on(route: BatTravelRoute) -> bool:
	return _route != null and _route == route

func enter() -> void:
	super()
	if not _route or not _route.curve or _route.curve.point_count < 2:
		_debug_log("invalid route; returning to idle.")
		var _idle: State = coordinator.get_transition(StateID.IDLE)
		if _idle:
			state_machine.change_state(coordinator.try_transition(state_machine, _idle, "bat_travel+invalid_route"))
		return

	_baked_length = _route.curve.get_baked_length()
	_travel_speed = max(_route.travel_speed, _baked_length / 3.0)

	var second_idx: int = 1 if _forward else (_route.curve.point_count - 2)
	var second_local: Vector2 = _route.curve.get_point_position(second_idx)
	_approach_target = _route.to_global(second_local)

	_progress = _route.curve.get_closest_offset(second_local)

	_approach_start    = root.body.global_position
	_approach_traveled = 0.0
	_approach_dist     = _approach_start.distance_to(_approach_target)
	_in_approach = _approach_dist > 0.5

	if debug_me_verbose:
		print("[BatTravel] === ENTER ===")
		print("[BatTravel]   forward:          ", _forward)
		print("[BatTravel]   player pos:        ", root.body.global_position)
		print("[BatTravel]   approach_start:    ", _approach_start)
		print("[BatTravel]   approach_target:   ", _approach_target)
		print("[BatTravel]   approach_dist:     ", _approach_dist)
		print("[BatTravel]   curve_start_prog:  ", _progress)
		print("[BatTravel]   baked_length:      ", _baked_length)
		print("[BatTravel]   in_approach:       ", _in_approach)
		var dest_local: Vector2 = _route.curve.sample_baked(_baked_length if _forward else 0.0)
		print("[BatTravel]   destination world: ", _route.to_global(dest_local))

	root.is_invulnerable = true
	root.is_dashing = true
	coordinator.freeze_action()
	coordinator.update_context("", true)
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 1
	root.body.velocity = Vector2.ZERO
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	var character = get_character()
	if character and character.audio is CharacterAudioControl:
		character.audio.play_enter_dash_sound()
		character.audio.start_dash_loop()
	_smoke_vfx = SMOKE_VFX_SCENE.instantiate() as GPUParticles2D
	_smoke_vfx.local_coords = false
	root.body.add_child(_smoke_vfx)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _in_approach:
		_approach_traveled += _travel_speed * delta
		if _approach_traveled >= _approach_dist:
			root.body.global_position = _approach_target
			_in_approach = false
		else:
			var t: float = _approach_traveled / _approach_dist
			var prev_pos: Vector2 = root.body.global_position
			root.body.global_position = _approach_start.lerp(_approach_target, t)
			_sync_velocity(prev_pos)
			var dir: Vector2 = (_approach_target - _approach_start).normalized()
			if dir.length_squared() > 0.01:
				var character = get_character()
				if character and character.anim and character.anim is CharacterAnimator:
					character.anim.force_face(dir)
			if debug_me_verbose:
				print("[BatTravel] APPROACH  t=", snappedf(t, 0.001), "  pos=", root.body.global_position)
		return

	if debug_me_verbose:
		print("[BatTravel] CURVE  progress=", snappedf(_progress, 0.1), "  pos=", root.body.global_position)

	if _forward:
		_progress += _travel_speed * delta
		if _progress >= _baked_length:
			_progress = _baked_length
			_apply_curve_position()
			_finish()
			return
	else:
		_progress -= _travel_speed * delta
		if _progress <= 0.0:
			_progress = 0.0
			_apply_curve_position()
			_finish()
			return
	_apply_curve_position()
	_update_facing()

func _apply_curve_position() -> void:
	var local_pos: Vector2 = _route.curve.sample_baked(_progress)
	var prev_pos: Vector2 = root.body.global_position
	root.body.global_position = _route.to_global(local_pos)
	_sync_velocity(prev_pos)

func _sync_velocity(prev_pos: Vector2) -> void:
	var engine_delta: float = get_physics_process_delta_time()
	if engine_delta > 0.0:
		root.body.velocity = (root.body.global_position - prev_pos) / engine_delta

func _update_facing() -> void:
	var ahead: float = clamp(_progress + 2.0, 0.0, _baked_length)
	var behind: float = clamp(_progress - 2.0, 0.0, _baked_length)
	var dir: Vector2 = (_route.curve.sample_baked(ahead) - _route.curve.sample_baked(behind)).normalized()
	if not _forward:
		dir = -dir
	if dir.length_squared() > 0.01:
		var character = get_character()
		if character and character.anim and character.anim is CharacterAnimator:
			character.anim.force_face(dir)

func _finish() -> void:
	if debug_me_verbose:
		print("[BatTravel] === FINISH ===")
		print("[BatTravel]   final player pos:  ", root.body.global_position)
	set_physics_process(false)
	var _idle: State = coordinator.get_transition(StateID.IDLE)
	if _idle:
		state_machine.change_state(coordinator.try_transition(state_machine, _idle, "bat_travel+complete"))

func exit() -> void:
	set_physics_process(false)
	root.body.velocity = Vector2.ZERO
	if root.sprite:
		root.sprite.modulate = Color.WHITE
	if _original_mask != -1:
		root.body.collision_mask = _original_mask
		_original_mask = -1
	root.is_dashing = false
	root.is_invulnerable = false
	coordinator.unfreeze_action()
	var character = get_character()
	if character and character.audio is CharacterAudioControl:
		character.audio.stop_dash_loop()
		character.audio.play_exit_dash_sound()
	_in_approach = false
	_route = null
	_detach_smoke()
	super()

func _detach_smoke() -> void:
	if not is_instance_valid(_smoke_vfx):
		_smoke_vfx = null
		return
	var vfx := _smoke_vfx
	_smoke_vfx = null
	vfx.reparent(root.get_tree().current_scene)
	vfx.emitting = false
	root.get_tree().create_timer(vfx.lifetime + 0.5).timeout.connect(vfx.queue_free)

func pause() -> void:
	set_physics_process(false)
	super()

func resume() -> void:
	set_physics_process(true)
	super()

#endregion FUNCTIONS
