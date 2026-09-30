## Centered dialog over a desaturated, darkened backdrop. Builds SogardButton options, traps focus, emits the chosen index.
class_name SogardModal
extends Control

#region VARIABLES
const SCENE_PATH := "res://Scenes/UX/Sogard/sogard_modal.tscn"
const BUTTON_SCENE_PATH := "res://Scenes/UX/Sogard/sogard_button.tscn"
const HOLD_BUTTON_SCENE_PATH := "res://Scenes/UX/Sogard/sogard_hold_button.tscn"
const DANGER_FRAME := preload("res://Sprites/UX/Sogard/sogard_sb_modal300x154_d.tres")
const DANGER_PLATE_N := preload("res://Sprites/UX/Sogard/sogard_sb_mb80_n.tres")
const DANGER_PLATE_F := preload("res://Sprites/UX/Sogard/sogard_sb_mb80_f.tres")
const FRAME_PADDING := Vector4(20, 18, 20, 20)
const BUTTON_HEIGHT := 24
const MODAL_POINTER_GAP := 5
const HOLD_GLYPH_KEY := "a"
const FADE_MS := 140
const FADE_STEPS := 3

@export_category("Frame")
## Frame nine-slice: sogard_sb_modal300x162, modal300x88, modal300x88_p or modal200x208.
@export var frame_style : StyleBox = preload("res://Sprites/UX/Sogard/sogard_sb_modal300x162.tres"):
	set(v):
		frame_style = v
		_apply_frame()
## Danger variant: forces sogard_sb_modal300x154_d and mb80 plates. Corner dots stay gold.
@export var danger : bool = false:
	set(v):
		danger = v
		_apply_frame()
## Backdrop blend toward the dark tint, 0..1. 0.72 matches the prototype scrim rgba(4,1,2,.72).
@export_range(0.0, 1.0) var darken : float = 0.72:
	set(v):
		darken = v
		_apply_backdrop()

@export_category("Buttons")
## Unfocused option plate. Prototype: mb127 for standard dialogs, mb160 for the slot menu, mb80 in danger.
@export var button_plate_n : StyleBox = preload("res://Sprites/UX/Sogard/sogard_sb_mb127_n.tres")
## Focused option plate, paired with button_plate_n.
@export var button_plate_f : StyleBox = preload("res://Sprites/UX/Sogard/sogard_sb_mb127_f.tres")
## Stacks options vertically with dia5 pointers (slot menu on modal200x208).
@export var vertical_buttons : bool = false
## Option index built as a SogardHoldButton (danger Hold to Erase, mb174). -1 for none.
@export var hold_option_index : int = -1

@export_category("Behavior")
## When true, cancel emits dismissed and closes the modal.
@export var cancel_closes : bool = true

@export_category("Sound")
## Played when an option is chosen.
@export var sound_accept : AudioStream
## Played when the modal is dismissed with cancel.
@export var sound_back : AudioStream

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

@onready var backdrop : ColorRect = $Backdrop
@onready var frame : PanelContainer = $Frame
@onready var corner_dots : Control = $CornerDots
@onready var title_label : Label = $Frame/VBox/Title
@onready var body_label : Label = $Frame/VBox/Body
@onready var button_row : BoxContainer = $Frame/VBox/ButtonRow
@onready var nav_input : SogardNavInput = $SogardNavInput

signal option_chosen(index: int)
signal dismissed()
signal closed()

## Backdrop opacity driven by SogardStepper during the open fade.
var backdrop_alpha : float = 0.0:
	set(v):
		backdrop_alpha = v
		_apply_backdrop()

var _buttons : Array[Control] = []
var _previous_focus : Control = null
var _suspended_inputs : Array[SogardNavInput] = []
var _closing : bool = false
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	corner_dots.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.item_rect_changed.connect(_sync_corner_dots)
	nav_input.cancelled.connect(handle_cancel)
	_apply_frame()
	_apply_backdrop()
	_sync_corner_dots()

## Instances the modal scene into the shared SogardOverlay layer and opens it. hold_index builds that option as a hold button.
static func summon(from: Node, title: String, body: String, options: PackedStringArray, default_index: int = 0, is_danger: bool = false, hold_index: int = -1) -> SogardModal:
	var modal := (load(SCENE_PATH) as PackedScene).instantiate() as SogardModal
	modal.danger = is_danger
	modal.hold_option_index = hold_index
	SogardOverlay.host_layer(from).add_child(modal)
	modal.open(title, body, options, default_index)
	return modal

## Fills text, builds option buttons, suspends other nav inputs, fades the backdrop in and focuses default_index.
func open(title: String, body: String, options: PackedStringArray, default_index: int = 0) -> void:
	if not is_node_ready():
		await ready
	menuSfx.play_page_open()
	_previous_focus = get_viewport().gui_get_focus_owner()
	title_label.text = title
	title_label.visible = not title.is_empty()
	body_label.text = body
	body_label.visible = not body.is_empty()
	_build_buttons(options)
	_suspended_inputs = SogardNavInput.suspend_others(nav_input)
	nav_input.scope_root = button_row
	nav_input.active = true
	if not _buttons.is_empty():
		var target := _buttons[clampi(default_index, 0, _buttons.size() - 1)]
		nav_input.initial_focus = target
		target.grab_focus()
	backdrop_alpha = 0.0
	SogardStepper.run(self, self, ^"backdrop_alpha", 0.0, 1.0, FADE_MS, FADE_STEPS)
	if debug_me:
		print_rich(debug_name, ": modal open [b]", title, "[/b] options=", options)

## Restores suspended nav inputs and previous focus, emits closed and frees the modal.
func close() -> void:
	if _closing:
		return
	_closing = true
	menuSfx.play_page_close()
	nav_input.active = false
	SogardNavInput.resume_others(_suspended_inputs)
	_suspended_inputs.clear()
	if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	if debug_me:
		print_rich(debug_name, ": modal closed")
	closed.emit()
	queue_free()

## C5 routing: when cancel_closes, emits dismissed and closes. Returns true when consumed.
func handle_cancel() -> bool:
	if not cancel_closes or _closing:
		return false
	_play(sound_back)
	dismissed.emit()
	close()
	return true

func _build_buttons(options: PackedStringArray) -> void:
	for b in _buttons:
		button_row.remove_child(b)
		b.queue_free()
	_buttons.clear()
	button_row.vertical = vertical_buttons
	var plate_n : StyleBox = DANGER_PLATE_N if danger else button_plate_n
	var plate_f : StyleBox = DANGER_PLATE_F if danger else button_plate_f
	for i in options.size():
		var is_hold := i == hold_option_index
		var scene := load(HOLD_BUTTON_SCENE_PATH if is_hold else BUTTON_SCENE_PATH) as PackedScene
		var b := scene.instantiate() as SogardButton
		b.name = "Option%d" % i
		b.pointer_gap = MODAL_POINTER_GAP
		if is_hold:
			b.glyph_key = HOLD_GLYPH_KEY
		else:
			b.plate_normal = plate_n
			b.plate_focused = plate_f
		if vertical_buttons:
			b.pointer = SogardButton.PointerType.DIA5
		var plate_tex := b.plate_normal as StyleBoxTexture
		if b.custom_minimum_size == Vector2.ZERO and plate_tex and plate_tex.texture:
			b.custom_minimum_size = Vector2(plate_tex.texture.get_width(), BUTTON_HEIGHT)
		b.activated.connect(_on_option_activated.bind(i))
		button_row.add_child(b)
		b.set_text(options[i])
		_buttons.append(b)

func _on_option_activated(index: int) -> void:
	if _closing:
		return
	if sound_accept:
		_play(sound_accept)
	else:
		menuSfx.play_confirm()
	if debug_me:
		print_rich(debug_name, ": option chosen [b]", index, "[/b]")
	option_chosen.emit(index)
	close()

func _apply_frame() -> void:
	if not is_node_ready():
		return
	var src : StyleBox = DANGER_FRAME if danger else frame_style
	if src == null:
		return
	var sb := src.duplicate() as StyleBox
	sb.content_margin_left = FRAME_PADDING.x
	sb.content_margin_top = FRAME_PADDING.y
	sb.content_margin_right = FRAME_PADDING.z
	sb.content_margin_bottom = FRAME_PADDING.w
	frame.add_theme_stylebox_override("panel", sb)
	var src_tex := src as StyleBoxTexture
	if src_tex and src_tex.texture:
		frame.custom_minimum_size = src_tex.texture.get_size()

func _apply_backdrop() -> void:
	if not is_node_ready():
		return
	var mat := backdrop.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("darken", darken)
		mat.set_shader_parameter("alpha", backdrop_alpha)

func _sync_corner_dots() -> void:
	corner_dots.position = frame.position
	corner_dots.size = frame.size

func _play(s: AudioStream) -> void:
	if s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
