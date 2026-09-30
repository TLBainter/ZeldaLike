##Static glyph platform helper: maps input events and controller names to a platform, resolves the Button Prompts setting, reads keyboard binds from InputMap, applies the Switch confirm/back swap and broadcasts to the sogard_glyph group.
class_name SogardInputGlyphs
extends RefCounted

#region VARIABLES
const XBOX : String = "xbox"
const PS : String = "ps"
const SWITCH : String = "switch"
const KEYBOARD : String = "keyboard"
const GROUP : StringName = &"sogard_glyph"
const PROMPTS_AUTO : int = 0
const PROMPT_PLATFORMS : PackedStringArray = ["", XBOX, PS, SWITCH, KEYBOARD]
const PS_PATTERN : String = "(?i)playstation|dualsense|dualshock"
const SWITCH_PATTERN : String = "(?i)nintendo|pro controller|joy-con"
const PAD_MOTION_THRESHOLD : float = 0.5
const KEY_ACTIONS : Dictionary = {
	"a": &"ui_accept", "b": &"ui_cancel", "x": &"actionButton3", "y": &"actionButton4",
	"lb": &"menuTabLeft", "rb": &"menuTabRight", "start": &"pause",
	"act1": &"actionButton1", "act2": &"actionButton2", "act3": &"actionButton3",
}
const KEY_LABELS : Dictionary = {
	"a": "Enter", "b": "Esc", "x": "J", "y": "I",
	"lb": "Q", "rb": "E", "start": "Esc", "dpad": "Arrows",
}
#endregion VARIABLES

#region FUNCTIONS
##Returns "keyboard" when no joypad is connected, otherwise the family of the first joypad's name.
static func detect_platform() -> String:
	var pads : Array[int] = Input.get_connected_joypads()
	if pads.is_empty():
		return KEYBOARD
	return family_for_name(Input.get_joy_name(pads[0]))

##Returns "ps", "switch" or "xbox" for a controller name; unmatched names count as xbox.
static func family_for_name(joy_name : String) -> String:
	if RegEx.create_from_string(PS_PATTERN).search(joy_name):
		return PS
	if RegEx.create_from_string(SWITCH_PATTERN).search(joy_name):
		return SWITCH
	return XBOX

##Platform implied by a physical input event: key or mouse button press gives keyboard, pad button press or stick motion past 0.5 gives the pad family. Triggers, releases and mouse motion return "".
static func platform_for_event(event : InputEvent) -> String:
	if event is InputEventKey or event is InputEventMouseButton:
		return KEYBOARD if event.is_pressed() else ""
	if event is InputEventJoypadButton:
		return family_for_name(Input.get_joy_name(event.device)) if event.is_pressed() else ""
	var motion : InputEventJoypadMotion = event as InputEventJoypadMotion
	if motion == null:
		return ""
	if motion.axis == JOY_AXIS_TRIGGER_LEFT or motion.axis == JOY_AXIS_TRIGGER_RIGHT:
		return ""
	if absf(motion.axis_value) <= PAD_MOTION_THRESHOLD:
		return ""
	return family_for_name(Input.get_joy_name(motion.device))

##Maps a Button Prompts index (0 Auto, 1 Xbox, 2 PlayStation, 3 Switch, 4 Keyboard) to a platform. Auto and unknown indices return auto_platform, or detect when it is empty.
static func resolve(prompts_index : int, auto_platform : String = "") -> String:
	if prompts_index <= PROMPTS_AUTO or prompts_index >= PROMPT_PLATFORMS.size():
		return detect_platform() if auto_platform.is_empty() else auto_platform
	return PROMPT_PLATFORMS[prompts_index]

##Layout-aware name of the first keyboard bind of action in InputMap (physical keycode when set, else keycode), or "" when the action has no key.
static func key_for_action(action : StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for ev : InputEvent in InputMap.action_get_events(action):
		var key_ev : InputEventKey = ev as InputEventKey
		if key_ev == null:
			continue
		var code : Key = key_ev.keycode
		if key_ev.physical_keycode != KEY_NONE:
			code = key_ev.physical_keycode
			if DisplayServer.get_name() != "headless":
				code = DisplayServer.keyboard_get_keycode_from_physical(key_ev.physical_keycode)
		if code != KEY_NONE:
			return OS.get_keycode_string(code)
	return ""

##Keyboard key-plate text for a glyph key, read from the bound action in InputMap; falls back to KEY_LABELS, and unknown keys return unchanged.
static func key_label(k : String) -> String:
	var lower : String = k.to_lower()
	if KEY_ACTIONS.has(lower):
		var bound : String = key_for_action(KEY_ACTIONS[lower])
		if not bound.is_empty():
			return bound
	return str(KEY_LABELS.get(lower, k))

##Calls set_glyph_platform(platform) on every node in the sogard_glyph group.
static func broadcast(tree : SceneTree, platform : String) -> void:
	if tree:
		tree.call_group(GROUP, "set_glyph_platform", platform)

##Binds ui_accept to the east face button and ui_cancel to the south face button when on is true (Switch layout); restores A/B otherwise. Idempotent.
static func set_confirm_swap(on : bool) -> void:
	_rebind(&"ui_accept", JOY_BUTTON_B if on else JOY_BUTTON_A)
	_rebind(&"ui_cancel", JOY_BUTTON_A if on else JOY_BUTTON_B)

static func _rebind(action : StringName, button : JoyButton) -> void:
	if not InputMap.has_action(action):
		return
	for ev : InputEvent in InputMap.action_get_events(action):
		var jb : InputEventJoypadButton = ev as InputEventJoypadButton
		if jb and (jb.button_index == JOY_BUTTON_A or jb.button_index == JOY_BUTTON_B):
			InputMap.action_erase_event(action, ev)
	var bind : InputEventJoypadButton = InputEventJoypadButton.new()
	bind.button_index = button
	bind.device = -1
	InputMap.action_add_event(action, bind)
#endregion FUNCTIONS
