##Sogard file select screen. Owns the 2x3 slot grid navigation, copy mode, the slot, erase and overwrite modals, toasts and the hint bar.
class_name FileSelect
extends Control

#region VARIABLES
signal slot_selected(slot: int)

enum ModalKind { SLOT, ERASE, OVERWRITE }

const TITLE_CHOOSE : String = "Choose a File"
const TITLE_COPY : String = "Copy %s to..."
const TITLE_SIDE : int = 166
const TITLE_LINE_Y : int = 25
const TITLE_DIA_Y : int = 22
const TITLE_LABEL_Y : int = 10
const TITLE_LABEL_H : int = 32
const TITLE_LABEL_PAD : int = 12
const SCREEN_W : int = 640

const SUB_SLOT : String = "FILE %s  \u00b7  %s"
const SUB_OVERWRITE : String = "with a copy of %s"
const HEAD_ERASE : String = "Erase this file?"
const HEAD_OVERWRITE : String = "Overwrite this file?"
const WARN_ERASE : String = "This cannot be undone."
const WARN_OVERWRITE : String = "The existing file will be lost."
const OPTIONS_SLOT : Array[String] = ["Play", "Copy", "Erase", "Back"]
const OPTIONS_ERASE : Array[String] = ["Back", "Hold to Erase"]
const OPTIONS_OVERWRITE : Array[String] = ["Back", "Hold to Overwrite"]
const HOLD_INDEX : int = 1
const ERASE_BACK_FOCUS : int = 2

const TOAST_COPIED : String = "Copied to File %s"
const TOAST_ERASED : String = "%s was erased"

const HINTS_SELECT : Array[String] = ["a:Select", "y:Options", "b:Back"]
const HINTS_HOLD : Array[String] = ["a:Hold", "b:Back"]
const HINTS_MODAL : Array[String] = ["a:Select", "b:Back"]
const HINTS_COPY : Array[String] = ["a:Copy Here", "b:Cancel"]

const COLOR_BONE := Color(0.913725, 0.878431, 0.811765, 1)
const COLOR_GOLD := Color(1, 0.823529, 0.121569, 1)
const COLOR_MUTED := Color(0.627451, 0.560784, 0.54902, 1)
const COLOR_WARN := Color(1, 0.419608, 0.419608, 1)
const COLOR_BIG_SHADOW := Color(0.227451, 0.0235294, 0.0627451, 1)
const COLOR_HOLD_FOCUSED := Color(1, 0.752941, 0.752941, 1)

@export_category("Modal Styles")
##Frame for the Play/Copy/Erase/Back modal (modal200x208).
@export var slot_frame : StyleBox
##Unfocused plate for the slot modal buttons (mb160).
@export var slot_plate_n : StyleBox
##Focused plate for the slot modal buttons (mb160).
@export var slot_plate_f : StyleBox

@export_category("Sounds")
##Played when grid focus moves between cards.
@export var sound_move : AudioStream
##Played when a card opens a modal or starts a slot.
@export var sound_accept : AudioStream
##Played when copy mode is cancelled and passed to the modals.
@export var sound_back : AudioStream
##Played on a denied pick (copy onto the source, empty slot in continue mode).
@export var sound_deny : AudioStream

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

@onready var _backdrop    : ColorRect      = $Backdrop
@onready var _title_label : Label          = $Title/Label
@onready var _line_l      : TextureRect    = $Title/LineL
@onready var _line_r      : TextureRect    = $Title/LineR
@onready var _dia_l       : TextureRect    = $Title/DiaL
@onready var _dia_r       : TextureRect    = $Title/DiaR
@onready var _nav         : SogardNavInput = $SogardNavInput
@onready var _shake       : SogardShake    = $Shake
@onready var _screen_in   : SogardScreenIn = $ScreenIn
@onready var _hint_layer  : CanvasLayer    = $HintLayer
@onready var _hint_bar    : SogardHintBar  = $HintLayer/HintBar
@onready var _cards : Array[FileSelectPanel] = [$Card0, $Card1, $Card2, $Card3, $Card4, $Card5]

var _is_new_game : bool = false
var _copy_from   : int = -1
var _modal       : SogardModal = null
var _pending     : Callable = Callable()
var _last_hints  : Array[String] = []
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	for i in _cards.size():
		_cards[i].panel_selected.connect(_on_slot_act)
		_cards[i].direction_requested.connect(_on_direction.bind(i))
	_nav.cancelled.connect(_cancel_copy)
	visibility_changed.connect(_on_visibility_changed)
	_hint_layer.visible = is_visible_in_tree()
	_update_title()
	_update_hints()

##Refreshes every card, leaves copy mode, focuses the first useful slot and plays the screen-in. is_new_game lets empty slots be picked.
func open(is_new_game: bool) -> void:
	_is_new_game = is_new_game
	_backdrop.visible = is_new_game
	_copy_from = -1
	_refresh_cards()
	for c in _cards:
		c.set_copy_state({}, false)
	var target : int = 0
	for i in _cards.size():
		if _cards[i].is_used() != is_new_game:
			target = i
			break
	_nav.action_cancel = &""
	_nav.initial_focus = _cards[target]
	menuSfx.silence_nav()
	_cards[target].grab_focus()
	_nav.active = true
	_hint_layer.visible = is_visible_in_tree()
	_update_title()
	_update_hints()
	_screen_in.play()
	if debug_me:
		print_rich(debug_name, ": open new_game=", is_new_game, " focus=", target)

func _refresh_cards() -> void:
	for i in _cards.size():
		var has : bool = saveManager.has_save(i)
		var data : Dictionary = saveManager.read_save_data(i) if has else {}
		_cards[i].setup(i, data, _is_new_game or has)

func _on_visibility_changed() -> void:
	_hint_layer.visible = is_visible_in_tree()
	if not visible:
		_nav.active = false

##actionButton4 opens the Play/Copy/Erase/Back modal for the focused used slot in either mode; an empty slot denies.
func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _nav.active:
		return
	if is_instance_valid(_modal) or _copy_from >= 0:
		return
	if not event.is_action_pressed(&"actionButton4"):
		return
	var focus := get_viewport().gui_get_focus_owner()
	var i : int = _cards.find(focus) if focus is FileSelectPanel else -1
	if i >= 0 and _cards[i].is_used():
		_play_accept()
		_open_modal(ModalKind.SLOT, i, 0)
	else:
		_deny()
	get_viewport().set_input_as_handled()

##Grid rule from the prototype: left/right swap columns, up is +4 and down is +2 modulo 6.
func _on_direction(dir: Vector2i, i: int) -> void:
	if is_instance_valid(_modal):
		return
	var n : int = _cards.size()
	var t : int = i
	if dir.y < 0:
		t = (i + 4) % n
	elif dir.y > 0:
		t = (i + 2) % n
	elif dir.x != 0:
		t = i + 1 if i % 2 == 0 else i - 1
	if t == i:
		return
	_cards[t].grab_focus()
	if sound_move:
		_play(sound_move)
	else:
		menuSfx.play_nav()
	if debug_me_verbose:
		print_rich(debug_name, ": focus slot ", t)

##Copy mode targets or denies. New game: a used slot opens the erase modal, an empty slot starts. Load: a used slot loads, an empty slot denies.
func _on_slot_act(i: int) -> void:
	if is_instance_valid(_modal):
		return
	var card := _cards[i]
	if _copy_from >= 0:
		if i == _copy_from:
			_deny()
		elif card.is_used():
			_play_accept()
			_open_modal(ModalKind.OVERWRITE, i, 0)
		else:
			_play_accept()
			_do_copy(i)
		return
	if card.is_used():
		_play_accept()
		if _is_new_game:
			_open_modal(ModalKind.ERASE, i, 0)
		else:
			_emit_slot(i)
	elif _is_new_game:
		_play_accept()
		_emit_slot(i)
	else:
		_deny()

func _emit_slot(i: int) -> void:
	if debug_me:
		print_rich(debug_name, ": [color=cyan]slot selected[/color] ", i)
	slot_selected.emit(i)

func _deny() -> void:
	_play(sound_deny)
	_shake.shake()

func _enter_copy(src: int) -> void:
	_copy_from = src
	var src_data : Dictionary = saveManager.read_save_data(src)
	for j in _cards.size():
		_cards[j].set_copy_state(src_data, j == src)
	var target : int = (src + 1) % _cards.size()
	for j in _cards.size():
		if not _cards[j].is_used():
			target = j
			break
	_nav.action_cancel = &"ui_cancel"
	_cards[target].grab_focus()
	_update_title()
	_update_hints()
	if debug_me:
		print_rich(debug_name, ": [color=cyan]copy mode[/color] from ", src)

func _exit_copy() -> void:
	_copy_from = -1
	for c in _cards:
		c.set_copy_state({}, false)
	_nav.action_cancel = &""
	_update_title()
	_update_hints()

func _cancel_copy() -> void:
	if _copy_from < 0:
		return
	var src : int = _copy_from
	_play(sound_back)
	_exit_copy()
	menuSfx.silence_nav()
	_cards[src].grab_focus()
	if debug_me:
		print_rich(debug_name, ": copy cancelled")

func _do_copy(t: int) -> void:
	var src : int = _copy_from
	var ok : bool = saveManager.copy_save(src, t)
	_exit_copy()
	_refresh_cards()
	_cards[t].grab_focus()
	if not ok:
		_deny()
		if debug_me:
			print_rich(debug_name, ": [color=red]copy failed[/color] ", src, " -> ", t)
		return
	SogardToast.toast(self, TOAST_COPIED % FileSelectPanel.roman(t))
	if debug_me:
		print_rich(debug_name, ": copied ", src, " -> ", t)

func _do_erase(i: int) -> void:
	var erased_name : String = _cards[i].get_display_name()
	saveManager.delete_save(i)
	_refresh_cards()
	_cards[i].grab_focus()
	_shake.shake()
	SogardToast.toast(self, TOAST_ERASED % erased_name)
	if debug_me:
		print_rich(debug_name, ": erased ", i)

##Builds a SogardModal in the overlay layer with the prototype label stack, then routes its choice through _pending once it closes.
func _open_modal(kind: int, slot: int, default_index: int) -> void:
	var m := (load(SogardModal.SCENE_PATH) as PackedScene).instantiate() as SogardModal
	var options : Array[String] = OPTIONS_SLOT
	if kind == ModalKind.SLOT:
		m.frame_style = slot_frame
		m.button_plate_n = slot_plate_n
		m.button_plate_f = slot_plate_f
		m.vertical_buttons = true
	else:
		m.danger = true
		m.hold_option_index = HOLD_INDEX
		options = OPTIONS_ERASE if kind == ModalKind.ERASE else OPTIONS_OVERWRITE
	if sound_accept:
		m.sound_accept = sound_accept
	if sound_back:
		m.sound_back = sound_back
	SogardOverlay.host_layer(self).add_child(m)
	_modal = m
	_add_modal_labels(m, kind, slot)
	m.open("", "", PackedStringArray(options), default_index)
	if kind != ModalKind.SLOT:
		var hold := m.button_row.get_node_or_null(NodePath("Option%d" % HOLD_INDEX)) as SogardButton
		if hold:
			hold.color_focused = COLOR_HOLD_FOCUSED
	_fit_frame(m)
	for b in m.button_row.get_children():
		(b as Control).focus_entered.connect(_update_hints)
	m.option_chosen.connect(_on_modal_option.bind(kind, slot))
	m.dismissed.connect(_on_modal_dismissed.bind(kind, slot))
	m.closed.connect(_on_modal_closed)
	_update_hints()
	if debug_me:
		print_rich(debug_name, ": modal ", ModalKind.keys()[kind], " slot ", slot)

func _add_modal_labels(m: SogardModal, kind: int, slot: int) -> void:
	var vbox := m.frame.get_node(^"VBox") as VBoxContainer
	var spacer := vbox.get_node(^"Spacer")
	var card := _cards[slot]
	var labels : Array[Label] = []
	var sub_text : String = SUB_SLOT % [FileSelectPanel.roman(slot), card.get_time_text()]
	if kind == ModalKind.OVERWRITE:
		sub_text = SUB_OVERWRITE % _cards[_copy_from].get_display_name()
	var sub := _make_label(sub_text, &"SogardSerif8", COLOR_MUTED)
	labels.append(sub)
	if kind != ModalKind.SLOT:
		var head := _make_label(HEAD_ERASE if kind == ModalKind.ERASE else HEAD_OVERWRITE, &"SogardBody16", COLOR_BONE)
		_set_shadow(head, Color.BLACK, Vector2i(1, 1))
		labels.append(head)
	var big := _make_label(card.get_display_name(), &"SogardScript32", COLOR_GOLD)
	_set_shadow(big, COLOR_BIG_SHADOW, Vector2i(0, 2))
	labels.append(big)
	if kind != ModalKind.SLOT:
		labels.append(_make_label(WARN_ERASE if kind == ModalKind.ERASE else WARN_OVERWRITE, &"SogardSerif8", COLOR_WARN))
	for l in labels:
		vbox.add_child(l)
		vbox.move_child(l, spacer.get_index())
	var base : Font = sub.get_theme_font(&"font")
	if base:
		var spaced := FontVariation.new()
		spaced.base_font = base
		spaced.spacing_glyph = 1
		sub.add_theme_font_override(&"font", spaced)

func _make_label(t: String, variation: StringName, color: Color) -> Label:
	var l := Label.new()
	l.theme_type_variation = variation
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override(&"font_color", color)
	return l

func _set_shadow(l: Label, color: Color, offset: Vector2i) -> void:
	l.add_theme_color_override(&"font_shadow_color", color)
	l.add_theme_constant_override(&"shadow_offset_x", offset.x)
	l.add_theme_constant_override(&"shadow_offset_y", offset.y)

##Shrinks the frame's top and bottom content margins when the label stack is taller than the frame art, so the 9-slice never stretches.
func _fit_frame(m: SogardModal) -> void:
	var sb := m.frame.get_theme_stylebox(&"panel") as StyleBoxTexture
	if sb == null or sb.texture == null:
		return
	var need : float = (m.frame.get_node(^"VBox") as Control).get_combined_minimum_size().y
	var room : float = sb.texture.get_height() - sb.content_margin_top - sb.content_margin_bottom
	var over : int = ceili(need - room)
	if over <= 0:
		return
	var half : int = floori(over / 2.0)
	var patched := sb.duplicate() as StyleBoxTexture
	patched.content_margin_top = maxf(0.0, sb.content_margin_top - half)
	patched.content_margin_bottom = maxf(0.0, sb.content_margin_bottom - (over - half))
	m.frame.add_theme_stylebox_override(&"panel", patched)
	if debug_me_verbose:
		print_rich(debug_name, ": modal frame over by ", over, "px, margins ", patched.content_margin_top, "/", patched.content_margin_bottom)

func _on_modal_option(index: int, kind: int, slot: int) -> void:
	_pending = Callable()
	match kind:
		ModalKind.SLOT:
			match index:
				0: _pending = _emit_slot.bind(slot)
				1: _pending = _enter_copy.bind(slot)
				2: _pending = _open_modal.bind(ModalKind.ERASE, slot, 0)
		ModalKind.ERASE:
			if index == HOLD_INDEX:
				_pending = _do_erase.bind(slot)
			elif not _is_new_game:
				_pending = _open_modal.bind(ModalKind.SLOT, slot, ERASE_BACK_FOCUS)
		ModalKind.OVERWRITE:
			if index == HOLD_INDEX:
				_pending = _do_copy.bind(slot)

func _on_modal_dismissed(kind: int, slot: int) -> void:
	_pending = Callable()
	if kind == ModalKind.ERASE and not _is_new_game:
		_pending = _open_modal.bind(ModalKind.SLOT, slot, ERASE_BACK_FOCUS)

func _on_modal_closed() -> void:
	_modal = null
	var next : Callable = _pending
	_pending = Callable()
	_update_hints()
	if next.is_valid():
		next.call()

##Lays out "Choose a File" or "Copy NAME to..." with the flanking lines and diamonds centered on the 640 wide screen.
func _update_title() -> void:
	_title_label.text = TITLE_COPY % _cards[_copy_from].get_display_name() if _copy_from >= 0 else TITLE_CHOOSE
	var font : Font = _title_label.get_theme_font(&"font")
	var fs : int = _title_label.get_theme_font_size(&"font_size")
	var textw : int = ceili(font.get_string_size(_title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) if font else 0
	var x0 : int = floori((SCREEN_W - (textw + TITLE_SIDE)) / 2.0)
	_line_l.position = Vector2(x0, TITLE_LINE_Y)
	_dia_l.position = Vector2(x0 + 67, TITLE_DIA_Y)
	_title_label.position = Vector2(x0 + 77, TITLE_LABEL_Y)
	_title_label.size = Vector2(textw + TITLE_LABEL_PAD, TITLE_LABEL_H)
	_dia_r.position = Vector2(x0 + 92 + textw, TITLE_DIA_Y)
	_line_r.position = Vector2(x0 + 102 + textw, TITLE_LINE_Y)

func _update_hints() -> void:
	var hints : Array[String] = HINTS_SELECT
	if is_instance_valid(_modal):
		var f := get_viewport().gui_get_focus_owner()
		hints = HINTS_HOLD if f is SogardHoldButton else HINTS_MODAL
	elif _copy_from >= 0:
		hints = HINTS_COPY
	if hints == _last_hints:
		return
	_last_hints = hints
	_hint_bar.set_hints(hints)

func _play(s: AudioStream) -> void:
	if s and audioManager:
		audioManager.play(s, "UI")

##Plays sound_accept when set, otherwise the shared menu confirm.
func _play_accept() -> void:
	if sound_accept:
		_play(sound_accept)
	else:
		menuSfx.play_confirm()
#endregion FUNCTIONS
