##Single short notice shown top-center in the Sogard overlay layer. Never focusable; clears itself after duration_ms.
class_name SogardToast
extends PanelContainer

#region VARIABLES
signal cleared()

const SCENE_PATH : String = "res://Scenes/UX/Sogard/sogard_toast.tscn"
const NODE_NAME : String = "SogardToast"

@export_category("Components")
@export var label : Label
@export var clear_timer : Timer

@export_category("Settings")
##Time on screen in milliseconds.
@export var duration_ms : int = 1800
##Frame stylebox. Default: #1a0508 fill, 1 px #8a0a16 border, 8/4 px padding.
@export var frame_style : StyleBox:
	set(v):
		frame_style = v
		if is_node_ready():
			_apply_style()
##Top edge in pixels from the viewport top. Horizontally centered.
@export var top_px : int = 46
##Fade-in time in milliseconds. 0 disables the fade.
@export var fade_ms : int = 120
##Fade-in step count.
@export var fade_steps : int = 2

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_style()
	if clear_timer:
		clear_timer.one_shot = true
		clear_timer.ignore_time_scale = true
		clear_timer.timeout.connect(_on_clear)
	if not visible or not label or label.text.is_empty():
		hide()

##Returns the single toast in the overlay layer (created on first use) after showing t on it.
static func toast(from : Node, t : String) -> SogardToast:
	var layer : SogardOverlay = SogardOverlay.host_layer(from)
	var existing : SogardToast = layer.get_node_or_null(NODE_NAME) as SogardToast
	if not existing:
		var scene : PackedScene = load(SCENE_PATH) as PackedScene
		if not scene:
			push_error("SogardToast: missing scene " + SCENE_PATH)
			return null
		existing = scene.instantiate() as SogardToast
		existing.name = NODE_NAME
		layer.add_child(existing)
	existing.show_text(t)
	return existing

##Shows t, recenters, replays the fade and restarts the clear timer.
func show_text(t : String) -> void:
	if label:
		label.text = t
	show()
	_place()
	if fade_ms > 0:
		SogardStepper.run(self, self, ^"modulate:a", 0.0, 1.0, fade_ms, fade_steps)
	else:
		SogardStepper.stop(self, self, ^"modulate:a")
		modulate.a = 1.0
	if clear_timer:
		clear_timer.start(maxf(float(duration_ms) / 1000.0, 0.001))
	if debug_me:
		print_rich(debug_name, ": [color=yellow]toast[/color] ", t)

func _apply_style() -> void:
	if frame_style:
		add_theme_stylebox_override("panel", frame_style)
	else:
		remove_theme_stylebox_override("panel")

func _place() -> void:
	var min_size : Vector2 = get_combined_minimum_size()
	var vp_w : float = get_viewport_rect().size.x
	size = min_size
	position = Vector2(floorf((vp_w - min_size.x) * 0.5), float(top_px))

func _on_clear() -> void:
	SogardStepper.stop(self, self, ^"modulate:a")
	hide()
	if debug_me_verbose:
		print_rich(debug_name, ": toast cleared")
	cleared.emit()
#endregion FUNCTIONS
