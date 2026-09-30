##Difficulty card: diff-n/f plate, stepped glow flicker and ember sparks while focused, name, ornament and description. Lifts 4 px on focus. SogardNavInput routes accept and directions to it; pointer motion focuses and a left click calls handle_accept.
class_name SogardDiffCard
extends Control

#region VARIABLES
signal activated()

const GOLD : Color = Color("#ffd21f")
const BONE : Color = Color("#e9e0cf")
const MUTED : Color = Color("#a08f8c")
const FOCUS_SHADOW : Color = Color("#3a0610")
const REST_SHADOW : Color = Color("#1a0508")
const LIFT_PX : int = 4
const GLOW_ANIM : StringName = &"flick"
const EMBER_ANIM : StringName = &"emb"
const GLOW_LENGTH : float = 1.8
const GLOW_STEPS : int = 5
const GLOW_KEYS : Array = [[0.0, 0.7], [0.18, 1.0], [0.34, 0.65], [0.52, 0.95], [0.70, 0.78], [1.0, 0.9]]
const EMBER_RISE : float = -22.0
const EMBER_PEAK : float = 0.15
## Per ember: [length s, steps, dx px, start offset s]. The start offset stands in for the CSS animation delay.
const EMBER_SPECS : Array = [[1.2, 8, -3.0, 0.0], [1.5, 9, 3.0, 1.0], [1.3, 8, 2.0, 0.4]]

@export_category("Content")
##Difficulty name shown in Script32. Also the saveManager difficulty string.
@export var diff_name : String = "Standard":
	set(v):
		diff_name = v
		if is_node_ready():
			name_label.text = v
##Description in Body16 at 18 px line height. Use explicit line breaks to match the prototype wrap.
@export_multiline var description : String = "":
	set(v):
		description = v
		if is_node_ready():
			desc_label.text = v

@export_category("Plate")
##Unfocused plate texture (sogard_ui_diff_n).
@export var plate_normal : Texture2D
##Focused plate texture (sogard_ui_diff_f).
@export var plate_focused : Texture2D

@export_category("Components")
@export var body : Control
@export var plate : TextureRect
@export var glow : TextureRect
@export var embers : Array[Control] = []
@export var name_label : Label
@export var desc_label : Label

@export_category("Sound")
##Played when the card gains focus.
@export var sound_focus : AudioStream
##Played when the card is activated.
@export var sound_accept : AudioStream

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

##Called as direction_handler.call(self, dir) for left and right; must return true when handled.
var direction_handler : Callable
var _focused : bool = false
var _glow_player : AnimationPlayer
var _ember_players : Array[AnimationPlayer] = []
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(set_focused_visual.bind(false))
	name_label.text = diff_name
	desc_label.text = description
	_build_players()
	set_focused_visual(false)

##Swaps plate, colors, glow, embers and lift between focused and unfocused looks.
func set_focused_visual(on : bool) -> void:
	_focused = on
	plate.texture = plate_focused if on and plate_focused else plate_normal
	body.position.y = -LIFT_PX if on else 0
	name_label.add_theme_color_override("font_color", GOLD if on else BONE)
	name_label.add_theme_color_override("font_shadow_color", FOCUS_SHADOW if on else REST_SHADOW)
	name_label.add_theme_color_override("font_outline_color", FOCUS_SHADOW)
	name_label.add_theme_constant_override("outline_size", 1 if on else 0)
	desc_label.add_theme_color_override("font_color", BONE if on else MUTED)
	glow.visible = on
	for e in embers:
		e.visible = on
	if on:
		_glow_player.play(GLOW_ANIM)
		_glow_player.seek(0.0, true)
		for i in _ember_players.size():
			_ember_players[i].play(EMBER_ANIM)
			_ember_players[i].seek(EMBER_SPECS[i][3], true)
	else:
		_glow_player.stop()
		for p in _ember_players:
			p.stop()
	if debug_me_verbose:
		print_rich(debug_name, ": focused ", on)

func _on_focus_entered() -> void:
	set_focused_visual(true)
	if sound_focus:
		_play(sound_focus)
	else:
		menuSfx.play_nav()

##Accept routed from SogardNavInput. Emits activated.
func handle_accept() -> bool:
	if sound_accept:
		_play(sound_accept)
	else:
		menuSfx.play_confirm_difficulty()
	if debug_me:
		print_rich(debug_name, ": [color=green]activated[/color] ", diff_name)
	activated.emit()
	return true

##Mouse input: real pointer motion focuses the card; a left press focuses it and routes through handle_accept.
func _gui_input(event : InputEvent) -> void:
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
	handle_accept()

##Left and right go to direction_handler; up and down are swallowed so focus stays on the card row.
func handle_direction(dir : Vector2i) -> bool:
	if dir.y != 0:
		return true
	if direction_handler.is_valid():
		return direction_handler.call(self, dir)
	return false

func _build_players() -> void:
	_glow_player = AnimationPlayer.new()
	_glow_player.name = "GlowPlayer"
	add_child(_glow_player)
	var ga : Animation = Animation.new()
	ga.length = GLOW_LENGTH
	ga.loop_mode = Animation.LOOP_LINEAR
	_add_stepped_track(ga, NodePath(String(get_path_to(glow)) + ":modulate:a"), GLOW_KEYS, GLOW_LENGTH, GLOW_STEPS, false)
	_add_library(_glow_player, GLOW_ANIM, ga)
	for i in mini(embers.size(), EMBER_SPECS.size()):
		var e : Control = embers[i]
		var spec : Array = EMBER_SPECS[i]
		var length : float = spec[0]
		var steps : int = spec[1]
		var rest : Vector2 = e.position
		var p : AnimationPlayer = AnimationPlayer.new()
		p.name = "EmberPlayer%d" % (i + 1)
		add_child(p)
		var a : Animation = Animation.new()
		a.length = length
		a.loop_mode = Animation.LOOP_LINEAR
		var path : String = String(get_path_to(e))
		_add_stepped_track(a, NodePath(path + ":position"), [[0.0, rest], [1.0, rest + Vector2(spec[2], EMBER_RISE)]], length, steps, true)
		_add_stepped_track(a, NodePath(path + ":modulate:a"), [[0.0, 0.0], [EMBER_PEAK, 1.0], [1.0, 0.0]], length, steps, false)
		_add_library(p, EMBER_ANIM, a)
		_ember_players.append(p)

func _add_library(p : AnimationPlayer, anim_name : StringName, a : Animation) -> void:
	var lib : AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(anim_name, a)
	p.add_animation_library(&"", lib)

func _add_stepped_track(a : Animation, path : NodePath, keys : Array, length : float, steps : int, snap : bool) -> void:
	var t : int = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, path)
	a.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	for i in keys.size() - 1:
		var t0 : float = keys[i][0] * length
		var t1 : float = keys[i + 1][0] * length
		for k in steps:
			var f : float = float(k) / float(steps)
			var v = lerp(keys[i][1], keys[i + 1][1], f)
			if snap:
				v = v.round()
			a.track_insert_key(t, t0 + (t1 - t0) * f, v)

func _play(s : AudioStream) -> void:
	if s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
