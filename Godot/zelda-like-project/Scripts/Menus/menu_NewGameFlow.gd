##Sogard new game flow: name entry keyboard, difficulty cards and the confirm modal. Owns its SogardNavInputs and the keyboard typing passthrough. Emits flow_confirmed after the confirm modal closes, or flow_cancelled on back.
class_name NewGameFlow
extends Control

#region VARIABLES
signal flow_confirmed(char_name: String, difficulty: String)
signal flow_cancelled()

const ROMAN : Array[String] = ["I", "II", "III", "IV", "V", "VI"]
const LETTERS : Array[String] = ["ABCDEFGHIJKLM", "NOPQRSTUVWXYZ"]
const ACTION_LABELS : Array[String] = ["Space", "Delete", "Done"]
const MAX_NAME : int = 9
const LETTER_COLS : int = 13
const ACTION_COLS : int = 4
const ROW_Y : Array[int] = [108, 133, 167]
const KEY_X0 : int = 35
const KEY_STEP : int = 24
const ACTION_X0 : int = 30
const ACTION_STEP : int = 81
const CELL_X0 : int = 106
const CELL_STEP : int = 19
const CELL_Y : int = 72
const CELL_SIZE : Vector2 = Vector2(16, 22)
const CELL_LABEL_POS : Vector2 = Vector2(-2, 10)
const CELL_LABEL_SIZE : Vector2 = Vector2(20, 14)
const UNDERLINE_POS : Vector2 = Vector2(1, 21)
const UNDERLINE_SIZE : Vector2 = Vector2(14, 1)
const CURSOR_OFFSET : Vector2 = Vector2(1, 20)
const CURSOR_SIZE : Vector2 = Vector2(14, 2)
const BLINK_ANIM : StringName = &"blink"
const BLINK_LENGTH : float = 1.0
const FOOTER_GAP : int = 6
const CONFIRM_ROW_GAP : int = 5
const CONFIRM_MARGIN_TOP : int = 14
const CONFIRM_MARGIN_BOTTOM : int = 16
const CANVAS_WIDTH : int = 640

const GOLD : Color = Color("#ffd21f")
const BONE : Color = Color("#e9e0cf")
const MUTED : Color = Color("#a08f8c")
const GOLD_SHADOW : Color = Color("#3a0610")
const CELL_SHADOW : Color = Color("#3a0409")
const UNDERLINE : Color = Color("#5a0b14")

const HINTS_NAME_KB : Array[String] = ["Enter:Select", "Bksp:Delete", ":Or type your name"]
const HINTS_NAME_PAD : Array[String] = ["a:Select", "b:Delete", "y:Case", "start:Done"]
const HINTS_DIFF_KB : Array[String] = ["Enter:Select", "Esc:Back"]
const HINTS_DIFF_PAD : Array[String] = ["a:Select", "b:Back"]

@export_category("Plates")
##Plate for the 26 letter keys.
@export var key_plate_normal : StyleBox
@export var key_plate_focused : StyleBox
##Plate for the case, Space, Delete and Done keys.
@export var action_plate_normal : StyleBox
@export var action_plate_focused : StyleBox

@export_category("Name Screen")
@export var name_screen : Control
@export var name_panel : Panel
@export var file_label : Label
##Holds the nine letter cells and the blinking cursor, built at runtime.
@export var cells_root : Control
##Holds the on-screen keyboard keys, built at runtime. Scope of name_nav.
@export var keys_root : Control
@export var name_nav : SogardNavInput
@export var name_screen_in : SogardScreenIn

@export_category("Difficulty Screen")
@export var diff_screen : Control
@export var story_card : SogardDiffCard
@export var standard_card : SogardDiffCard
@export var epic_card : SogardDiffCard
@export var beginning_label : Label
@export var footer_name_label : Label
@export var diff_nav : SogardNavInput
@export var diff_screen_in : SogardScreenIn

@export_category("Shared")
@export var hint_bar : SogardHintBar
@export var shake : SogardShake
##Keyboard and pad passthrough for name typing. Must be the last child so it sees input before the navs.
@export var typing : SogardNameTyping

@export_category("Sounds")
##Played when focus moves between keys or cards.
@export var sound_focus : AudioStream
##Played when a character is typed or the case changes.
@export var sound_type : AudioStream
@export var sound_delete : AudioStream
##Played on a full name or an empty Done.
@export var sound_error : AudioStream
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

var _name : String = ""
var _upper : bool = true
var _difficulty : String = "Standard"
var _diff_index : int = 1
var _slot : int = -1
var _running : bool = false
var _on_name_screen : bool = true
var _pending_confirm : bool = false
var _last_key : SogardGridButton = null
var _suspended : Array[SogardNavInput] = []
var _modal : SogardModal = null
var _keys : Array = []
var _cards : Array[SogardDiffCard] = []
var _cell_labels : Array[Label] = []
var _cursor : ColorRect
var _blink : AnimationPlayer
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	_cards = [story_card, standard_card, epic_card]
	_build_cells()
	_build_keys()
	name_nav.initial_focus = _keys[0][0]
	story_card.activated.connect(_on_difficulty_chosen.bind("Story"))
	standard_card.activated.connect(_on_difficulty_chosen.bind("Standard"))
	epic_card.activated.connect(_on_difficulty_chosen.bind("Epic"))
	for card in _cards:
		card.direction_handler = _on_card_direction
	name_nav.cancelled.connect(_on_name_back)
	diff_nav.cancelled.connect(_back_to_name)
	typing.typed.connect(_on_typed)
	typing.backspace.connect(_on_backspace)
	typing.done_pressed.connect(_done)
	typing.case_pressed.connect(_toggle_case)
	typing.device_changed.connect(_on_device_changed)
	_apply_spacing(file_label)
	_refresh_name()
	_refresh_case()

##Opens the flow on the name screen for save slot index slot (0-based, -1 hides the FILE label). The host shows this node before calling.
func start(slot : int = -1) -> void:
	_name = ""
	_upper = true
	_diff_index = 1
	_difficulty = "Standard"
	_slot = slot
	_pending_confirm = false
	_running = true
	_on_name_screen = true
	file_label.text = ("FILE " + ROMAN[slot]) if slot >= 0 and slot < ROMAN.size() else ""
	name_screen.visible = true
	diff_screen.visible = false
	_suspended.append_array(SogardNavInput.suspend_others(name_nav))
	diff_nav.active = false
	name_nav.active = true
	typing.active = true
	typing.typing = true
	_refresh_name()
	_refresh_case()
	_last_key = _keys[0][0]
	_grab_silent(_last_key)
	name_screen_in.play()
	_refresh_hints()
	_suspend_late.call_deferred()
	if debug_me:
		print_rich(debug_name, ": [color=cyan]start[/color] slot=", slot)

##Second suspend pass one frame later, for navs the host re-enabled after the slot was chosen.
func _suspend_late() -> void:
	if not _running:
		return
	var own : SogardNavInput = name_nav if name_nav.active else diff_nav
	if not own.active:
		return
	for n in SogardNavInput.suspend_others(own):
		if n != name_nav and n != diff_nav and not _suspended.has(n):
			_suspended.append(n)

func _build_cells() -> void:
	for i in MAX_NAME:
		var cell : Control = Control.new()
		cell.name = "Cell%d" % i
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.position = Vector2(CELL_X0 + i * CELL_STEP, CELL_Y)
		cell.size = CELL_SIZE
		cells_root.add_child(cell)
		var line : ColorRect = ColorRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.color = UNDERLINE
		line.position = UNDERLINE_POS
		line.size = UNDERLINE_SIZE
		cell.add_child(line)
		var lbl : Label = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.theme_type_variation = &"SogardBody16"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = CELL_LABEL_POS
		lbl.size = CELL_LABEL_SIZE
		lbl.add_theme_color_override("font_color", GOLD)
		lbl.add_theme_color_override("font_shadow_color", CELL_SHADOW)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		cell.add_child(lbl)
		_cell_labels.append(lbl)
	_cursor = ColorRect.new()
	_cursor.name = "Cursor"
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.color = GOLD
	_cursor.size = CURSOR_SIZE
	cells_root.add_child(_cursor)
	_blink = AnimationPlayer.new()
	_blink.name = "CursorBlink"
	cells_root.add_child(_blink)
	var a : Animation = Animation.new()
	a.length = BLINK_LENGTH
	a.loop_mode = Animation.LOOP_LINEAR
	var t : int = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath("Cursor:modulate:a"))
	a.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	a.track_insert_key(t, 0.0, 1.0)
	a.track_insert_key(t, BLINK_LENGTH * 0.5, 0.0)
	var lib : AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(BLINK_ANIM, a)
	_blink.add_animation_library(&"", lib)

func _build_keys() -> void:
	for r in 3:
		var row : Array = []
		var cols : int = ACTION_COLS if r == 2 else LETTER_COLS
		for c in cols:
			var caption : String
			if r < 2:
				caption = LETTERS[r][c]
			elif c == 0:
				caption = "abc"
			else:
				caption = ACTION_LABELS[c - 1]
			var plate_n : StyleBox = action_plate_normal if r == 2 else key_plate_normal
			var plate_f : StyleBox = action_plate_focused if r == 2 else key_plate_focused
			var b : SogardGridButton = SogardGridButton.build(plate_n, plate_f, caption, Vector2i(c, r))
			if r == 2:
				b.base_position = Vector2(ACTION_X0 + c * ACTION_STEP, ROW_Y[2])
			else:
				b.base_position = Vector2(KEY_X0 + c * KEY_STEP, ROW_Y[r])
			b.sound_focus = sound_focus
			b.direction_handler = _on_key_direction
			b.activated.connect(_on_key_activated.bind(Vector2i(c, r)))
			b.focus_entered.connect(_on_key_focused.bind(b))
			keys_root.add_child(b)
			row.append(b)
		_keys.append(row)

##Grid wrap navigation from the prototype: letter rows wrap across 13 columns, the action row across 4, and vertical moves map columns between the two widths.
func _on_key_direction(cell : Vector2i, dir : Vector2i) -> bool:
	var c : int = cell.x
	var r : int = cell.y
	if dir.x < 0:
		c = (c + ACTION_COLS - 1) % ACTION_COLS if r == 2 else (c + LETTER_COLS - 1) % LETTER_COLS
	elif dir.x > 0:
		c = (c + 1) % ACTION_COLS if r == 2 else (c + 1) % LETTER_COLS
	elif dir.y < 0:
		if r == 2:
			r = 1
			c = _action_to_letter_col(c)
		elif r == 1:
			r = 0
		else:
			r = 2
			c = _letter_to_action_col(c)
	elif dir.y > 0:
		if r == 0:
			r = 1
		elif r == 1:
			r = 2
			c = _letter_to_action_col(c)
		else:
			r = 0
			c = _action_to_letter_col(c)
	(_keys[r][c] as Control).grab_focus()
	return true

func _action_to_letter_col(c : int) -> int:
	return mini(LETTER_COLS - 1, roundi(c * float(LETTER_COLS) / ACTION_COLS + 1.0))

func _letter_to_action_col(c : int) -> int:
	return floori(c * float(ACTION_COLS) / LETTER_COLS)

func _on_key_focused(b : SogardGridButton) -> void:
	_last_key = b

func _on_key_activated(cell : Vector2i) -> void:
	if cell.y < 2:
		var ch : String = LETTERS[cell.y][cell.x]
		_type_char(ch if _upper else ch.to_lower())
		return
	match cell.x:
		0: _toggle_case()
		1: _type_char(" ")
		2: _del_char()
		3: _done()

func _on_typed(ch : String) -> void:
	_type_char(ch)
	_grab_silent(_keys[2][3])

func _on_backspace(is_echo : bool) -> void:
	if not _name.is_empty():
		_del_char()
	elif not is_echo:
		_on_name_back()

func _on_device_changed(_is_pad : bool) -> void:
	if _running:
		_refresh_hints()

##Appends ch unless the name is full. A space switches back to capitals; a capital switches to lowercase.
func _type_char(ch : String) -> void:
	if _name.length() >= MAX_NAME:
		_play(sound_error)
		shake.shake()
		return
	if ch == " ":
		_upper = true
	elif ch >= "A" and ch <= "Z":
		_upper = false
	_name += ch
	_play(sound_type)
	_refresh_name()
	_refresh_case()
	if debug_me_verbose:
		print_rich(debug_name, ": name '", _name, "'")

##Removes the last character. Capitals return when the name is empty or ends with a space.
func _del_char() -> void:
	if _name.is_empty():
		return
	_name = _name.left(-1)
	if _name.is_empty() or _name.ends_with(" "):
		_upper = true
	_play(sound_delete)
	_refresh_name()
	_refresh_case()

func _toggle_case() -> void:
	_upper = not _upper
	_play(sound_type)
	_refresh_case()

func _done() -> void:
	var trimmed : String = _name.strip_edges()
	if trimmed.is_empty():
		_play(sound_error)
		shake.shake()
		return
	_name = trimmed
	_refresh_name()
	_show_diff()

func _refresh_name() -> void:
	for i in _cell_labels.size():
		_cell_labels[i].text = _name[i] if i < _name.length() else ""
	var n : int = _name.length()
	_cursor.visible = n < MAX_NAME
	if _cursor.visible:
		_cursor.position = Vector2(CELL_X0 + n * CELL_STEP, CELL_Y) + CURSOR_OFFSET
		_blink.play(BLINK_ANIM)
		_blink.seek(0.0, true)
	else:
		_blink.stop()
	if not _keys.is_empty():
		(_keys[2][3] as SogardGridButton).dimmed = _name.strip_edges().is_empty()

func _refresh_case() -> void:
	if _keys.is_empty():
		return
	for r in 2:
		for c in LETTER_COLS:
			var ch : String = LETTERS[r][c]
			(_keys[r][c] as SogardButton).set_text(ch if _upper else ch.to_lower())
	(_keys[2][0] as SogardButton).set_text("abc" if _upper else "ABC")

func _refresh_hints() -> void:
	var pad : bool = typing.is_pad
	var pairs : Array[String]
	if _on_name_screen:
		pairs = HINTS_NAME_PAD if pad else HINTS_NAME_KB
	else:
		pairs = HINTS_DIFF_PAD if pad else HINTS_DIFF_KB
	hint_bar.set_hints(pairs.duplicate())

func _show_diff() -> void:
	menuSfx.play_page_open()
	_on_name_screen = false
	name_nav.active = false
	typing.typing = false
	name_screen.visible = false
	diff_screen.visible = true
	footer_name_label.text = _name
	var bw : int = _text_width(beginning_label)
	var nw : int = _text_width(footer_name_label)
	var x : int = floori((CANVAS_WIDTH - (bw + FOOTER_GAP + nw)) / 2.0)
	beginning_label.position.x = x
	beginning_label.size.x = bw
	footer_name_label.position.x = x + bw + FOOTER_GAP
	footer_name_label.size.x = nw
	var card : SogardDiffCard = _cards[_diff_index]
	diff_nav.initial_focus = card
	diff_nav.active = true
	card.grab_focus()
	diff_screen_in.play()
	_refresh_hints()
	if debug_me:
		print_rich(debug_name, ": [color=cyan]difficulty[/color] name='", _name, "'")

func _back_to_name() -> void:
	if _modal:
		return
	_on_name_screen = true
	diff_nav.active = false
	diff_screen.visible = false
	name_screen.visible = true
	name_nav.active = true
	typing.typing = true
	var target : SogardGridButton = _last_key if is_instance_valid(_last_key) else _keys[0][0]
	_grab_silent(target)
	name_screen_in.play()
	_play(sound_back)
	menuSfx.play_page_close()
	_refresh_hints()

##Left and right cycle the three cards with wrap. Up and down are swallowed by the card.
func _on_card_direction(card : SogardDiffCard, dir : Vector2i) -> bool:
	if dir.x == 0:
		return true
	var idx : int = _cards.find(card)
	var next : int = (idx + 1) % _cards.size() if dir.x > 0 else (idx + _cards.size() - 1) % _cards.size()
	_cards[next].grab_focus()
	if sound_focus:
		_play(sound_focus)
	else:
		menuSfx.play_nav()
	return true

##Opens the confirm modal for difficulty. The difficulty string is passed through unchanged to flow_confirmed.
func _on_difficulty_chosen(difficulty : String) -> void:
	if _modal:
		return
	_difficulty = difficulty
	_diff_index = maxi(0, ["Story", "Standard", "Epic"].find(difficulty))
	_pending_confirm = false
	_modal = SogardModal.summon(self, "", "", PackedStringArray(["No", "Yes"]), 1)
	_build_confirm_content(_modal)
	_modal.option_chosen.connect(_on_confirm_option)
	_modal.closed.connect(_on_modal_closed)
	if debug_me:
		print_rich(debug_name, ": confirm ", difficulty)

func _build_confirm_content(m : SogardModal) -> void:
	for b in m.button_row.get_children():
		if b is SogardButton:
			(b as SogardButton).pointer = SogardButton.PointerType.NONE
	var sb : StyleBox = m.frame.get_theme_stylebox("panel").duplicate() as StyleBox
	sb.content_margin_top = CONFIRM_MARGIN_TOP
	sb.content_margin_bottom = CONFIRM_MARGIN_BOTTOM
	m.frame.add_theme_stylebox_override("panel", sb)
	var vbox : Node = m.title_label.get_parent()
	var sub_text : String = ("FILE " + ROMAN[_slot]) if _slot >= 0 and _slot < ROMAN.size() else ""
	var sub : Label = _add_centered(vbox, 0, 8, -1, &"SogardSerif8", sub_text, MUTED)
	_apply_spacing(sub)
	_add_centered(vbox, 1, 16, 1, &"SogardBody16", "Begin as", BONE)
	var big : Label = _add_centered(vbox, 2, 32, 0, &"SogardScript32", _name, GOLD)
	_set_shadow(big, GOLD_SHADOW, Vector2i(0, 2))
	var wrap : Control = _make_wrapper(vbox, 3, 18)
	var row : Control = Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(row)
	var on_lbl : Label = _make_label(row, &"SogardBody16", "on", BONE)
	var diff_lbl : Label = _make_label(row, &"SogardScript16", _difficulty, GOLD)
	_set_shadow(diff_lbl, GOLD_SHADOW, Vector2i(1, 1))
	var tail_lbl : Label = _make_label(row, &"SogardBody16", "difficulty?", BONE)
	var on_w : int = _text_width(on_lbl)
	var d_w : int = _text_width(diff_lbl)
	var tail_w : int = _text_width(tail_lbl)
	var total : int = on_w + CONFIRM_ROW_GAP + d_w + CONFIRM_ROW_GAP + tail_w
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.offset_left = -floori(total / 2.0)
	row.offset_right = row.offset_left + total
	row.offset_bottom = 18
	on_lbl.position = Vector2(0, 3)
	diff_lbl.position = Vector2(on_w + CONFIRM_ROW_GAP, 0)
	tail_lbl.position = Vector2(on_w + CONFIRM_ROW_GAP + d_w + CONFIRM_ROW_GAP, 3)

func _make_wrapper(vbox : Node, index : int, height : int) -> Control:
	var w : Control = Control.new()
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.custom_minimum_size = Vector2(0, height)
	vbox.add_child(w)
	vbox.move_child(w, index)
	return w

func _add_centered(vbox : Node, index : int, height : int, y : int, variation : StringName, text : String, color : Color) -> Label:
	var w : Control = _make_wrapper(vbox, index, height)
	var lbl : Label = _make_label(w, variation, text, color)
	lbl.anchor_right = 1.0
	lbl.offset_top = y
	lbl.offset_bottom = y + height
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _make_label(parent : Node, variation : StringName, text : String, color : Color) -> Label:
	var lbl : Label = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.theme_type_variation = variation
	lbl.add_theme_color_override("font_color", color)
	lbl.text = text
	parent.add_child(lbl)
	return lbl

func _set_shadow(lbl : Label, color : Color, offset : Vector2i) -> void:
	lbl.add_theme_color_override("font_shadow_color", color)
	lbl.add_theme_constant_override("shadow_offset_x", offset.x)
	lbl.add_theme_constant_override("shadow_offset_y", offset.y)

func _on_confirm_option(index : int) -> void:
	_pending_confirm = index == 1
	if _pending_confirm:
		menuSfx.play_confirm_start_game()

##Runs after the modal restored focus. Yes finishes the flow and emits flow_confirmed; No or Back leaves the difficulty screen active.
func _on_modal_closed() -> void:
	_modal = null
	if not _pending_confirm:
		return
	_pending_confirm = false
	_finish(false)
	if debug_me:
		print_rich(debug_name, ": [color=green]confirmed[/color] ", _name, " ", _difficulty)
	flow_confirmed.emit(_name, _difficulty)

func _on_name_back() -> void:
	if not _name.is_empty():
		_del_char()
		return
	_play(sound_back)
	menuSfx.play_page_close()
	_finish(true)
	if debug_me:
		print_rich(debug_name, ": [color=orange]cancelled[/color]")
	flow_cancelled.emit()

##Deactivates the flow input. resume restores the navs suspended by start; confirm skips it because the scene is about to change.
func _finish(resume : bool) -> void:
	_running = false
	name_nav.active = false
	diff_nav.active = false
	typing.typing = false
	typing.active = false
	_blink.stop()
	if resume:
		SogardNavInput.resume_others(_suspended)
	_suspended.clear()

##Grabs focus without the menu nav sound, for focus moves the player did not make.
func _grab_silent(c : Control) -> void:
	menuSfx.silence_nav()
	c.grab_focus()

##Adds 1 px glyph spacing on top of the label's current theme font. The label must be inside the tree.
func _apply_spacing(lbl : Label) -> void:
	var fv : FontVariation = FontVariation.new()
	fv.base_font = lbl.get_theme_font("font")
	fv.spacing_glyph = 1
	lbl.add_theme_font_override("font", fv)

func _text_width(lbl : Label) -> int:
	var f : Font = lbl.get_theme_font("font")
	return ceili(f.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lbl.get_theme_font_size("font_size")).x)

func _play(s : AudioStream) -> void:
	if s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
