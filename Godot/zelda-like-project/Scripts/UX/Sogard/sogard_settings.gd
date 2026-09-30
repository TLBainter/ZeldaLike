##Sogard settings screen: Gameplay, Graphics and Audio rows under a tab row. One scene serves the title (TITLE) and pause (PAUSE) variants.
class_name SogardSettings
extends Control

#region VARIABLES
signal setting_changed(key : StringName, value : int)
signal back_requested()
signal resume_requested()
signal page_requested(delta : int)

enum SettingsVariant { TITLE, PAUSE }

const PANEL_TOP_TITLE : float = 48.0
const PANEL_TOP_PAUSE : float = 40.0
const SUB_LABEL_X : float = 28.0
const SUB_FOCUS_X : float = 20.0
const COLOR_BONE : Color = Color("#e9e0cf")
const COLOR_MUTED : Color = Color("#a08f8c")
const HINTS_TITLE : Array[String] = ["dpad:Adjust", "lb+rb:Category", "b:Back"]
const HINTS_PAUSE : Array[String] = ["dpad:Adjust", "start:Resume"]
const MUTED_VALUE_KEYS : Array[StringName] = [&"prompts", &"text"]
const ROW_NAMES : Dictionary = {
	&"prompts": "Prompts",
	&"text": "TextSpeed",
	&"shake": "ScreenShake",
	&"particles": "Particles",
	&"display": "DisplayMode",
	&"scale": "Scaling",
	&"master": "MasterVolume",
	&"music": "MusicVolume",
	&"bgm": "BackgroundMusic",
	&"boss": "BossMusic",
	&"cut": "CutsceneMusic",
	&"style": "MusicStyle",
	&"fx": "EffectVolume",
	&"pfx": "PlayerFX",
	&"efx": "EnemyFX",
	&"afx": "AmbientFX",
	&"ux": "UXVolume",
}

const SB_PANEL : StyleBox = preload("res://Sprites/UX/Sogard/sogard_sb_panel_set.tres")
const SB_PANEL_P : StyleBox = preload("res://Sprites/UX/Sogard/sogard_sb_panel_set_p.tres")
const TEX_ROW_FP : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_row_fp.tres")
const TEX_ROW_FP_SUB : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_row_fp_sub.tres")

@export_category("Settings")
##TITLE: heading, panel-set frame, panel top 48. PAUSE: no heading, panel-set-p frame, panel top 40, START/Esc resumes and B goes back.
@export var variant : SettingsVariant = SettingsVariant.TITLE:
	set(v):
		variant = v
		_apply_variant()

@export_category("Actions")
##Cycles the focused choice row, as the prototype A press does. Handled here because the nav's accept is disabled in this scene.
@export var action_accept : StringName = &"ui_accept"
##Back action. TITLE routes it through the nav cancel; PAUSE reads it here after action_resume.
@export var action_back : StringName = &"ui_cancel"
##PAUSE only: emits resume_requested. Checked before action_back so Esc resumes and joypad B goes back.
@export var action_resume : StringName = &"pause"
##Previous category (TITLE) or pause page (PAUSE). Bound to the nav only when the action exists in the InputMap.
@export var action_tab_prev : StringName = &"menuTabLeft"
##Next category (TITLE) or pause page (PAUSE). Bound to the nav only when the action exists in the InputMap.
@export var action_tab_next : StringName = &"menuTabRight"

@export_category("Components")
@export var heading : Control
@export var panel : Panel
@export var tabs : SogardTabs
@export var gameplay : Control
@export var graphics : Control
@export var audio : Control
@export var shake : SogardShake
@export var hint_bar : SogardHintBar
@export var nav : SogardNavInput
##Enter animation replayed on every set_active(true), so a re-opened pause settings page steps in again.
@export var screen_in : SogardScreenIn

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _rows : Dictionary = {}
var _containers : Array[Control] = []
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	_containers = [gameplay, graphics, audio]
	for key in ROW_NAMES:
		var row : Control = get_node("%" + String(ROW_NAMES[key]))
		_rows[key] = row
		_setup_row(key, row)
	tabs.tab_changed.connect(_on_tab_changed)
	nav.cancelled.connect(_on_back)
	nav.tab_prev.connect(_on_tab_step.bind(-1))
	nav.tab_next.connect(_on_tab_step.bind(1))
	nav.action_tab_prev = action_tab_prev if _has_action(action_tab_prev) else &""
	nav.action_tab_next = action_tab_next if _has_action(action_tab_next) else &""
	_show_category(tabs.active_index)
	_apply_variant()
	shake.set_shake_level((_rows[&"shake"] as SogardChoiceRow).index)

##Applies stored values by key without emitting setting_changed. Unknown keys are ignored. Call after the scene is in the tree.
func set_values(values : Dictionary) -> void:
	for key in values:
		var k : StringName = StringName(key)
		if not _rows.has(k):
			continue
		var choice : SogardChoiceRow = _rows[k] as SogardChoiceRow
		var slider : SogardSliderRow = _rows[k] as SogardSliderRow
		if choice:
			choice.index = int(values[key])
		elif slider:
			slider.value = int(values[key])
		_restyle_row(k)
	shake.set_shake_level((_rows[&"shake"] as SogardChoiceRow).index)
	if debug_me:
		print_rich(debug_name, ": set_values ", values)

##Returns every setting as key -> int (choice index or slider value 0-10).
func get_values() -> Dictionary:
	var out : Dictionary = {}
	for key in _rows:
		var choice : SogardChoiceRow = _rows[key] as SogardChoiceRow
		var slider : SogardSliderRow = _rows[key] as SogardSliderRow
		if choice:
			out[key] = choice.index
		elif slider:
			out[key] = slider.value
	return out

##Enables or disables this screen's SogardNavInput. Enabling focuses the open category's first row when focus is outside the screen and replays screen_in.
func set_active(on : bool) -> void:
	nav.active = on
	if on and not _owns_focus():
		_focus_first_row()
	if on and screen_in:
		screen_in.play()
	if debug_me:
		print_rich(debug_name, ": active ", on)

func _input(event : InputEvent) -> void:
	if not nav.active or not is_visible_in_tree() or event.is_echo():
		return
	if variant == SettingsVariant.PAUSE and _pressed(event, action_resume):
		_on_resume()
	elif variant == SettingsVariant.PAUSE and _pressed(event, action_back):
		_on_back()
	elif _pressed(event, action_accept):
		_do_accept()
	else:
		return
	get_viewport().set_input_as_handled()

func _setup_row(key : StringName, row : Control) -> void:
	var choice : SogardChoiceRow = row as SogardChoiceRow
	var slider : SogardSliderRow = row as SogardSliderRow
	if choice:
		choice.index_changed.connect(_on_row_changed.bind(key))
		if choice.is_sub_row:
			choice.label.offset_left = SUB_LABEL_X
			choice.focus_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			choice.focus_bar.position = Vector2(SUB_FOCUS_X, 0.0)
			choice.focus_bar.size = TEX_ROW_FP_SUB.get_size()
	elif slider:
		slider.value_changed.connect(_on_row_changed.bind(key))
		slider.sfx_bus = settingsManager.BUSES.get(key, &"UI")
		if slider.is_sub_row:
			slider.label.offset_left = SUB_LABEL_X
			slider.focus_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			slider.focus_bar.position = Vector2(SUB_FOCUS_X, 0.0)
			slider.focus_bar.size = TEX_ROW_FP_SUB.get_size()
	row.focus_entered.connect(_restyle_row.bind(key))
	row.focus_exited.connect(_restyle_row.bind(key))

func _apply_variant() -> void:
	if not is_node_ready():
		return
	var pause : bool = variant == SettingsVariant.PAUSE
	heading.visible = not pause
	panel.position.y = PANEL_TOP_PAUSE if pause else PANEL_TOP_TITLE
	panel.add_theme_stylebox_override(&"panel", SB_PANEL_P if pause else SB_PANEL)
	hint_bar.hint_color = COLOR_BONE if pause else COLOR_MUTED
	hint_bar.set_hints((HINTS_PAUSE if pause else HINTS_TITLE).duplicate())
	nav.action_cancel = &"" if pause else action_back
	for key in _rows:
		var choice : SogardChoiceRow = _rows[key] as SogardChoiceRow
		if choice:
			if choice.is_sub_row:
				choice.focus_texture = TEX_ROW_FP_SUB if pause else SogardSliderRow.TEX_ROW_F_SUB
			else:
				choice.focus_texture = TEX_ROW_FP if pause else SogardChoiceRow.TEX_ROW_F
		_restyle_row(key)
	if debug_me:
		print_rich(debug_name, ": variant ", SettingsVariant.keys()[variant])

func _restyle_row(key : StringName) -> void:
	var row : Control = _rows[key]
	var focused : bool = row.has_focus()
	var choice : SogardChoiceRow = row as SogardChoiceRow
	var slider : SogardSliderRow = row as SogardSliderRow
	if choice and not focused and MUTED_VALUE_KEYS.has(key):
		choice.value_label.add_theme_color_override("font_color", COLOR_MUTED)
	if choice and choice.is_sub_row and not focused:
		choice.label.add_theme_color_override("font_color", COLOR_MUTED)
	if slider:
		if variant == SettingsVariant.PAUSE:
			slider.focus_bar.texture = TEX_ROW_FP_SUB if slider.is_sub_row else TEX_ROW_FP
		else:
			slider.focus_bar.texture = SogardSliderRow.TEX_ROW_F_SUB if slider.is_sub_row else SogardSliderRow.TEX_ROW_F
		if slider.is_sub_row and not focused:
			slider.label.add_theme_color_override("font_color", COLOR_MUTED)

func _on_row_changed(v : int, key : StringName) -> void:
	if key == &"shake":
		shake.set_shake_level(v)
		if v > 0:
			shake.shake()
	if debug_me:
		print_rich(debug_name, ": [color=cyan]", key, "[/color] = ", v)
	setting_changed.emit(key, v)

func _on_tab_changed(i : int) -> void:
	var row_had_focus : bool = _owns_focus() and not tabs.has_focus()
	_show_category(i)
	if row_had_focus:
		_focus_first_row()

func _on_tab_step(delta : int) -> void:
	if variant == SettingsVariant.PAUSE:
		page_requested.emit(delta)
		if debug_me:
			print_rich(debug_name, ": page_requested ", delta)
	elif delta < 0:
		tabs.prev()
	else:
		tabs.next()

func _on_back() -> void:
	if debug_me:
		print_rich(debug_name, ": [color=orange]back[/color]")
	back_requested.emit()

func _on_resume() -> void:
	if debug_me:
		print_rich(debug_name, ": [color=orange]resume[/color]")
	resume_requested.emit()

func _do_accept() -> void:
	if not _owns_focus():
		_focus_first_row()
		return
	var choice : SogardChoiceRow = get_viewport().gui_get_focus_owner() as SogardChoiceRow
	if choice and choice.options.size() > 0:
		choice.set_index((choice.index + 1) % choice.options.size())

func _show_category(i : int) -> void:
	for c in _containers.size():
		_containers[c].visible = c == i
	nav.initial_focus = _first_row(i)
	if debug_me_verbose:
		print_rich(debug_name, ": category ", i)

func _first_row(i : int) -> Control:
	if i < 0 or i >= _containers.size() or _containers[i].get_child_count() == 0:
		return null
	return _containers[i].get_child(0) as Control

func _focus_first_row() -> void:
	var row : Control = _first_row(tabs.active_index)
	if row:
		menuSfx.silence_nav()
		row.grab_focus()

func _owns_focus() -> bool:
	var f : Control = get_viewport().gui_get_focus_owner()
	return f != null and is_ancestor_of(f)

func _pressed(event : InputEvent, action : StringName) -> bool:
	return _has_action(action) and event.is_action_pressed(action)

func _has_action(action : StringName) -> bool:
	return action != &"" and InputMap.has_action(action)
#endregion FUNCTIONS
