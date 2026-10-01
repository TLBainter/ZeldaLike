## Row of Sogard tab plates (tab128 settings categories, tab72 pause pages). Screens drive it with next/prev; a left click on a plate selects it through set_active.
@tool
class_name SogardTabs
extends HBoxContainer

#region VARIABLES
enum TabVariant { TAB128, TAB72 }

const COLOR_ACTIVE := Color("#ffd21f")
const COLOR_MUTED := Color("#a08f8c")
const COLOR_BONE := Color("#e9e0cf")
const COLOR_OUTLINE := Color("#3a0409")
const COLOR_SHADOW_F := Color("#1a0204")
const COLOR_SHADOW := Color("#000000")
const TAB_SIZES := {
	TabVariant.TAB128: Vector2(128, 22),
	TabVariant.TAB72: Vector2(72, 20),
}
const STYLE_N := {
	TabVariant.TAB128: preload("res://Sprites/UX/Sogard/sogard_sb_tab128_n.tres"),
	TabVariant.TAB72: preload("res://Sprites/UX/Sogard/sogard_sb_tab72_n.tres"),
}
const STYLE_A := {
	TabVariant.TAB128: preload("res://Sprites/UX/Sogard/sogard_sb_tab128_a.tres"),
	TabVariant.TAB72: preload("res://Sprites/UX/Sogard/sogard_sb_tab72_a.tres"),
}
const STYLE_AF := {
	TabVariant.TAB128: preload("res://Sprites/UX/Sogard/sogard_sb_tab128_af.tres"),
	TabVariant.TAB72: preload("res://Sprites/UX/Sogard/sogard_sb_tab72_a.tres"),
}

@export_category("Tabs")
## Plate preset: TAB128 for settings categories, TAB72 for pause pages.
@export var variant : TabVariant = TabVariant.TAB128:
	set(v):
		variant = v
		_rebuild()
## Tab captions in display order.
@export var tab_labels : PackedStringArray = PackedStringArray():
	set(v):
		tab_labels = v
		_rebuild()
## Index of the active tab. Use set_active to also emit tab_changed.
@export var active_index : int = 0:
	set(v):
		active_index = v
		_refresh()
## When true next/prev wrap past the first and last tab (prototype wraps with (c+3)%3).
@export var wrap : bool = true
## When true the row is focusable and consumes left/right through handle_direction.
@export var focusable : bool = false:
	set(v):
		focusable = v
		focus_mode = Control.FOCUS_ALL if v else Control.FOCUS_NONE
## Theme variation for tab captions. Prototype tabs use GothicPixelBody 16.
@export var label_variation : StringName = &"SogardBody16"
## Caption Y offset in px; Body16 sits 2px high in fixed-height plates.
@export var label_y_offset : int = 2

@export_category("Sound")
## Played when the active tab changes.
@export var sound_tick : AudioStream

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

signal tab_changed(index: int)

var _tabs : Array[Panel] = []
var _row_focused : bool = false
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_entered.connect(set_focused_visual.bind(true))
	focus_exited.connect(set_focused_visual.bind(false))
	_rebuild()

## Sets the active tab (clamped). Plays sound_tick and emits tab_changed when emit is true and the index changed.
func set_active(i: int, emit: bool = true) -> void:
	var n := tab_labels.size()
	if n == 0:
		return
	var clamped := clampi(i, 0, n - 1)
	if clamped == active_index:
		return
	active_index = clamped
	if debug_me:
		print_rich(debug_name, ": tab -> [b]", clamped, "[/b]")
	if emit:
		if not Engine.is_editor_hint():
			if sound_tick:
				_play(sound_tick)
			else:
				menuSfx.play_page_switch()
		tab_changed.emit(clamped)

## Moves to the next tab, wrapping when wrap is true.
func next() -> void:
	_step(1)

## Moves to the previous tab, wrapping when wrap is true.
func prev() -> void:
	_step(-1)

## C5 routing: consumes left/right while focusable; up/down pass through for focus navigation.
func handle_direction(dir: Vector2i) -> bool:
	if not focusable or dir.x == 0:
		return false
	_step(signi(dir.x))
	return true

## Mouse input: real pointer motion focuses the row when focusable; a left press on a plate selects it through set_active, focusing the row first when focusable.
func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var mm := event as InputEventMouseMotion
	if mm:
		if focus_mode != Control.FOCUS_NONE and mm.relative != Vector2.ZERO and not has_focus() and SogardNavInput.mouse_hover_allowed(self):
			grab_focus()
		return
	var mb := event as InputEventMouseButton
	if not mb or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var i := _tab_at(mb.position)
	if i < 0 or not SogardNavInput.mouse_allowed(self):
		return
	accept_event()
	if focus_mode != Control.FOCUS_NONE and not has_focus():
		grab_focus()
	if debug_me_verbose:
		print_rich(debug_name, ": mouse press on tab ", i)
	set_active(i)

func _tab_at(p: Vector2) -> int:
	for i in _tabs.size():
		if _tabs[i].get_rect().has_point(p):
			return i
	return -1

## Row focus swaps the active tab128 plate to the _af variant.
func set_focused_visual(on: bool) -> void:
	_row_focused = on
	_refresh()

func _step(delta: int) -> void:
	var n := tab_labels.size()
	if n == 0:
		return
	var i := active_index + delta
	if i < 0 or i >= n:
		if not wrap:
			return
		i = posmod(i, n)
	set_active(i)

func _rebuild() -> void:
	if not is_node_ready():
		return
	for t in _tabs:
		remove_child(t)
		t.queue_free()
	_tabs.clear()
	for i in tab_labels.size():
		var panel := Panel.new()
		panel.name = "Tab%d" % i
		panel.custom_minimum_size = TAB_SIZES[variant]
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.focus_mode = Control.FOCUS_NONE
		var label := Label.new()
		label.name = "Label"
		label.theme_type_variation = label_variation
		label.text = tab_labels[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_top = label_y_offset
		label.offset_bottom = label_y_offset
		add_child(panel)
		_tabs.append(panel)
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	for i in _tabs.size():
		var active := i == active_index
		var style : StyleBox = STYLE_N[variant]
		if active:
			style = STYLE_AF[variant] if _row_focused else STYLE_A[variant]
		_tabs[i].add_theme_stylebox_override("panel", style)
		var inactive_color := COLOR_MUTED if variant == TabVariant.TAB128 else COLOR_BONE
		_style_label(_tabs[i].get_node("Label") as Label, COLOR_ACTIVE if active else inactive_color, active)

func _style_label(label: Label, color: Color, lit: bool) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", COLOR_SHADOW_F if lit else COLOR_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", 2 if lit else 0)

func _play(s: AudioStream) -> void:
	if not Engine.is_editor_hint() and s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
