##Keyboard passthrough for name entry. Place as the last child of its screen so it sees input before SogardNavInput. Consumes only accepted characters, Backspace, Tab and pad Y/Start; Enter, Esc and directions pass through.
class_name SogardNameTyping
extends Node

#region VARIABLES
signal typed(ch : String)
signal backspace(is_echo : bool)
signal done_pressed()
signal case_pressed()
signal device_changed(is_pad : bool)

const PAD_AXIS_DEADZONE : float = 0.5

@export_category("Settings")
##Tracks the last input device and emits device_changed. When false the node ignores all input.
@export var active : bool = true
##Consumes typing keys and pad Y/Start. Turn off on screens without name entry and while a modal is open.
@export var typing : bool = false
##Characters accepted from the keyboard, matched against the full character.
@export var allowed_pattern : String = "^[A-Za-z0-9' \\-]$"

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

##True when the most recent input came from a gamepad.
var is_pad : bool = false
var _regex : RegEx = RegEx.new()
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	_regex.compile(allowed_pattern)

func _input(event : InputEvent) -> void:
	if not active or not is_inside_tree():
		return
	_track_device(event)
	if not typing:
		return
	if event is InputEventKey:
		_handle_key(event as InputEventKey)
	elif event is InputEventJoypadButton:
		_handle_pad(event as InputEventJoypadButton)

func _handle_key(k : InputEventKey) -> void:
	if not k.pressed or k.ctrl_pressed or k.alt_pressed or k.meta_pressed:
		return
	if k.keycode == KEY_BACKSPACE:
		_consume()
		backspace.emit(k.echo)
		return
	if k.keycode == KEY_TAB:
		_consume()
		if not k.echo:
			done_pressed.emit()
		return
	if k.unicode <= 0:
		return
	var ch : String = String.chr(k.unicode)
	if _regex.search(ch) == null:
		return
	_consume()
	if debug_me_verbose:
		print_rich(debug_name, ": typed '", ch, "'")
	typed.emit(ch)

func _handle_pad(b : InputEventJoypadButton) -> void:
	if not b.pressed:
		return
	if b.button_index == JOY_BUTTON_Y:
		_consume()
		case_pressed.emit()
	elif b.button_index == JOY_BUTTON_START:
		_consume()
		done_pressed.emit()

func _track_device(event : InputEvent) -> void:
	var pad : bool = is_pad
	if event is InputEventKey:
		pad = false
	elif event is InputEventJoypadButton:
		pad = true
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) >= PAD_AXIS_DEADZONE:
		pad = true
	if pad == is_pad:
		return
	is_pad = pad
	if debug_me:
		print_rich(debug_name, ": device ", "pad" if pad else "keyboard")
	device_changed.emit(pad)

func _consume() -> void:
	get_viewport().set_input_as_handled()
#endregion FUNCTIONS
