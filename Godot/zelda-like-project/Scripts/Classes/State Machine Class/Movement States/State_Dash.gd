##[b][color=red]StateDash[/color][/b] is the dash movement state.[br]
##Entered from StateRun via actionButton4 when the player has >= 1 energy.[br]
##The player dashes in their current movement direction at dodge_speed.[br]
##Dash distance = 2 * dodge_speed (pixels). Invulnerable while dashing.[br]
##Interrupted early by wall/surface collision.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateDash
extends State

#region VARIABLES

##Energy consumed per dash.
const DASH_COST : int = 1
const SMOKE_VFX_SCENE = preload("res://Scenes/VFX/Particle Systems/vfx_bat_smoke.tscn")

var _dodge_executed : bool = false
var _smoke_vfx : GPUParticles2D = null
var _dash_dir : Vector2 = Vector2.ZERO
var _distance_traveled : float = 0.0
var _dodge_speed : float = 100.0
var _original_mask : int = -1
var _max_dist : float = 0.0
var _clearance_clipped : bool = false

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_physics_process(false)
	super()

func enter():
	super()
	_dodge_executed = false
	var character = get_character()
	if not coordinator.consume_energy(DASH_COST):
		_debug_log("not enough energy to dash.")
		var _next : State = coordinator.get_transition("idle")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "dash+insufficient_energy"))
		return
	if root.body.velocity.length() > 10.0:
		_dash_dir = root.body.velocity.normalized()
	elif character and character.anim:
		_dash_dir = facing_to_vector(character.anim.facing)
	else:
		_dash_dir = Vector2.DOWN
	if root and "stats" in root and root.stats and root.stats.resource:
		_dodge_speed = root.stats.resource.dodge_speed
	_distance_traveled = 0.0
	var _proposed_max : float = 0.6 * _dodge_speed
	_max_dist = _clearance_adjusted_dist(_dash_dir, _proposed_max)
	_clearance_clipped = _max_dist < _proposed_max
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	coordinator.freeze_action()
	coordinator.update_context("", true)
	root.body.velocity = _dash_dir * _dodge_speed
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 1
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	if character and character.audio is CharacterAudioControl:
		character.audio.play_enter_dash_sound()
		character.audio.start_dash_loop()
		if debug_me:
			var cac := character.audio as CharacterAudioControl
			var lib := cac.bat_squeak_sounds
			if lib == null:
				print_rich(debug_name, ": [color=red][i]bat_squeak_sounds: NOT ASSIGNED[/i][/color]")
			elif lib.sl.is_empty():
				print_rich(debug_name, ": [color=red][i]bat_squeak_sounds: assigned but EMPTY[/i][/color]")
			else:
				print_rich(debug_name, ": [color=green][i]bat_squeak_sounds: OK ([/i][/color][i]", lib.sl.size(), "[/i][color=green][i] clips)[/i][/color]")
	_smoke_vfx = SMOKE_VFX_SCENE.instantiate() as GPUParticles2D
	_smoke_vfx.local_coords = false
	root.body.add_child(_smoke_vfx)
	_dodge_executed = true
	set_physics_process(true)

func _physics_process(_delta : float):
	root.body.velocity = _dash_dir * (2.0 * _dodge_speed)
	root.body.move_and_slide()
	_distance_traveled += _delta * 2.0 * _dodge_speed
	if root.body.get_slide_collision_count() > 0:
		var rebound_dist : float = 16.0 + _distance_traveled * 0.25
		var _rebound : StateDashRebound = coordinator.get_transition("dash_rebound") as StateDashRebound
		if debug_me:
			var normal : Vector2 = root.body.get_slide_collision(0).get_normal()
			print_rich(debug_name, ": [color=red][i]wall hit[/i][/color]: dist_traveled=[i]",
				snappedf(_distance_traveled, 0.01), "[/i] normal=[i]", normal,
				"[/i] rebound_dist=[i]", snappedf(rebound_dist, 0.01),
				"[/i] rebound_state=[i]", _rebound != null, "[/i]")
		if _rebound:
			_rebound.setup(-_dash_dir, rebound_dist, _dodge_speed)
			state_machine.change_state(coordinator.try_transition(state_machine, _rebound, "dash+wall_hit_rebound"))
		else:
			var _next : State = coordinator.get_transition("idle")
			if _next:
				state_machine.change_state(coordinator.try_transition(state_machine, _next, "dash+wall_hit"))
		return
	if _distance_traveled >= _max_dist:
		var _rebound2 : StateDashRebound = coordinator.get_transition("dash_rebound") as StateDashRebound
		if _clearance_clipped and _rebound2:
			var rebound_dist : float = 16.0 + _distance_traveled * 0.25
			if debug_me:
				print_rich(debug_name, ": [color=red][i]object hit (clearance clipped)[/i][/color]: dist_traveled=[i]",
					snappedf(_distance_traveled, 0.01), "[/i] rebound_dist=[i]", snappedf(rebound_dist, 0.01), "[/i]")
			_rebound2.setup(-_dash_dir, rebound_dist, _dodge_speed)
			state_machine.change_state(coordinator.try_transition(state_machine, _rebound2, "dash+object_hit_rebound"))
		else:
			var _next2 : State = coordinator.get_transition("idle")
			if _next2:
				state_machine.change_state(coordinator.try_transition(state_machine, _next2, "dash+complete"))

##Returns the safe dash distance in physical pixels.
func _clearance_adjusted_dist(direction: Vector2, proposed_max: float) -> float:
	var saved_mask : int = root.body.collision_mask
	root.body.collision_mask = 2
	if not root.body.test_move(root.body.global_transform, direction * proposed_max):
		root.body.collision_mask = saved_mask
		return proposed_max
	var endpoint_xform : Transform2D = root.body.global_transform.translated(direction * proposed_max)
	if not root.body.test_move(endpoint_xform, Vector2.ZERO, null, 0.08, true):
		root.body.collision_mask = saved_mask
		return proposed_max
	var lo : float = 0.0
	var hi : float = proposed_max
	for _i in range(12):
		var mid : float = (lo + hi) / 2.0
		if root.body.test_move(root.body.global_transform, direction * mid):
			hi = mid
		else:
			lo = mid
	root.body.collision_mask = saved_mask
	return lo

func exit():
	set_physics_process(false)
	if root.sprite:
		root.sprite.modulate = Color.WHITE
	if _original_mask != -1:
		root.body.collision_mask = _original_mask
		_original_mask = -1
	root.is_dashing = false
	root.is_invulnerable = false
	unlock_facing()
	coordinator.unfreeze_action()
	if _dodge_executed:
		coordinator.start_dodge_cooldown()
		var character = get_character()
		if character and character.audio is CharacterAudioControl:
			character.audio.stop_dash_loop()
			character.audio.play_exit_dash_sound()
	_dodge_executed = false
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

#endregion FUNCTIONS
