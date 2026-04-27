##[b][color=red]StateDashRebound[/color][/b] is the post-dash rebound movement state.[br]
##Entered from StateDash when the dash is interrupted by a wall or object collision.[br]
##The player is pushed back 10% of the distance they successfully traveled during the dash.[br]
##Rebound stops normally on collision (no chaining). No invulnerability granted.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateDashRebound
extends State

#region VARIABLES

var _rebound_dir: Vector2 = Vector2.ZERO
var _rebound_dist: float = 0.0
var _traveled: float = 0.0
var _dodge_speed: float = 100.0

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	set_physics_process(false)
	super()

##Called by StateDash before transitioning here. Provides rebound parameters.
func setup(direction: Vector2, distance: float, speed: float) -> void:
	_rebound_dir = direction
	_rebound_dist = distance
	_dodge_speed = speed
	print_rich("[color=#FF8C00]Rebound triggered on [/color]", root.name,
		"[color=#FF8C00], traveling [/color]", snappedf(_rebound_dist, 0.01), "[color=#FF8C00] pixels![/color]")
	if debug_me:
		print_rich("[color=#FF8C00][", debug_name, "][/color] setup(); dir=", _rebound_dir,
			"  dist=", snappedf(_rebound_dist, 0.01), "  speed=", _dodge_speed)

func enter() -> void:
	super()
	_traveled = 0.0
	root.body.velocity = _rebound_dir * (2.0 * _dodge_speed)
	set_physics_process(true)
	var character = get_character()
	if character and character.audio is CharacterAudioControl:
		character.audio.play_rebound_sound()
	if debug_me:
		print_rich("[color=#FF8C00][", debug_name, "][/color] enter(); _rebound_dist=",
			snappedf(_rebound_dist, 0.01), "  _rebound_dir=", _rebound_dir)

func _physics_process(delta: float) -> void:
	root.body.velocity = _rebound_dir * (2.0 * _dodge_speed)
	root.body.move_and_slide()
	_traveled += delta * 2.0 * _dodge_speed
	if debug_me_verbose:
		print_rich("[color=#FF8C00][", debug_name, "][/color] tick; traveled=",
			snappedf(_traveled, 0.01), " / ", snappedf(_rebound_dist, 0.01))
	if _traveled >= _rebound_dist or root.body.get_slide_collision_count() > 0:
		if debug_me:
			var reason := "dist_reached" if _traveled >= _rebound_dist else "collision"
			print_rich("[color=#FF8C00][", debug_name, "][/color] exit; reason=", reason,
				"  traveled=", snappedf(_traveled, 0.01), "  target=", snappedf(_rebound_dist, 0.01))
		_safe_transition(StateKeys.IDLE)
		return

func exit() -> void:
	set_physics_process(false)
	if debug_me:
		print_rich("[color=#FF8C00][", debug_name, "][/color] exit()")
	super()

#endregion FUNCTIONS
