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

var idle_state : State
var rebound_state : StateDashRebound

##Energy consumed per dash.
const DASH_COST : int = 1

var _dodge_executed : bool = false
var _dash_dir : Vector2 = Vector2.ZERO
var _distance_traveled : float = 0.0
var _dodge_speed : float = 100.0
var _original_mask : int = -1
var _max_dist : float = 0.0
var _clearance_clipped : bool = false  # True if _max_dist was shortened due to an object ahead.

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_physics_process(false)
	super()

func init_state_refs() -> void:
	idle_state = coordinator.get_state(StateIdling)
	rebound_state = coordinator.get_state(StateDashRebound)

func enter():
	super()
	var character = get_character()
	# Check and consume energy; abort back to idle if insufficient.
	if not coordinator.consume_energy(DASH_COST):
		if debug_me:
			print(debug_name, ": not enough energy to dash.")
		if idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "dash+insufficient_energy"))
		return
	# Determine dash direction from current velocity; fall back to facing.
	if root.body.velocity.length() > 10.0:
		_dash_dir = root.body.velocity.normalized()
	elif character and character.anim:
		_dash_dir = facing_to_vector(character.anim.facing)
	else:
		_dash_dir = Vector2.DOWN
	# Read dodge speed from stats resource.
	if root and "stats" in root and root.stats and root.stats.resource:
		_dodge_speed = root.stats.resource.dodge_speed
	_distance_traveled = 0.0
	# Pass physical distance (velocity = 2x speed, tracking aligned to 2x below).
	var _proposed_max : float = 0.6 * _dodge_speed
	_max_dist = _clearance_adjusted_dist(_dash_dir, _proposed_max)
	_clearance_clipped = _max_dist < _proposed_max
	# Lock facing and grant invulnerability.
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	# Freeze action layer -- no attacking during dash.
	coordinator.freeze_action()
	coordinator.update_context("", true)
	# Prime velocity so the very first physics frame moves correctly.
	root.body.velocity = _dash_dir * _dodge_speed
	# Phase through interactables (Layer 2); keep world geometry (Layer 1).
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 1
	# TEMP: Darken and halve sprite opacity as a dash visual until animations are ready.
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	# TODO: Play 'dash enter' directional animation (e.g. "DashEnterDown") when animations are created.
	if character and character.audio is CharacterAudioControl:
		character.audio.play_enter_dash_sound()
		character.audio.start_dash_loop()
		if debug_me:
			var cac := character.audio as CharacterAudioControl
			var lib := cac.bat_squeak_sounds
			if lib == null:
				print_rich("[color=#4FC3F7][", debug_name, "][/color] bat_squeak_sounds: NOT ASSIGNED")
			elif lib.sl.is_empty():
				print_rich("[color=#4FC3F7][", debug_name, "][/color] bat_squeak_sounds: assigned but EMPTY")
			else:
				print_rich("[color=#4FC3F7][", debug_name, "][/color] bat_squeak_sounds: OK (", lib.sl.size(), " clips)")
	_dodge_executed = true
	set_physics_process(true)

func _physics_process(_delta : float):
	# Maintain dash velocity and apply movement.
	root.body.velocity = _dash_dir * (2.0 * _dodge_speed)
	root.body.move_and_slide()
	_distance_traveled += _delta * 2.0 * _dodge_speed
	# Exit: wall/object collision → rebound; max distance → idle.
	if root.body.get_slide_collision_count() > 0:
		# TODO: Play 'dash exit' directional animation (e.g. "DashExitDown") when animations are created.
		var rebound_dist : float = 16.0 + _distance_traveled * 0.25
		if debug_me:
			var normal : Vector2 = root.body.get_slide_collision(0).get_normal()
			print_rich("[color=#4FC3F7][", debug_name, "][/color] wall hit ; dist_traveled=",
				snappedf(_distance_traveled, 0.01), "  normal=", normal,
				"  rebound_dist=", snappedf(rebound_dist, 0.01),
				"  rebound_state=", rebound_state != null)
		if rebound_state:
			rebound_state.setup(-_dash_dir, rebound_dist, _dodge_speed)
			state_machine.change_state(coordinator.try_transition(state_machine, rebound_state, "dash+wall_hit_rebound"))
		elif idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "dash+wall_hit"))
		return
	if _distance_traveled >= _max_dist:
		# TODO: Play 'dash exit' directional animation (e.g. "DashExitDown") when animations are created.
		if _clearance_clipped and rebound_state:
			# Dash was stopped by an object ahead; rebound away from it.
			var rebound_dist : float = 16.0 + _distance_traveled * 0.25
			if debug_me:
				print_rich("[color=#4FC3F7][", debug_name, "][/color] object hit (clearance clipped) ; dist_traveled=",
					snappedf(_distance_traveled, 0.01), "  rebound_dist=", snappedf(rebound_dist, 0.01))
			rebound_state.setup(-_dash_dir, rebound_dist, _dodge_speed)
			state_machine.change_state(coordinator.try_transition(state_machine, rebound_state, "dash+object_hit_rebound"))
		elif idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "dash+complete"))

##Returns the safe dash distance in physical pixels.
func _clearance_adjusted_dist(direction: Vector2, proposed_max: float) -> float:
	var saved_mask : int = root.body.collision_mask
	root.body.collision_mask = 2  # Interactable Layer only.
	# Quick path: no layer-2 object anywhere in the sweep at all.
	if not root.body.test_move(root.body.global_transform, direction * proposed_max):
		root.body.collision_mask = saved_mask
		return proposed_max
	# Shape-based endpoint check: test the full player collision shape at the endpoint.
	# recovery_as_collision=true causes test_move to report initial overlaps at the from transform.
	var endpoint_xform : Transform2D = root.body.global_transform.translated(direction * proposed_max)
	if not root.body.test_move(endpoint_xform, Vector2.ZERO, null, 0.08, true):
		# Player shape is clear at the endpoint -- passes through all objects in the path.
		root.body.collision_mask = saved_mask
		return proposed_max
	# Shape overlaps at endpoint -- binary-search for the front face of the first blocker.
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
	# TEMP: Restore sprite from dash visual.
	if root.sprite:
		root.sprite.modulate = Color.WHITE
	# Restore collision mask.
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
	super()

#endregion FUNCTIONS
