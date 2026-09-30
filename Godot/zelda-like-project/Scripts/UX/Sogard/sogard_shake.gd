##Stepped horizontal screen shake for Sogard menus. Amplitude follows the Screen Shake setting level.
class_name SogardShake
extends Node

#region VARIABLES
const AMPLITUDES : Array[int] = [0, 1, 3, 6]

@export_category("Components")
##Node shaken on X. Must expose a position property (Control or Node2D).
@export var target : CanvasItem

@export_category("Settings")
##Screen Shake level 0..3 (Off, Minimal, Standard, Excessive = 0, 1, 3, 6 px).
@export_range(0, 3) var shake_level : int = 2
##Total shake time in milliseconds.
@export var duration_ms : int = 260
##Number of discrete offset steps.
@export var steps : int = 6

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _timer : Timer
var _step : int = 0
var _rest_x : float = 0.0
var _amp : int = 0
var _running : bool = false
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	add_to_group("sogard_shake")
	if settingsManager:
		set_shake_level(settingsManager.get_value(&"shake"))
	_timer = Timer.new()
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_on_step)
	add_child(_timer)

##Settings hook: sets the amplitude level 0..3.
func set_shake_level(l : int) -> void:
	shake_level = clampi(l, 0, 3)

##Shakes target on X alternating +-amp for duration_ms in steps jumps, then restores the rest position.
func shake() -> void:
	_amp = AMPLITUDES[clampi(shake_level, 0, 3)]
	if not target or _amp == 0:
		return
	if not _running:
		_rest_x = target.get_indexed(^"position:x")
	_running = true
	_step = 0
	target.set_indexed(^"position:x", _rest_x + _amp)
	_timer.wait_time = maxf(float(duration_ms) / 1000.0 / float(maxi(steps, 1)), 0.001)
	_timer.start()
	if debug_me:
		print_rich(debug_name, ": [color=yellow]shake[/color] amp=", _amp)

func _on_step() -> void:
	_step += 1
	if _step >= maxi(steps, 1):
		_timer.stop()
		target.set_indexed(^"position:x", _rest_x)
		_running = false
		return
	target.set_indexed(^"position:x", _rest_x + (_amp if _step % 2 == 0 else -_amp))
	if debug_me_verbose:
		print_rich(debug_name, ": shake step ", _step, " x=", target.get_indexed(^"position:x"))
#endregion FUNCTIONS
