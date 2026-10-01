##Gamepad-first Sogard settings row: a labeled 0-10 slider drawn as layered atlas art (background, red dither fill, foreground frame), stepped by handle_direction. Keys and pad route through SogardNavInput; a left press or drag on the track sets the value.
@tool
class_name SogardSliderRow
extends Control

#region VARIABLES
signal value_changed(value : int)

const TRACK_X : int = 284
const TRACK_Y : int = 5
const TRACK_W : int = 100
const TRACK_H : int = 10
const ART_X : int = 280
const ART_W : int = 104
const FILL_Y : int = 6
const FILL_H : int = 8
const BG_X : int = 281
const PIP_COUNT : int = 10
const TRACK_HIT_PAD : float = 4.0
const TREE_X : int = 14
const OUTLINE_COLOR : Color = Color("#3a0409")
const FOCUS_SHADOW_COLOR : Color = Color("#1a0204")
const SHADOW_COLOR : Color = Color("#000000")
const COLOR_BONE : Color = Color("#e9e0cf")
const COLOR_GOLD : Color = Color("#ffd21f")
const COLOR_BRASS : Color = Color("#c9a24a")

const TEX_FG_N : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_slider_fg.tres")
const TEX_FG_F : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_slider_fg_f.tres")
const TEX_BG_N : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_slider_bg.tres")
const TEX_BG_F : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_slider_bg_f.tres")
const TEX_FILL_N : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_dither_red.png")
const TEX_FILL_F : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_dither_red_f.png")
const TEX_KNOB_N : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_slider_knob.tres")
const TEX_KNOB_F : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_slider_knob_f.tres")
const TEX_ROW_F : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_row_f.tres")
const TEX_ROW_F_SUB : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_row_f_sub.tres")

@export_category("Components")
@export var focus_bar : TextureRect
@export var label : Label
@export var knob : TextureRect

@export_category("Value")
##Caption shown left of the track.
@export var label_text : String = "":
	set(v):
		label_text = v
		if is_node_ready() and label:
			label.text = v
##Slider value, 0-10. The inline setter does the real clamp and redraw; use set_value() to also fire sound/emit.
@export_range(0, 10, 1) var value : int = 5:
	set(v):
		value = clampi(v, 0, PIP_COUNT)
		_apply_value_visuals()
		queue_redraw()

@export_category("Layout")
##Swaps the focus bar to its _sub texture. Does not reposition the label; callers indent by placement.
@export var is_sub_row : bool = false:
	set(v):
		is_sub_row = v
		_apply_focus_bar_texture()
		queue_redraw()
##Draws the parent tree line to the left of the row when is_sub_row is true.
@export var tree_line : bool = true
##Shortens the drawn tree line to stop at this row's midline instead of passing through.
@export var is_last_child : bool = false

@export_category("Sound")
@export var sound_tick : AudioStream
@export var sound_error : AudioStream
@export var sound_focus : AudioStream
##Audio bus this slider controls; the slider-move sound plays on it so the change is audible. Set by the owning menu.
var sfx_bus : StringName = &"UI"

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _focused : bool = false
var _dragging : bool = false
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	if label:
		label.text = label_text
	_apply_focus_bar_texture()
	_apply_value_visuals()

##Sets the value and, only when it actually changes, plays sound_tick and emits value_changed. Repeats sound_error at the bounds.
func set_value(v : int, emit : bool = true) -> void:
	if Engine.is_editor_hint():
		return
	var before : int = value
	var clamped : int = clampi(v, 0, PIP_COUNT)
	value = clamped
	if clamped == before:
		_play(sound_error)
		return
	if sound_tick:
		_play(sound_tick)
	else:
		menuSfx.play_slider_move(sfx_bus)
	if emit:
		value_changed.emit(value)
	if debug_me:
		print_rich(debug_name, ": value ", value)

##Left/right steps value by 1. Returns true, consuming the input.
func handle_direction(dir : Vector2i) -> bool:
	if dir == Vector2i.LEFT:
		set_value(value - 1)
		return true
	if dir == Vector2i.RIGHT:
		set_value(value + 1)
		return true
	return false

##Mouse input: real pointer motion focuses; a left press on the track, and a drag that started there, set the value through set_value only when it changes.
func _gui_input(event : InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var mb : InputEventMouseButton = event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		if _dragging:
			_dragging = false
			accept_event()
		return
	if focus_mode == Control.FOCUS_NONE:
		return
	var mm : InputEventMouseMotion = event as InputEventMouseMotion
	if mm:
		if _dragging:
			if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
				accept_event()
				_set_value_from_x(mm.position.x)
			else:
				_dragging = false
			return
		if mm.relative != Vector2.ZERO and not has_focus() and SogardNavInput.mouse_hover_allowed(self):
			grab_focus()
		return
	if not mb or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not SogardNavInput.mouse_allowed(self):
		return
	accept_event()
	if not has_focus():
		grab_focus()
	var x : float = mb.position.x
	if x >= float(TRACK_X) - TRACK_HIT_PAD and x <= float(TRACK_X + TRACK_W) + TRACK_HIT_PAD:
		_dragging = true
		_set_value_from_x(x)

func _set_value_from_x(x : float) -> void:
	var v : int = clampi(roundi((x - float(TRACK_X)) / float(TRACK_W) * float(PIP_COUNT)), 0, PIP_COUNT)
	if v != value:
		set_value(v)

##Swaps the label style, the knob art and the drawn track layers between focused and unfocused looks.
func set_focused_visual(on : bool) -> void:
	_focused = on
	_apply_focus_bar_texture()
	_apply_value_visuals()
	queue_redraw()
	if debug_me_verbose:
		print_rich(debug_name, ": focused ", _focused)

func _on_focus_entered() -> void:
	if Engine.is_editor_hint():
		return
	set_focused_visual(true)
	if sound_focus:
		_play(sound_focus)
	else:
		menuSfx.play_nav()

func _on_focus_exited() -> void:
	_dragging = false
	set_focused_visual(false)

func _apply_focus_bar_texture() -> void:
	if not focus_bar or Engine.is_editor_hint():
		return
	focus_bar.texture = TEX_ROW_F_SUB if is_sub_row else TEX_ROW_F
	focus_bar.visible = _focused

func _apply_value_visuals() -> void:
	if not is_node_ready() or Engine.is_editor_hint():
		return
	if label:
		var c : Color = COLOR_GOLD if _focused else COLOR_BONE
		label.add_theme_color_override("font_color", c)
		label.add_theme_color_override("font_shadow_color", FOCUS_SHADOW_COLOR if _focused else SHADOW_COLOR)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", 1 if _focused else 0)
	if knob:
		knob.texture = TEX_KNOB_F if _focused else TEX_KNOB_N
		if knob.texture:
			var ks : Vector2 = knob.texture.get_size()
			knob.size = ks
			var kx : float = float(TRACK_X) + float(TRACK_W) * float(value) / float(PIP_COUNT)
			knob.position = Vector2(kx - ks.x * 0.5, float(TRACK_Y) + float(TRACK_H) * 0.5 - ks.y * 0.5)

func _draw() -> void:
	if is_sub_row and tree_line:
		var bottom : float = size.y * 0.5 if is_last_child else size.y
		draw_line(Vector2(TREE_X, 0.0), Vector2(TREE_X, bottom), COLOR_BRASS, 1.0)
		draw_line(Vector2(TREE_X, size.y * 0.5), Vector2(TREE_X + 6.0, size.y * 0.5), COLOR_BRASS, 1.0)
	draw_texture(TEX_BG_F if _focused else TEX_BG_N, Vector2(float(BG_X), float(FILL_Y)))
	var fill_w : float = float(TRACK_W) * float(value) / float(PIP_COUNT)
	if fill_w > 0.0:
		draw_texture_rect(TEX_FILL_F if _focused else TEX_FILL_N, Rect2(float(TRACK_X), float(FILL_Y), fill_w, float(FILL_H)), true)
	draw_texture(TEX_FG_F if _focused else TEX_FG_N, Vector2(float(ART_X), float(TRACK_Y)))

func _play(s : AudioStream) -> void:
	if not Engine.is_editor_hint() and s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
