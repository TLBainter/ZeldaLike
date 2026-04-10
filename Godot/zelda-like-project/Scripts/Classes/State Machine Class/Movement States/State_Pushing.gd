##[b][color=red]StatePushing[/color][/b] is the [b]Movement layer[/b] state for pushing a grabbed object.[br]
##Smoothly moves both the player and object 8px in the facing direction.[br]
##Holding directional input causes continuous snaps with a weight-based delay between them.[br]
##Returns to GrabIdle when input stops. Transitions to Pulling if input reverses (and object is pullable).[br]
##[br]
##[b]Layer[/b]: Movement
class_name StatePushing
extends State

#region VARIABLES

##Whether input is currently being held along the push axis.
var _input_held : bool = false
##Whether a snap timer is currently active (prevents overlapping snaps).
var _snap_timer_active : bool = false
##Whether a smooth snap is currently in progress.
var _is_snapping : bool = false
##The target position for the player during a smooth snap.
var _player_snap_target : Vector2 = Vector2.ZERO
##The speed of the smooth snap in pixels per second.
var _snap_speed : float = 80.0

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	_input_held = true
	_snap_timer_active = false
	_is_snapping = false
	root.body.velocity = Vector2.ZERO
	###===SIGNAL CONNECTION===###
	if root.input: _safe_connect(root.input.on_move, _on_move)
	###===END SIGNAL CONNECTION===###
	_perform_snap()

func exit():
	_is_snapping = false
	set_physics_process(false)
	_input_held = false
	_snap_timer_active = false
	root.body.velocity = Vector2.ZERO
	###===SIGNAL DISCONNECTION===###
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	###===END SIGNAL DISCONNECTION===###
	super()

func pause() -> void:
	_input_held = false
	_snap_timer_active = false
	_is_snapping = false
	set_physics_process(false)
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume() -> void:
	if root.input: _safe_connect(root.input.on_move, _on_move)
	super()

##Tracks directional input. Returns to GrabIdle if input stops.[br]
##Transitions to Pulling if input reverses and object is pullable.
func _on_move(move_input : Vector2, move_strength : float) -> void:
	if move_strength < GameConstants.JOYSTICK_DEADZONE:
		_input_held = false
		if not _is_snapping:
			var _gi : State = coordinator.get_transition("grab_idle")
			if _gi:
				state_machine.change_state(coordinator.try_transition(state_machine, _gi, "on_move+strength<0.15"))
		return
	var character = get_character()
	if not character or not character.anim:
		return
	var facing_dir : Vector2 = facing_to_vector(character.anim.facing)
	var dot : float = move_input.normalized().dot(facing_dir)
	if dot > 0.5:
		_input_held = true
	elif dot < -0.5:
		_input_held = false
		if not _is_snapping:
			var grabbed = coordinator.grabbed_object
			if grabbed and grabbed.object_data and grabbed.object_data.pullable:
				var _pull : State = coordinator.get_transition("pulling")
				if _pull:
					state_machine.change_state(coordinator.try_transition(state_machine, _pull, "on_move+dot<-0.5+pullable"))
			else:
				var _gi2 : State = coordinator.get_transition("grab_idle")
				if _gi2:
					state_machine.change_state(coordinator.try_transition(state_machine, _gi2, "on_move+dot<-0.5+not_pullable"))
	else:
		_input_held = false
		if not _is_snapping:
			var _gi3 : State = coordinator.get_transition("grab_idle")
			if _gi3:
				state_machine.change_state(coordinator.try_transition(state_machine, _gi3, "on_move+perpendicular"))

##Attempts to smoothly snap the object and player 8px in the facing direction.
func _perform_snap() -> void:
	if _is_snapping:
		return
	var character = get_character()
	if not character:
		return
	var grabbed = coordinator.grabbed_object
	if not grabbed:
		return
	var facing_str : String = character.anim.facing
	if facing_str not in ["up", "down", "left", "right"]:
		return
	var facing_dir : Vector2 = facing_to_vector(facing_str)
	var weight : int = 30
	if grabbed.stats and grabbed.stats.resource:
		weight = grabbed.stats.resource.weight
	_snap_speed = 120.0 - (float(weight) * 0.8)
	if grabbed.smooth_snap_move(facing_dir, GameConstants.SNAP_DISTANCE, _snap_speed):
		_is_snapping = true
		_player_snap_target = character.body.global_position + (facing_dir * GameConstants.SNAP_DISTANCE)
		if not grabbed.snap_move_completed.is_connected(_on_snap_completed):
			grabbed.snap_move_completed.connect(_on_snap_completed, CONNECT_ONE_SHOT)
		set_physics_process(true)
		if character.anim and character.anim is CharacterAnimator:
			character.anim.play_directional_anim("Push")
		if grabbed.object_data and grabbed.object_data.material and grabbed.object_data.material.move_sounds:
			if character.audio:
				character.audio.play_sound(grabbed.object_data.material.move_sounds.sl.pick_random())
		_debug_log(str("Snapping push ", facing_dir))
	else:
		_start_snap_timer(grabbed)


func _physics_process(delta : float) -> void:
	if not _is_snapping:
		set_physics_process(false)
		return
	var character = get_character()
	if not character:
		return
	var distance_left = character.body.global_position.distance_to(_player_snap_target)
	var move_amount = _snap_speed * delta
	if move_amount >= distance_left:
		var remaining = _player_snap_target - character.body.global_position
		var collision = character.body.move_and_collide(remaining)
		if collision:
			_is_snapping = false
			set_physics_process(false)
	else:
		var direction = (_player_snap_target - character.body.global_position).normalized()
		var collision = character.body.move_and_collide(direction * move_amount)
		if collision:
			_is_snapping = false
			set_physics_process(false)

##Called when the smooth snap finishes. Checks for continued input or grab release.
func _on_snap_completed() -> void:
	_is_snapping = false
	set_physics_process(false)
	var character = get_character()
	if character:
		character.body.global_position = _player_snap_target
	if not root.input or not root.input.is_action_button_held("actionButton4"):
		_input_held = false
		var _gi : State = coordinator.get_transition("grab_idle")
		if _gi:
			state_machine.change_state(coordinator.try_transition(state_machine, _gi, "snap_completed+button_released"))
		return
	var grabbed = coordinator.grabbed_object
	if grabbed:
		_start_snap_timer(grabbed)

##Starts a timer based on the object's weight. On timeout, snaps again if input is held.
func _start_snap_timer(grabbed) -> void:
	if _snap_timer_active:
		return
	_snap_timer_active = true
	var delay : float = _get_snap_delay(grabbed)
	get_tree().create_timer(delay).timeout.connect(_on_snap_timer)

##Called when the snap delay expires. Performs another snap if input is still held.
func _on_snap_timer() -> void:
	_snap_timer_active = false
	if not root.input or not root.input.is_action_button_held("actionButton4"):
		_input_held = false
		var _gi : State = coordinator.get_transition("grab_idle")
		if _gi:
			state_machine.change_state(coordinator.try_transition(state_machine, _gi, "snap_timer+button_released"))
		return
	if _input_held:
		_perform_snap()

##Calculates the delay between snaps based on object weight.[br]
##Light (10): ~0.15s, Medium (30): ~0.35s, Heavy (60): ~0.65s
func _get_snap_delay(grabbed) -> float:
	var weight : int = 30
	if grabbed.stats and grabbed.stats.resource:
		weight = grabbed.stats.resource.weight
	return 0.05 + (float(weight) * 0.01)

func get_context_key() -> String:
	return "grab"

#endregion FUNCTIONS
