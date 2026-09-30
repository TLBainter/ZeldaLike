##Player settings store (settingsManager autoload). Loads user://settings.cfg on start, applies every key and saves on each change.
extends Node

#region VARIABLES
signal setting_changed(key : StringName)

const CFG_PATH : String = "user://settings.cfg"
const CFG_SECTION : String = "settings"
const MUTE_DB : float = -80.0
const SLIDER_MAX : int = 10
const DEFAULTS : Dictionary = {
	&"prompts": 0, &"text": 1, &"shake": 2, &"particles": 2, &"display": 0, &"scale": 1,
	&"master": 8, &"music": 8, &"bgm": 10, &"boss": 10, &"cut": 9, &"style": 0,
	&"fx": 8, &"pfx": 10, &"efx": 9, &"afx": 7, &"ux": 6,
}
const CHOICE_MAX : Dictionary = {
	&"prompts": 4, &"text": 2, &"shake": 3, &"particles": 3, &"display": 2, &"scale": 1, &"style": 1,
}
const BUSES : Dictionary = {
	&"master": &"Master", &"music": &"Music", &"bgm": &"Songs", &"boss": &"Boss", &"cut": &"Cutscene",
	&"fx": &"Sound Effects", &"pfx": &"Character", &"efx": &"Environment", &"afx": &"Ambience", &"ux": &"UI",
}
const TEXT_SPEED_MULTIPLIERS : Array[float] = [0.5, 1.0, 2.0]
const DISPLAY_MODES : Array[int] = [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
]
const DISPLAY_BORDERLESS : int = 2
const SCALE_PIXEL_PERFECT : int = 1
const GROUP_SHAKE : StringName = &"sogard_shake"
const GROUP_PARTICLES : StringName = &"sogard_particles"
const GROUP_TEXT_SPEED : StringName = &"sogard_text_speed"

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _values : Dictionary = {}
var _glyph_platform : String = SogardInputGlyphs.KEYBOARD
var _last_device : String = SogardInputGlyphs.KEYBOARD
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	_load()
	for key in DEFAULTS:
		_apply(key)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	get_tree().root.window_input.connect(_on_window_input)
	if debug_me:
		print_rich(debug_name, ": [color=cyan]loaded[/color] ", _values)

##Returns the stored value for key (choice index or slider 0-10), or 0 for an unknown key.
func get_value(key : StringName) -> int:
	return int(_values.get(key, 0))

##Returns a copy of every setting as key -> int, in the shape SogardSettings.set_values expects.
func get_all() -> Dictionary:
	return _values.duplicate()

##Clamps and stores v, applies it, saves the file and emits setting_changed. Unknown keys and unchanged values are ignored.
func set_value(key : StringName, v : int) -> void:
	if not DEFAULTS.has(key):
		return
	var clamped : int = _clamp_value(key, v)
	if int(_values.get(key, -1)) == clamped:
		return
	_values[key] = clamped
	_apply(key)
	_save()
	setting_changed.emit(key)
	if debug_me:
		print_rich(debug_name, ": [color=yellow]", key, "[/color] = ", clamped)

##Receiver for SogardSettings.setting_changed(key, value).
func on_settings_changed(key : StringName, value : int) -> void:
	set_value(key, value)

##Dialogue reveal multiplier for the stored Text Speed (Slow 0.5, Normal 1.0, Fast 2.0).
func get_text_speed_multiplier() -> float:
	return TEXT_SPEED_MULTIPLIERS[clampi(get_value(&"text"), 0, TEXT_SPEED_MULTIPLIERS.size() - 1)]

##Resolved glyph platform ("xbox", "ps", "switch" or "keyboard") for glyph nodes that enter the tree after the last broadcast.
func get_glyph_platform() -> String:
	return _glyph_platform

func _clamp_value(key : StringName, v : int) -> int:
	return clampi(v, 0, int(CHOICE_MAX.get(key, SLIDER_MAX)))

func _load() -> void:
	var cfg : ConfigFile = ConfigFile.new()
	var err : Error = cfg.load(CFG_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("settingsManager: could not read %s (%s), using defaults" % [CFG_PATH, error_string(err)])
	for key in DEFAULTS:
		var v : int = int(DEFAULTS[key])
		if err == OK:
			v = int(cfg.get_value(CFG_SECTION, String(key), v))
		_values[key] = _clamp_value(key, v)

func _save() -> void:
	var cfg : ConfigFile = ConfigFile.new()
	for key in _values:
		cfg.set_value(CFG_SECTION, String(key), _values[key])
	var err : Error = cfg.save(CFG_PATH)
	if err != OK:
		push_warning("settingsManager: could not write %s (%s)" % [CFG_PATH, error_string(err)])
	elif debug_me_verbose:
		print_rich(debug_name, ": saved ", CFG_PATH)

func _apply(key : StringName) -> void:
	if BUSES.has(key):
		_apply_volume(key)
	elif key == &"style":
		_apply_music_style()
	elif key == &"prompts":
		_apply_prompts()
	elif key == &"text":
		get_tree().call_group(GROUP_TEXT_SPEED, "set_text_speed_multiplier", get_text_speed_multiplier())
	elif key == &"shake":
		get_tree().call_group(GROUP_SHAKE, "set_shake_level", get_value(key))
	elif key == &"particles":
		get_tree().call_group(GROUP_PARTICLES, "set_particle_level", get_value(key))
	elif key == &"display":
		_apply_display()
	elif key == &"scale":
		_apply_scale()

##Sets the mapped bus to linear_to_db(v / 10), or MUTE_DB at 0. Never touches bus mute flags.
func _apply_volume(key : StringName) -> void:
	var idx : int = AudioServer.get_bus_index(BUSES[key])
	if idx < 0:
		push_warning("settingsManager: missing audio bus " + String(BUSES[key]))
		return
	var v : int = get_value(key)
	var db : float = MUTE_DB if v <= 0 else linear_to_db(float(v) / float(SLIDER_MAX))
	AudioServer.set_bus_volume_db(idx, db)
	if debug_me_verbose:
		print_rich(debug_name, ": bus ", BUSES[key], " = ", db, " dB")

##Applies the music style choice by toggling the RetroBitCrush effect on the Music bus. Retro (0) enables it, Orchestral (1) disables it.
func _apply_music_style() -> void:
	var idx : int = AudioServer.get_bus_index("Music")
	if idx < 0:
		push_warning("settingsManager: missing audio bus Music")
		return
	AudioServer.set_bus_effect_enabled(idx, 0, get_value(&"style") == 0)

##Windowed, Fullscreen (exclusive) or Borderless (fullscreen window with the borderless flag). Skipped on the headless display server.
func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var index : int = get_value(&"display")
	var mode : DisplayServer.WindowMode = DISPLAY_MODES[index] as DisplayServer.WindowMode
	var borderless : bool = index == DISPLAY_BORDERLESS
	if not borderless:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if borderless:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

##Fit uses fractional content scaling; Pixel Perfect uses integer scaling.
func _apply_scale() -> void:
	var pixel_perfect : bool = get_value(&"scale") == SCALE_PIXEL_PERFECT
	get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if pixel_perfect else Window.CONTENT_SCALE_STRETCH_FRACTIONAL

##Resolves the Button Prompts setting (Auto follows the last used device), applies the Switch confirm/back swap and broadcasts the platform to the sogard_glyph group.
func _apply_prompts() -> void:
	_set_platform(SogardInputGlyphs.resolve(get_value(&"prompts"), _last_device), true)

##Stores p as the glyph platform, applies the confirm swap and broadcasts it. Skipped when p is already current unless force is set.
func _set_platform(p : String, force : bool = false) -> void:
	if p == _glyph_platform and not force:
		return
	_glyph_platform = p
	SogardInputGlyphs.set_confirm_swap(p == SogardInputGlyphs.SWITCH)
	SogardInputGlyphs.broadcast(get_tree(), p)
	if debug_me:
		print_rich(debug_name, ": glyph platform ", p)

##Observe-only device tracker on the root window, which sees every event before _input propagation and while paused. Never marks events handled.
func _on_window_input(event : InputEvent) -> void:
	_track_device(SogardInputGlyphs.platform_for_event(event))

##Records the last used device and, under Auto prompts, switches the glyph platform to it.
func _track_device(p : String) -> void:
	if p.is_empty() or p == _last_device:
		return
	_last_device = p
	if debug_me_verbose:
		print_rich(debug_name, ": last device ", p)
	if get_value(&"prompts") == SogardInputGlyphs.PROMPTS_AUTO:
		_set_platform(p)

##Falls back to keyboard when the last joypad disconnects. Connecting a pad never changes the platform; the first pad press does.
func _on_joy_connection_changed(device : int, connected : bool) -> void:
	if debug_me:
		print_rich(debug_name, ": joy ", device, " '", Input.get_joy_name(device), "' connected=", connected)
	if connected or not Input.get_connected_joypads().is_empty():
		return
	_track_device(SogardInputGlyphs.KEYBOARD)
#endregion FUNCTIONS
