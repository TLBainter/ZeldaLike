##[b][color=red]StateBackstep[/color][/b] is the backstep movement state.[br]
##Available from Idle or Walk via actionButton4 when no interactable is present.[br]
##The player steps backward (opposite to facing) at dodge_speed.[br]
##Backstep distance = 0.5 * dodge_speed (pixels). No energy cost, but blocked when exhausted.[br]
##Invulnerable while backstepping. Interrupted early by wall/surface collision.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateBackstep
extends StateDodge

#region VARIABLES

const BACKSTEP_DISTANCE_MULTIPLIER : float = 0.1   # proposed_max = multiplier * dodge_speed

var _backstep_dir      : Vector2 = Vector2.ZERO
var _distance_traveled : float   = 0.0
var _max_dist          : float   = 0.0

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	var character = get_character()
	if coordinator.is_exhausted():
		_debug_log("backstep blocked; exhausted.")
		_safe_transition(StateID.IDLE)
		return
	if character and character.anim:
		_backstep_dir = -facing_to_vector(character.anim.facing)
	else:
		_backstep_dir = Vector2.UP
	if root and "stats" in root and root.stats and root.stats.resource:
		_dodge_speed = root.stats.resource.dodge_speed
	_distance_traveled = 0.0
	_max_dist = _clearance_adjusted_dist(_backstep_dir, BACKSTEP_DISTANCE_MULTIPLIER * _dodge_speed)
	if character and character.audio is CharacterAudioControl:
		character.audio.play_enter_backstep_sound()
	_start_dodge(_backstep_dir)

func _physics_process(_delta : float):
	root.body.velocity = _backstep_dir * _dodge_speed
	root.body.move_and_slide()
	_distance_traveled += _delta * _dodge_speed
	if _distance_traveled >= _max_dist or root.body.get_slide_collision_count() > 0:
		_safe_transition(StateID.IDLE)

func _on_dodge_complete() -> void:
	var character = get_character()
	if character and character.audio is CharacterAudioControl:
		character.audio.play_exit_backstep_sound()

#endregion FUNCTIONS
