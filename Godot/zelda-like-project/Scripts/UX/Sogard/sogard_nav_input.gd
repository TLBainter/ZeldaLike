##Sole menu input reader for a Sogard screen or modal: directional repeat, focus scoring, and accept/cancel routing to the focused control.
class_name SogardNavInput
extends Node

#region VARIABLES
signal cancelled()
signal tab_prev()
signal tab_next()

const GROUP : StringName = &"sogard_nav_input"

@export_category("Components")
##Root whose focusable descendants are navigation candidates.
@export var scope_root : Control
##Control focused on ready and when focus is outside scope_root.
@export var initial_focus : Control

@export_category("Actions")
@export var action_up : StringName = &"ui_up"
@export var action_down : StringName = &"ui_down"
@export var action_left : StringName = &"ui_left"
@export var action_right : StringName = &"ui_right"
@export var action_accept : StringName = &"ui_accept"
@export var action_cancel : StringName = &"ui_cancel"
##Previous tab action. Empty disables it. Stage 4 maps LB.
@export var action_tab_prev : StringName = &""
##Next tab action. Empty disables it. Stage 4 maps RB.
@export var action_tab_next : StringName = &""

@export_category("Settings")
##Delay before the first repeat of a held direction.
@export var repeat_delay_ms : int = 320
##Interval between repeats after the first.
@export var repeat_rate_ms : int = 110
##Only active instances read input. A modal clears this on the screen beneath it and restores it on close.
@export var active : bool = true:
	set(v):
		active = v
		_clear_held()

@export_category("Sounds")
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

var _held_action : StringName = &""
var _held_dir : Vector2i = Vector2i.ZERO
var _repeat_left_ms : float = 0.0
var _accept_target : Control = null
static var _hover_suppressed : bool = false
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	add_to_group(GROUP)
	if active and initial_focus:
		_grab_initial.call_deferred()

func _grab_initial() -> void:
	if initial_focus == null:
		return
	menuSfx.silence_nav()
	initial_focus.grab_focus()

##Deactivates every other active SogardNavInput in the tree and returns them so the caller can pass them to resume_others.
static func suspend_others(except : SogardNavInput) -> Array[SogardNavInput]:
	var out : Array[SogardNavInput] = []
	for n in except.get_tree().get_nodes_in_group(GROUP):
		if n != except and n is SogardNavInput and n.active:
			n.active = false
			out.append(n)
	return out

##Reactivates the SogardNavInputs returned by suspend_others.
static func resume_others(list : Array[SogardNavInput]) -> void:
	for n in list:
		if is_instance_valid(n):
			n.active = true

##Mouse gate shared by Sogard controls: true when c is visible and the SogardNavInput with the deepest scope containing c is active (or none contains c).
static func mouse_allowed(c : Control) -> bool:
	if not c or not c.is_inside_tree() or not c.is_visible_in_tree():
		return false
	var best_scope : Node = null
	var best_active : bool = true
	for n in c.get_tree().get_nodes_in_group(GROUP):
		var nav : SogardNavInput = n as SogardNavInput
		if not nav:
			continue
		var scope : Node = nav.scope_root if nav.scope_root else nav.get_parent()
		if not scope or not (scope == c or scope.is_ancestor_of(c)):
			continue
		if scope == best_scope:
			best_active = best_active or nav.active
		elif best_scope == null or best_scope.is_ancestor_of(scope):
			best_scope = scope
			best_active = nav.active
	return best_active

##Motion-refocus gate: false while hover is suppressed by keyboard or pad navigation. Suppression clears at query time once no direction action is held, then this defers to mouse_allowed.
static func mouse_hover_allowed(c : Control) -> bool:
	if _hover_suppressed and c and c.is_inside_tree():
		if _direction_held(c.get_tree()):
			return false
		_hover_suppressed = false
	return mouse_allowed(c)

##True while any active SogardNavInput has a direction action currently pressed.
static func _direction_held(tree : SceneTree) -> bool:
	for n in tree.get_nodes_in_group(GROUP):
		var nav : SogardNavInput = n as SogardNavInput
		if not nav or not nav.active:
			continue
		for a in [nav.action_up, nav.action_down, nav.action_left, nav.action_right]:
			if a != &"" and Input.is_action_pressed(a):
				return true
	return false

func _input(event : InputEvent) -> void:
	if not active or not is_inside_tree():
		return
	if event is InputEventMouse:
		return
	if event.is_echo():
		if _is_direction_event(event):
			get_viewport().set_input_as_handled()
		return
	for pair in _direction_pairs():
		var action : StringName = pair[0]
		if action == &"" or not event.is_action(action):
			continue
		if event.is_action_pressed(action):
			_held_action = action
			_held_dir = pair[1]
			_repeat_left_ms = float(repeat_delay_ms)
			_do_direction(_held_dir)
		elif event.is_action_released(action) and action == _held_action:
			_clear_held()
		get_viewport().set_input_as_handled()
		return
	if action_accept != &"" and event.is_action(action_accept):
		if event.is_action_pressed(action_accept):
			if _do_accept():
				get_viewport().set_input_as_handled()
		elif event.is_action_released(action_accept):
			if _do_accept_released():
				get_viewport().set_input_as_handled()
		return
	if action_cancel != &"" and event.is_action_pressed(action_cancel):
		_do_cancel()
		get_viewport().set_input_as_handled()
		return
	if action_tab_prev != &"" and event.is_action_pressed(action_tab_prev):
		tab_prev.emit()
		get_viewport().set_input_as_handled()
		return
	if action_tab_next != &"" and event.is_action_pressed(action_tab_next):
		tab_next.emit()
		get_viewport().set_input_as_handled()

func _process(delta : float) -> void:
	if not active or _held_action == &"":
		return
	if not Input.is_action_pressed(_held_action):
		_clear_held()
		return
	_repeat_left_ms -= delta * 1000.0
	if _repeat_left_ms <= 0.0:
		_repeat_left_ms += float(repeat_rate_ms)
		_do_direction(_held_dir)

func _direction_pairs() -> Array:
	return [[action_up, Vector2i.UP], [action_down, Vector2i.DOWN], [action_left, Vector2i.LEFT], [action_right, Vector2i.RIGHT]]

func _is_direction_event(event : InputEvent) -> bool:
	for pair in _direction_pairs():
		if pair[0] != &"" and event.is_action(pair[0]):
			return true
	return false

func _clear_held() -> void:
	_held_action = &""
	_held_dir = Vector2i.ZERO
	_repeat_left_ms = 0.0

func _focused() -> Control:
	var f : Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if f and scope_root and not (f == scope_root or scope_root.is_ancestor_of(f)):
		return null
	return f

func _ensure_focus() -> Control:
	var f : Control = _focused()
	if f:
		return f
	var target : Control = initial_focus
	if not target or not target.is_visible_in_tree():
		var list : Array[Control] = SogardFocusNav.focusables(scope_root)
		target = list[0] if not list.is_empty() else null
	if target:
		target.grab_focus()
	return null

func _do_direction(dir : Vector2i) -> void:
	_hover_suppressed = true
	var f : Control = _ensure_focus()
	if not f:
		return
	if f.has_method("handle_direction") and f.handle_direction(dir):
		if debug_me_verbose:
			print_rich(debug_name, ": direction ", dir, " consumed by ", f.name)
		return
	var next : Control = SogardFocusNav.pick(f, SogardFocusNav.focusables(scope_root), dir)
	if next:
		next.grab_focus()
		if sound_focus:
			_play(sound_focus)
		else:
			menuSfx.play_nav()
		if debug_me:
			print_rich(debug_name, ": [color=cyan]focus[/color] ", f.name, " -> ", next.name)

func _do_accept() -> bool:
	var f : Control = _focused()
	if not f:
		_ensure_focus()
		return true
	if f.has_method("handle_accept"):
		_accept_target = f
		var used : bool = f.handle_accept()
		if debug_me:
			print_rich(debug_name, ": accept on ", f.name, " consumed=", used)
		return used
	return false

func _do_accept_released() -> bool:
	var t : Control = _accept_target
	_accept_target = null
	if is_instance_valid(t) and t.has_method("handle_accept_released"):
		t.handle_accept_released()
		return true
	return false

func _do_cancel() -> void:
	var f : Control = _focused()
	if f and f.has_method("handle_cancel") and f.handle_cancel():
		return
	if debug_me:
		print_rich(debug_name, ": [color=orange]cancelled[/color]")
	cancelled.emit()

func _play(s : AudioStream) -> void:
	if s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
