##[b][color=red]StateDash[/color][/b] is the dash movement state.[br]
##Entered from StateRun via actionButton4 when the player has >= 1 energy.[br]
##The player dashes in their current movement direction at dodge_speed.[br]
##Dash distance = 2 * dodge_speed (pixels). Invulnerable while dashing.[br]
##Interrupted early by wall/surface collision.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateDash
extends StateDodge

#region VARIABLES

##Energy consumed per dash.
const DASH_COST : int = 1
const DASH_DISTANCE_MULTIPLIER : float = 0.6   # proposed_max = multiplier * dodge_speed
const DASH_SPEED_MULTIPLIER    : float = 2.0   # physics velocity = multiplier * dodge_speed
const REBOUND_BASE_DIST        : float = 16.0  # pixels of rebound at zero travel distance
const REBOUND_TRAVEL_FACTOR    : float = 0.25  # extra rebound pixels per pixel traveled

var _dash_dir          : Vector2 = Vector2.ZERO
var _clearance_clipped : bool   = false
var _distance_traveled : float  = 0.0
var _max_dist          : float  = 0.0

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	_dodge_executed = false
	var character = get_character()
	if not coordinator.consume_energy(DASH_COST):
		_debug_log("not enough energy to dash.")
		_safe_transition(StateKeys.IDLE)
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
	var _proposed_max : float = DASH_DISTANCE_MULTIPLIER * _dodge_speed
	_max_dist = _clearance_adjusted_dist(_dash_dir, _proposed_max)
	_clearance_clipped = _max_dist < _proposed_max
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
	_start_dodge(_dash_dir)

func _physics_process(_delta : float):
	root.body.velocity = _dash_dir * (DASH_SPEED_MULTIPLIER * _dodge_speed)
	root.body.move_and_slide()
	_distance_traveled += _delta * DASH_SPEED_MULTIPLIER * _dodge_speed
	if root.body.get_slide_collision_count() > 0:
		var rebound_dist : float = REBOUND_BASE_DIST + _distance_traveled * REBOUND_TRAVEL_FACTOR
		var _rebound : StateDashRebound = coordinator.get_transition(StateKeys.DASH_REBOUND) as StateDashRebound
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
			_safe_transition(StateKeys.IDLE)
		return
	if _distance_traveled >= _max_dist:
		var _rebound2 : StateDashRebound = coordinator.get_transition(StateKeys.DASH_REBOUND) as StateDashRebound
		if _clearance_clipped and _rebound2:
			var rebound_dist : float = REBOUND_BASE_DIST + _distance_traveled * REBOUND_TRAVEL_FACTOR
			if debug_me:
				print_rich(debug_name, ": [color=red][i]object hit (clearance clipped)[/i][/color]: dist_traveled=[i]",
					snappedf(_distance_traveled, 0.01), "[/i] rebound_dist=[i]", snappedf(rebound_dist, 0.01), "[/i]")
			_rebound2.setup(-_dash_dir, rebound_dist, _dodge_speed)
			state_machine.change_state(coordinator.try_transition(state_machine, _rebound2, "dash+object_hit_rebound"))
		else:
			_safe_transition(StateKeys.IDLE)

func _on_dodge_complete() -> void:
	var character = get_character()
	if character and character.audio is CharacterAudioControl:
		character.audio.stop_dash_loop()
		character.audio.play_exit_dash_sound()

#endregion FUNCTIONS
