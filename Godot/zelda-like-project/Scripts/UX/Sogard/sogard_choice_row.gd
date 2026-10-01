##Gamepad-first Sogard settings row: a labeled left/right choice cycling through options. Keys and pad route through SogardNavInput; pointer motion focuses and a click on an arrow steps the option.
@tool
class_name SogardChoiceRow
extends Control

#region VARIABLES
signal index_changed(index : int)

const VALUE_X : int = 290
const VALUE_W : int = 84
const ARROW_GAP : int = 6
const ARROW_HIT_PAD : float = 4.0
const TREE_X : int = 14
const OUTLINE_COLOR : Color = Color("#3a0409")
const FOCUS_SHADOW_COLOR : Color = Color("#1a0204")
const SHADOW_COLOR : Color = Color("#000000")
const COLOR_BONE : Color = Color("#e9e0cf")
const COLOR_GOLD : Color = Color("#ffd21f")
const COLOR_MUTED : Color = Color("#a08f8c")
const COLOR_BRASS : Color = Color("#c9a24a")

const TEX_ARROW_L : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_arrow_l.tres")
const TEX_ARROW_L_D : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_arrow_l_d.tres")
const TEX_ARROW_R : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_arrow_r.tres")
const TEX_ARROW_R_D : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_arrow_r_d.tres")
const TEX_ROW_F : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_row_f.tres")

@export_category("Components")
@export var focus_bar : TextureRect
@export var label : Label
@export var arrow_l : TextureRect
@export var value_label : Label
@export var arrow_r : TextureRect

@export_category("Value")
##Caption shown left of the value.
@export var label_text : String = "":
	set(v):
		label_text = v
		if is_node_ready() and label:
			label.text = v
##Cycled option strings shown in value_label.
@export var options : PackedStringArray = PackedStringArray():
	set(v):
		options = v
		index = clampi(index, 0, maxi(options.size() - 1, 0))
		_apply_index_visuals()
##Selected option index. The inline setter does the real clamp and redraw; use set_index() to also fire sound/emit.
@export var index : int = 0:
	set(v):
		index = clampi(v, 0, maxi(options.size() - 1, 0))
		_apply_index_visuals()

@export_category("Layout")
##Indent only; focus art comes from focus_texture, set by the caller, independent of this flag.
@export var is_sub_row : bool = false:
	set(v):
		is_sub_row = v
		queue_redraw()
##Draws the parent tree line to the left of the row when is_sub_row is true.
@export var tree_line : bool = true
##Shortens the drawn tree line to stop at this row's midline instead of passing through.
@export var is_last_child : bool = false
##Focus bar art shown while focused. Caller-set; does not auto-swap from is_sub_row.
@export var focus_texture : Texture2D = TEX_ROW_F:
	set(v):
		focus_texture = v
		if not Engine.is_editor_hint() and focus_bar:
			focus_bar.texture = focus_texture

@export_category("Sound")
@export var sound_tick : AudioStream
@export var sound_error : AudioStream
@export var sound_accept : AudioStream
@export var sound_focus : AudioStream

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
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	if label:
		label.text = label_text
	if not Engine.is_editor_hint() and focus_bar:
		focus_bar.texture = focus_texture
		focus_bar.visible = false
	_apply_index_visuals()

##Sets index and, only when it actually changes, plays sound_tick and emits index_changed. Repeats sound_error at the bounds.
func set_index(i : int, emit : bool = true) -> void:
	if Engine.is_editor_hint():
		return
	var before : int = index
	var clamped : int = clampi(i, 0, maxi(options.size() - 1, 0))
	index = clamped
	if clamped == before:
		_play(sound_error)
		return
	_play(sound_tick)
	if emit:
		index_changed.emit(index)
	if debug_me:
		print_rich(debug_name, ": index ", index, " -> ", options[index] if index < options.size() else "")

##Left/right cycles the option index. Returns true, consuming the input.
func handle_direction(dir : Vector2i) -> bool:
	if dir == Vector2i.LEFT:
		set_index(index - 1)
		return true
	if dir == Vector2i.RIGHT:
		set_index(index + 1)
		return true
	return false

##Accept plays the confirm sound without changing the index. Always returns true.
func handle_accept() -> bool:
	if Engine.is_editor_hint():
		return true
	if sound_accept:
		_play(sound_accept)
	else:
		menuSfx.play_confirm()
	if debug_me:
		print_rich(debug_name, ": accepted at index ", index)
	return true

##Mouse input: real pointer motion focuses; a left press on an arrow steps through handle_direction, elsewhere on the row it routes through handle_accept.
func _gui_input(event : InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if focus_mode == Control.FOCUS_NONE:
		return
	var mm : InputEventMouseMotion = event as InputEventMouseMotion
	if mm:
		if mm.relative != Vector2.ZERO and not has_focus() and SogardNavInput.mouse_hover_allowed(self):
			grab_focus()
		return
	var mb : InputEventMouseButton = event as InputEventMouseButton
	if not mb or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not SogardNavInput.mouse_allowed(self):
		return
	accept_event()
	if not has_focus():
		grab_focus()
	var dir : Vector2i = _arrow_dir_at(mb.position.x)
	if dir != Vector2i.ZERO:
		handle_direction(dir)
	else:
		handle_accept()

func _arrow_dir_at(x : float) -> Vector2i:
	if arrow_l and x >= arrow_l.position.x - ARROW_HIT_PAD and x < float(VALUE_X):
		return Vector2i.LEFT
	if arrow_r and x > float(VALUE_X + VALUE_W) and x <= arrow_r.position.x + arrow_r.size.x + ARROW_HIT_PAD:
		return Vector2i.RIGHT
	return Vector2i.ZERO

##Swaps focus bar visibility, label style and arrow tint between focused and unfocused looks.
func set_focused_visual(on : bool) -> void:
	_focused = on
	if focus_bar:
		focus_bar.visible = _focused
	_apply_index_visuals()
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
	set_focused_visual(false)

func _apply_index_visuals() -> void:
	if not is_node_ready():
		return
	if Engine.is_editor_hint():
		if value_label:
			value_label.text = options[index] if index < options.size() else ""
		return
	if label:
		var c : Color = COLOR_GOLD if _focused else COLOR_BONE
		label.add_theme_color_override("font_color", c)
		label.add_theme_color_override("font_shadow_color", FOCUS_SHADOW_COLOR if _focused else SHADOW_COLOR)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", 1 if _focused else 0)
	if value_label:
		value_label.text = options[index] if index < options.size() else ""
		value_label.add_theme_color_override("font_color", COLOR_GOLD if _focused else COLOR_BONE)
	var at_min : bool = index <= 0
	var at_max : bool = index >= options.size() - 1
	if arrow_l:
		arrow_l.texture = TEX_ARROW_L_D if at_min else TEX_ARROW_L
		arrow_l.modulate = Color.WHITE if _focused else COLOR_MUTED
	if arrow_r:
		arrow_r.texture = TEX_ARROW_R_D if at_max else TEX_ARROW_R
		arrow_r.modulate = Color.WHITE if _focused else COLOR_MUTED
	_layout()

func _layout() -> void:
	if not is_node_ready():
		return
	if value_label:
		value_label.position.x = VALUE_X
		value_label.size.x = VALUE_W
	if arrow_l and arrow_l.texture:
		var s : Vector2 = arrow_l.texture.get_size()
		arrow_l.size = s
		arrow_l.position = Vector2(float(VALUE_X - ARROW_GAP) - s.x, (size.y - s.y) * 0.5)
	if arrow_r and arrow_r.texture:
		var s : Vector2 = arrow_r.texture.get_size()
		arrow_r.size = s
		arrow_r.position = Vector2(float(VALUE_X + VALUE_W + ARROW_GAP), (size.y - s.y) * 0.5)

func _draw() -> void:
	if is_sub_row and tree_line:
		var bottom : float = size.y * 0.5 if is_last_child else size.y
		draw_line(Vector2(TREE_X, 0.0), Vector2(TREE_X, bottom), COLOR_BRASS, 1.0)
		draw_line(Vector2(TREE_X, size.y * 0.5), Vector2(TREE_X + 6.0, size.y * 0.5), COLOR_BRASS, 1.0)

func _play(s : AudioStream) -> void:
	if not Engine.is_editor_hint() and s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
