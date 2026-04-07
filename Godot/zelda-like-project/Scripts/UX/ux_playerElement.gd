##[b][color=red]UXElement[/color][/b] is the base class for player UI elements that fade in/out.[br]
##Provides common visibility management, fade animation, force-show, and timer logic.[br]
##Subclasses override [b]_on_element_ready()[/b], [b]_on_element_process()[/b], and [b]_can_fade_out()[/b].
class_name UXElement
extends Control

#region VARIABLES

@export_category("Visibility")
##How long the element stays visible after being shown (in seconds).
@export var visibility_duration : float = 3.0
##How fast the element fades in (higher = faster).
@export var fade_in_speed : float = 12.0
##How fast the element fades out (lower = slower).
@export var fade_out_speed : float = 2.0

@export_category("UX Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

#=======INTERNAL VARIABLES=======#

##Current target alpha for fade in/out.
var _target_alpha : float = 0.0
##Whether the element is currently forced visible (zoom, exhaustion, etc).
var _force_visible : bool = false
##Timer reference for visibility countdown.
var _visibility_timer : Timer

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	modulate.a = 0.0
	_target_alpha = 0.0
	set_process(false)
	_visibility_timer = Timer.new()
	_visibility_timer.one_shot = true
	_visibility_timer.wait_time = visibility_duration
	_visibility_timer.timeout.connect(_on_visibility_timeout)
	add_child(_visibility_timer)
	_on_element_ready()

##Virtual. Called at the end of _ready() for subclass-specific setup.
func _on_element_ready() -> void:
	pass

func _process(delta : float) -> void:
	_on_element_process(delta)
	_process_fade(delta)

##Virtual. Called each frame before fade processing. Override for per-frame logic.
func _on_element_process(_delta : float) -> void:
	pass

##Handles fade interpolation toward _target_alpha.
func _process_fade(delta : float) -> void:
	if modulate.a != _target_alpha:
		var speed = fade_in_speed if _target_alpha > modulate.a else fade_out_speed
		modulate.a = move_toward(modulate.a, _target_alpha, speed * delta)
		if modulate.a <= 0.0:
			modulate.a = 0.0
			if not _force_visible:
				set_process(false)

#region VISIBILITY

##Makes the element visible and starts the visibility countdown.
func show_element() -> void:
	_target_alpha = 1.0
	_visibility_timer.stop()
	_visibility_timer.start(visibility_duration)
	set_process(true)

##Called when the visibility timer expires. Fades out if [b]_can_fade_out()[/b] returns true.
func _on_visibility_timeout() -> void:
	if _force_visible:
		return
	if _can_fade_out():
		_target_alpha = 0.0

##Virtual. Returns whether the element should fade out when the timer expires.[br]
##Override to add conditions (e.g., only fade if resource is full).
func _can_fade_out() -> bool:
	return true

##Forces the element to stay visible or releases it.
func force_show(should_force : bool) -> void:
	_force_visible = should_force
	if should_force:
		_target_alpha = 1.0
		_visibility_timer.stop()
		set_process(true)
	else:
		if _should_start_fade_timer():
			_visibility_timer.start(visibility_duration)

##Virtual. Returns whether to start the fade timer when force_show(false) is called.[br]
##Override if the element has additional conditions (e.g., ticking animation).
func _should_start_fade_timer() -> bool:
	return true

#endregion VISIBILITY

#endregion FUNCTIONS
