## Sogard file card, 290x86. Renders one save slot as used, empty or copy ghost and forwards nav, accept and mouse input to FileSelect.
class_name FileSelectPanel
extends Control

#region VARIABLES
signal panel_selected(slot_index: int)
signal direction_requested(dir: Vector2i)

const ROMAN : Array[String] = ["I", "II", "III", "IV", "V", "VI"]

const _SPELL_ORDER : Array[String] = [
	ItemID.SPELL_GRAPPLE,
	ItemID.SPELL_HAMMER,
	ItemID.SPELL_HASTE,
	ItemID.SPELL_SUMMON,
	ItemID.SPELL_IGNITE,
]

const _MOBILITY_ORDER : Array[String] = [
	ItemID.BAT_FORM,
	ItemID.ALBEDO_HOOD,
	ItemID.WAVEWALK_BOOTS,
]

const TEXT_EMPTY : String = "Empty"
const TEXT_COMMENCE : String = "Commence Epic"
const TEXT_OVERWRITES : String = "Overwrites %s"

const COLOR_GOLD := Color(1, 0.823529, 0.121569, 1)
const COLOR_BONE := Color(0.913725, 0.878431, 0.811765, 1)
const COLOR_DIM := Color(0.415686, 0.333333, 0.34902, 1)
const COLOR_FOCUS_SHADOW := Color(0.101961, 0.00784314, 0.0156863, 1)
const COLOR_FOCUS_OUTLINE := Color(0.227451, 0.0156863, 0.0352941, 1)

const CARD_W : int = 290
const CARD_H : int = 86
const ROW_GAP : int = 8
const RIGHT_EDGE : int = 279
const NUM_X : int = 11
const NUM_W : int = 20
const NAME_X : int = 39
const TEXT_NUDGE : int = 2
const ROW1_TOP : int = 8
const ROW1_H : int = 16
const DIFF_TOP : int = 12
const DIFF_H : int = 8
const TAG_TOP : int = 10
const TAG_H : int = 12
const TAG_PAD : int = 3
const LOC_TOP : int = 27
const LOC_H : int = 8
const LOC_W : int = 240
const EMPTY_TOP : int = 35
const ICON_TOP : int = 43
const SKULL_X : int = 11
const SKULL_CELL : int = 12
const SKULL_INSET : int = 1
const SKULL_COLS : int = 10
const MAX_SKULLS : int = 20
const BAR_X : int = 139
const BAR_STEP : int = 14
const MAGIC_TOP : int = 60
const MAX_BARS : int = 5
const ITEM_X : int = 200
const ITEM_STEP : int = 16
const EQUIP_TOP : int = 60
const MISSING_ALPHA : float = 0.6
const GHOST_OPACITY : float = 0.3
const GHOST_GRAY : float = 0.5
const GHOST_BRIGHT : float = 0.8
const COPY_HERE_H : int = 32
const OVER_NOTE_GAP : int = 2
const OVER_NOTE_H : int = 8

@export_category("Card")
## Card plate when unfocused (sogard_ui_card_n).
@export var card_normal : Texture2D
## Card plate when focused (sogard_ui_card_f).
@export var card_focused : Texture2D
## Card plate for the copy source while unfocused (sogard_ui_card_s).
@export var card_source : Texture2D

@export_category("Icons")
## One skull per 4 max health, up to 20 in a 10 column grid.
@export var skull_texture : Texture2D
## One energy icon per 4 max energy, up to 5.
@export var energy_texture : Texture2D
## One magic icon per 6 total shards, up to 5.
@export var magic_texture : Texture2D
## Spell book minis in design order: grapple, hammer, haste, summon, ignite.
@export var book_textures : Array[Texture2D] = []
## Mobility minis in design order: bat, hood, boots.
@export var equip_textures : Array[Texture2D] = []
## Applied with 60% alpha to books and equipment the save does not own.
@export var missing_material : Material

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

@onready var _bg : TextureRect = $Bg
@onready var _fx : Control = $Fx
@onready var _used : CanvasGroup = $Used
@onready var _num_label : Label = $Used/UsedBox/Num
@onready var _name_label : Label = $Used/UsedBox/Name
@onready var _tag : Panel = $Used/UsedBox/Tag
@onready var _tag_label : Label = $Used/UsedBox/Tag/TagLabel
@onready var _diff_label : Label = $Used/UsedBox/Diff
@onready var _time_label : Label = $Used/UsedBox/Time
@onready var _location_label : Label = $Used/UsedBox/Location
@onready var _icons : Control = $Used/UsedBox/Icons
@onready var _empty : Control = $Empty
@onready var _empty_num : Label = $Empty/EmptyNum
@onready var _empty_label : Label = $Empty/EmptyLabel
@onready var _ghost : Control = $Ghost
@onready var _copy_here : Label = $Ghost/CopyHere
@onready var _over_note : Label = $Ghost/OverNote
@onready var _flick_player : AnimationPlayer = $FlickPlayer
@onready var _pulse_player : AnimationPlayer = $PulsePlayer
@onready var _ember1_player : AnimationPlayer = $Ember1Player
@onready var _ember2_player : AnimationPlayer = $Ember2Player
@onready var _ember3_player : AnimationPlayer = $Ember3Player

var slot_index : int = -1

var _data : Dictionary = {}
var _selectable : bool = true
var _src_data : Dictionary = {}
var _is_source : bool = false
var _used_mat : ShaderMaterial = null
var _glow_on : bool = false
var _pulse_on : bool = false
var _skulls : Array[TextureRect] = []
var _energy : Array[TextureRect] = []
var _magic : Array[TextureRect] = []
var _books : Array[TextureRect] = []
var _equip : Array[TextureRect] = []
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	if _used.material is ShaderMaterial:
		_used_mat = (_used.material as ShaderMaterial).duplicate() as ShaderMaterial
		_used.material = _used_mat
	_copy_here.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_icons()
	focus_entered.connect(refresh)
	focus_exited.connect(refresh)
	if not focus_entered.is_connected(menuSfx.play_nav):
		focus_entered.connect(menuSfx.play_nav)
	refresh()

## Binds the slot index, its save dictionary and whether an empty slot may be picked, then redraws. Empty save_data draws the empty card.
func setup(slot: int, save_data: Dictionary, selectable: bool) -> void:
	slot_index = slot
	_data = save_data
	_selectable = selectable
	refresh()
	if debug_me_verbose:
		print_rich(debug_name, ": slot ", slot, " used=", not save_data.is_empty(), " selectable=", selectable)

## Sets copy mode on this card. Empty src_data leaves copy mode; is_source marks the file being copied.
func set_copy_state(src_data: Dictionary, is_source: bool) -> void:
	_src_data = src_data
	_is_source = is_source and not src_data.is_empty()
	refresh()

## Returns true when this slot holds a save.
func is_used() -> bool:
	return not _data.is_empty()

## Returns the stored character name, or an empty string for an empty slot.
func get_display_name() -> String:
	if _data.is_empty():
		return ""
	return str(_data.get("metadata", {}).get("character_name", "?"))

## Returns the stored play time as H:MM:SS, or an empty string for an empty slot.
func get_time_text() -> String:
	if _data.is_empty():
		return ""
	return _format_time(float(_data.get("metadata", {}).get("play_time", 0.0)))

## Returns the roman numeral for a zero based slot index.
static func roman(i: int) -> String:
	return ROMAN[i] if i >= 0 and i < ROMAN.size() else str(i + 1)

## Called by SogardNavInput. Hands the direction to FileSelect, which owns grid navigation.
func handle_direction(dir: Vector2i) -> bool:
	direction_requested.emit(dir)
	return true

## Called by SogardNavInput on accept press. Emits panel_selected for this slot.
func handle_accept() -> bool:
	panel_selected.emit(slot_index)
	return true

## Mouse input: only real pointer motion focuses the card, so a resting cursor never undoes keyboard moves; a left press focuses it and routes through handle_accept.
func _gui_input(event: InputEvent) -> void:
	if focus_mode == Control.FOCUS_NONE:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		if mm.relative != Vector2.ZERO and not has_focus() and SogardNavInput.mouse_hover_allowed(self):
			grab_focus()
		return
	var mb := event as InputEventMouseButton
	if not mb or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not SogardNavInput.mouse_allowed(self):
		return
	accept_event()
	if not has_focus():
		grab_focus()
	if debug_me_verbose:
		print_rich(debug_name, ": mouse press on slot ", slot_index)
	handle_accept()

## Redraws the card from focus, slot data and copy state, following the prototype slotCards rules.
func refresh() -> void:
	if not is_node_ready():
		return
	var f : bool = has_focus()
	var copying : bool = not _src_data.is_empty()
	var ghost : bool = copying and f and not _is_source
	var data : Dictionary = _src_data if ghost else _data
	_bg.texture = card_focused if f else (card_source if _is_source else card_normal)
	_set_glow(f and not ghost)
	_set_pulse(ghost)
	_ghost.visible = ghost
	_used.visible = not data.is_empty()
	_empty.visible = data.is_empty()
	if data.is_empty():
		_draw_empty(f)
	else:
		_draw_used(data, f and not ghost)
	_apply_ghost_material(ghost)
	if ghost:
		_draw_ghost()

func _draw_used(data: Dictionary, lit: bool) -> void:
	var meta : Dictionary = data.get("metadata", {})
	var inv  : Dictionary = meta.get("inventory", {})
	_num_label.text = roman(slot_index)
	_name_label.text = str(meta.get("character_name", "?"))
	_time_label.text = _format_time(float(meta.get("play_time", 0.0)))
	_diff_label.text = str(meta.get("difficulty", ""))
	_location_label.text = str(meta.get("location_name", "?"))
	_tag.visible = _is_source
	_style_text(_name_label, COLOR_GOLD if lit else COLOR_BONE, lit)
	_layout_row1()
	_fit(_location_label, NAME_X, LOC_TOP, LOC_H, 0, LOC_W)
	_fill_icons(meta, inv)

## Lays out row 1 right to left: time, difficulty, COPYING tag, then the name fills what is left after the numeral.
func _layout_row1() -> void:
	var x : int = RIGHT_EDGE
	var time_w : int = _text_w(_time_label)
	x -= time_w
	_fit(_time_label, x, ROW1_TOP, ROW1_H, 0, time_w)
	_diff_label.visible = not _diff_label.text.is_empty()
	if _diff_label.visible:
		var diff_w : int = _text_w(_diff_label)
		x -= ROW_GAP + diff_w
		_fit(_diff_label, x, DIFF_TOP, DIFF_H, 0, diff_w)
	if _tag.visible:
		var label_w : int = _text_w(_tag_label)
		var tag_w : int = label_w + TAG_PAD * 2
		x -= ROW_GAP + tag_w
		_tag.position = Vector2(x, TAG_TOP)
		_tag.size = Vector2(tag_w, TAG_H)
		_fit(_tag_label, TAG_PAD, 0, TAG_H, 0, label_w)
	_fit(_num_label, NUM_X, ROW1_TOP, ROW1_H, TEXT_NUDGE, NUM_W)
	_fit(_name_label, NAME_X, ROW1_TOP, ROW1_H, TEXT_NUDGE, maxi(0, x - ROW_GAP - NAME_X))

func _fill_icons(meta: Dictionary, inv: Dictionary) -> void:
	var skull_count  : int = clampi(floori(float(int(meta.get("max_health", 12))) / 4.0), 0, MAX_SKULLS)
	var energy_count : int = clampi(floori(float(int(meta.get("max_energy", 8))) / 4.0), 0, MAX_BARS)
	var magic_count  : int = clampi(floori(float(int(meta.get("total_shards", 6))) / 6.0), 0, MAX_BARS)
	for i in _skulls.size():
		_skulls[i].visible = i < skull_count
	for i in _energy.size():
		_energy[i].visible = i < energy_count
	for i in _magic.size():
		_magic[i].visible = i < magic_count
	for i in _books.size():
		_set_owned(_books[i], _SPELL_ORDER[i] in inv)
	for i in _equip.size():
		var base_id : String = _MOBILITY_ORDER[i]
		var upg_id  : String = ItemID.MOBILITY_UPGRADES.get(base_id, "")
		var owned   : bool   = base_id in inv or (not upg_id.is_empty() and upg_id in inv)
		_set_owned(_equip[i], owned)

func _draw_empty(f: bool) -> void:
	var lit : bool = f and _selectable
	_empty_num.text = roman(slot_index)
	_empty_label.text = TEXT_COMMENCE if lit else TEXT_EMPTY
	_style_text(_empty_label, COLOR_GOLD if lit else COLOR_DIM, lit)
	_fit(_empty_num, NUM_X, EMPTY_TOP, ROW1_H, TEXT_NUDGE, NUM_W)
	_fit(_empty_label, NAME_X, EMPTY_TOP, ROW1_H, TEXT_NUDGE)

## Centers "Copy Here?" and, when this slot holds a save, the "Overwrites" note under it.
func _draw_ghost() -> void:
	var note : bool = not _data.is_empty()
	_over_note.visible = note
	var total : int = COPY_HERE_H + (OVER_NOTE_GAP + OVER_NOTE_H if note else 0)
	var top : int = floori((CARD_H - total) / 2.0)
	_fit(_copy_here, 0, top, COPY_HERE_H, 0, CARD_W)
	if note:
		_over_note.text = TEXT_OVERWRITES % get_display_name()
		_fit(_over_note, 0, top + COPY_HERE_H + OVER_NOTE_GAP, OVER_NOTE_H, 0, CARD_W)

func _apply_ghost_material(ghost: bool) -> void:
	if _used_mat == null:
		return
	_used_mat.set_shader_parameter(&"opacity", GHOST_OPACITY if ghost else 1.0)
	_used_mat.set_shader_parameter(&"gray", GHOST_GRAY if ghost else 0.0)
	_used_mat.set_shader_parameter(&"bright", GHOST_BRIGHT if ghost else 1.0)

## Shows the glow and embers and restarts their stepped loops; embers 2 and 3 run their delay clip first.
func _set_glow(on: bool) -> void:
	if on == _glow_on:
		return
	_glow_on = on
	for p : AnimationPlayer in [_flick_player, _ember1_player, _ember2_player, _ember3_player]:
		p.clear_queue()
		p.stop()
	_fx.visible = on
	if not on:
		return
	_flick_player.play(&"loop")
	_ember1_player.play(&"loop")
	for p : AnimationPlayer in [_ember2_player, _ember3_player]:
		p.play(&"wait")
		p.queue(&"loop")

func _set_pulse(on: bool) -> void:
	if on == _pulse_on:
		return
	_pulse_on = on
	if on:
		_pulse_player.play(&"loop")
	else:
		_pulse_player.stop()
		_copy_here.modulate.a = 1.0

func _build_icons() -> void:
	for i in MAX_SKULLS:
		var col : int = i % SKULL_COLS
		var row : int = floori(float(i) / SKULL_COLS)
		_skulls.append(_add_icon(skull_texture, Vector2(SKULL_X + col * SKULL_CELL + SKULL_INSET, ICON_TOP + row * SKULL_CELL + SKULL_INSET)))
	for i in MAX_BARS:
		_energy.append(_add_icon(energy_texture, Vector2(BAR_X + i * BAR_STEP, ICON_TOP)))
		_magic.append(_add_icon(magic_texture, Vector2(BAR_X + i * BAR_STEP, MAGIC_TOP)))
	for i in mini(book_textures.size(), _SPELL_ORDER.size()):
		_books.append(_add_icon(book_textures[i], Vector2(ITEM_X + i * ITEM_STEP, ICON_TOP)))
	for i in mini(equip_textures.size(), _MOBILITY_ORDER.size()):
		_equip.append(_add_icon(equip_textures[i], Vector2(ITEM_X + i * ITEM_STEP, EQUIP_TOP)))

func _add_icon(tex: Texture2D, pos: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icons.add_child(r)
	r.position = pos
	if tex:
		r.size = tex.get_size()
	return r

func _set_owned(r: TextureRect, owned: bool) -> void:
	r.material = null if owned else missing_material
	r.modulate.a = 1.0 if owned else MISSING_ALPHA

## Focused text is the given color with a 1,1 #1a0204 shadow and a 1px #3a0409 outline; unfocused uses a 1,1 black shadow and no outline.
func _style_text(lbl: Label, color: Color, focused: bool) -> void:
	lbl.add_theme_color_override(&"font_color", color)
	lbl.add_theme_color_override(&"font_shadow_color", COLOR_FOCUS_SHADOW if focused else Color.BLACK)
	lbl.add_theme_color_override(&"font_outline_color", COLOR_FOCUS_OUTLINE)
	lbl.add_theme_constant_override(&"shadow_offset_x", 1)
	lbl.add_theme_constant_override(&"shadow_offset_y", 1)
	lbl.add_theme_constant_override(&"outline_size", 1 if focused else 0)

## Sizes the label to its line height and centers it vertically in a box of box_h at top, plus nudge. w < 0 keeps the text width.
func _fit(lbl: Label, x: int, top: int, box_h: int, nudge: int, w: int = -1) -> void:
	var ms : Vector2 = lbl.get_combined_minimum_size()
	var h : int = int(ms.y)
	lbl.size = Vector2(w if w >= 0 else ceili(ms.x), h)
	lbl.position = Vector2(x, top + floori((box_h - h) / 2.0) + nudge)

func _text_w(lbl: Label) -> int:
	return ceili(lbl.get_combined_minimum_size().x)

func _format_time(seconds: float) -> String:
	var total : int = int(seconds)
	var h : int = floori(float(total) / 3600.0)
	var m : int = floori(float(total % 3600) / 60.0)
	var s : int = total % 60
	return "%d:%02d:%02d" % [h, m, s]
#endregion FUNCTIONS
