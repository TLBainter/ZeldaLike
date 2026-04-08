##[b][color=red]StateBatTravel[/color][/b] is the bat travel movement state.[br]
##Entered when the player interacts with a [BatTravelCircle] inside a [BatTravelRoute].[br]
##The player glides along the route's [Curve2D] from one circle to the other.[br]
##No energy cost. No dodge cooldown. Invulnerable while traveling.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateBatTravel
extends State

#region VARIABLES

var _route: BatTravelRoute
##true = traveling from Circle A to Circle B. false = B to A.
var _forward: bool = true
##Pixels traveled along the baked curve so far.
var _progress: float = 0.0
var _baked_length: float = 0.0
var _travel_speed: float = 200.0
var _original_mask: int = -1

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	set_physics_process(false)
	super()

##Called by [BatTravelCircle] before requesting the state change.[br]
##[param is_start]: true if the player entered Circle A (travels A→B), false for B→A.
func setup(route: BatTravelRoute, is_start: bool) -> void:
	_route = route
	_forward = is_start

func enter() -> void:
	super()
	# Guard: need a valid route and curve with at least 2 points.
	if not _route or not _route.curve or _route.curve.point_count < 2:
		_debug_log("invalid route — returning to idle.")
		var _idle: State = coordinator.get_transition("idle")
		if _idle:
			state_machine.change_state(coordinator.try_transition(state_machine, _idle, "bat_travel+invalid_route"))
		return
	_baked_length = _route.curve.get_baked_length()
	_progress = 0.0 if _forward else _baked_length
	_travel_speed = max(_route.travel_speed, _baked_length / 3.0)
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
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _forward:
		_progress += _travel_speed * delta
		if _progress >= _baked_length:
			_progress = _baked_length
			_apply_position()
			_finish()
			return
	else:
		_progress -= _travel_speed * delta
		if _progress <= 0.0:
			_progress = 0.0
			_apply_position()
			_finish()
			return
	_apply_position()
	_update_facing()

func _apply_position() -> void:
	var local_pos: Vector2 = _route.curve.sample_baked(_progress)
	var prev_pos: Vector2 = root.body.global_position
	root.body.global_position = _route.to_global(local_pos)
	# Keep velocity in sync so the camera's move_toward step size stays non-zero.
	var engine_delta: float = get_physics_process_delta_time()
	if engine_delta > 0.0:
		root.body.velocity = (root.body.global_position - prev_pos) / engine_delta

func _update_facing() -> void:
	# Approximate tangent by sampling slightly ahead and behind.
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
	set_physics_process(false)
	var _idle: State = coordinator.get_transition("idle")
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
	_route = null
	super()

func pause() -> void:
	set_physics_process(false)
	super()

func resume() -> void:
	set_physics_process(true)
	super()

#endregion FUNCTIONS
