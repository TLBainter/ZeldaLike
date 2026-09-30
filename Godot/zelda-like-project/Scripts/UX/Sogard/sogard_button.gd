##Gamepad-first Sogard menu button: nine-slice plate, centered label with optional pad glyph, poking diamond pointers and optional glow while focused. Keys and pad route through SogardNavInput; pointer motion focuses and a left click calls handle_accept.
class_name SogardButton
extends Control

#region VARIABLES
signal activated()

enum PointerType { NONE, DIA3, DIA5, DIA5_RED, DIA7 }
enum PointerSide { LEFT, RIGHT, BOTH }

const POINTER_TEXTURES : Array = [
	null,
	preload("res://Sprites/UX/Sogard/sogard_ui_dia3.tres"),
	preload("res://Sprites/UX/Sogard/sogard_ui_dia5.tres"),
	preload("res://Sprites/UX/Sogard/sogard_ui_dia5_red.tres"),
	preload("res://Sprites/UX/Sogard/sogard_ui_dia7.tres"),
]
const GLYPH_SIZE : Vector2 = Vector2(16, 16)
const GLYPH_GAP : int = 5
const OUTLINE_COLOR : Color = Color("#3a0409")
const FOCUS_SHADOW_COLOR : Color = Color("#1a0204")
const SHADOW_COLOR : Color = Color("#000000")
const POKE_ANIM : StringName = &"poke"
const FLICK_ANIM : StringName = &"flick"

@export_category("Components")
@export var plate : Panel
@export var label : Label
@export var glyph_chip : TextureRect
@export var pointer_left : TextureRect
@export var pointer_right : TextureRect
@export var glow : TextureRect
@export var anim : AnimationPlayer
@export var glow_anim : AnimationPlayer

@export_category("Plate")
##Unfocused plate. Presets: sogard_sb_<btn180|btn220|mb80|mb127|mb160|key22|key77>_n. Its texture size is the minimum size.
@export var plate_normal : StyleBox:
	set(v):
		plate_normal = v
		update_minimum_size()
		_apply_visual()
##Focused plate, the _f partner of plate_normal.
@export var plate_focused : StyleBox:
	set(v):
		plate_focused = v
		_apply_visual()

@export_category("Label")
##Button caption.
@export var text : String = "":
	set(v):
		text = v
		if is_node_ready() and label:
			label.text = v
##Theme type variation for the caption.
@export var label_variation : StringName = &"SogardBody16":
	set(v):
		label_variation = v
		if is_node_ready() and label:
			label.theme_type_variation = v
##Downward caption offset in pixels (Body16 sits +2 px in fixed-height plates).
@export var label_y_offset : int = 2:
	set(v):
		label_y_offset = v
		_layout()
##Unfocused caption color: bone #e9e0cf, or muted #a08f8c where the README asks.
@export var color_normal : Color = Color("#e9e0cf"):
	set(v):
		color_normal = v
		_apply_visual()
##Focused caption color.
@export var color_focused : Color = Color("#ffd21f"):
	set(v):
		color_focused = v
		_apply_visual()
##Disabled caption color.
@export var color_disabled : Color = Color("#6a5559"):
	set(v):
		color_disabled = v
		_apply_visual()
##Focused #3a0409 outline thickness passed to the Label outline_size constant.
@export var focus_outline_size : int = 1:
	set(v):
		focus_outline_size = v
		_apply_visual()

@export_category("Glyph")
##Pad glyph key (a b x y lb rb start dpad) shown left of the caption with a 5 px gap. Empty hides the chip.
@export var glyph_key : String = "":
	set(v):
		glyph_key = v
		_refresh_glyph()
##Controller glyph set: "xbox", "ps" or "switch", or "keyboard" for a text key chip from InputMap. Pulled from settingsManager on entering the tree.
@export var glyph_platform : String = "xbox":
	set(v):
		glyph_platform = v
		_refresh_glyph()

@export_category("Pointer")
##Diamond pointer texture shown while focused.
@export var pointer : PointerType = PointerType.DIA5:
	set(v):
		pointer = v
		_apply_visual()
##Which side(s) show a pointer. Both sides poke inward.
@export var pointer_side : PointerSide = PointerSide.BOTH:
	set(v):
		pointer_side = v
		_apply_visual()
##Pixel gap between the plate edge and the pointer at rest (title 6, modal 5).
@export var pointer_gap : int = 6:
	set(v):
		pointer_gap = v
		_place_pointers()
##Shows sogard_ui_fx_glow_btn centered behind the plate while focused, flickering in discrete steps.
@export var glow_enabled : bool = false:
	set(v):
		glow_enabled = v
		_apply_visual()

@export_category("State")
##Dims the caption, hides pointers and removes the button from focus.
@export var disabled : bool = false:
	set(v):
		disabled = v
		_apply_disabled()

@export_category("Sound")
##Played when this button gains focus.
@export var sound_focus : AudioStream
##Played when the button is activated.
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

var poke_offset : int = 0:
	set(v):
		poke_offset = v
		_place_pointers()
var label_nudge : Vector2 = Vector2.ZERO:
	set(v):
		label_nudge = v
		_layout()
var _focused : bool = false
var _mouse_down : bool = false
var _key_chip : PanelContainer = null
#endregion VARIABLES

#region FUNCTIONS
func _enter_tree() -> void:
	if settingsManager:
		glyph_platform = settingsManager.get_glyph_platform()

func _ready() -> void:
	add_to_group("sogard_glyph")
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	resized.connect(_layout)
	if label:
		label.text = text
		label.theme_type_variation = label_variation
		label.minimum_size_changed.connect(_layout)
	_apply_disabled()
	_refresh_glyph()
	_apply_visual()

func _get_minimum_size() -> Vector2:
	var sb : StyleBoxTexture = plate_normal as StyleBoxTexture
	if sb and sb.texture:
		return sb.texture.get_size()
	return plate_normal.get_minimum_size() if plate_normal else Vector2.ZERO

##Sets the caption.
func set_text(t : String) -> void:
	text = t

##Settings hook: swaps the pad glyph to platform p.
func set_glyph_platform(p : String) -> void:
	glyph_platform = p

##Swaps plate, caption color, pointers with poke loop and glow between focused and unfocused looks.
func set_focused_visual(on : bool) -> void:
	_focused = on and not disabled
	_apply_visual()
	if debug_me_verbose:
		print_rich(debug_name, ": focused ", _focused)

##Accept routed from SogardNavInput. Emits activated and returns true unless disabled.
func handle_accept() -> bool:
	if disabled:
		return false
	if sound_accept:
		_play(sound_accept)
	else:
		menuSfx.play_confirm()
	if debug_me:
		print_rich(debug_name, ": [color=green]activated[/color] ", text)
	activated.emit()
	return true

##Mouse input: real pointer motion focuses, left press routes through handle_accept, and the matching release reaches handle_accept_released when defined.
func _gui_input(event : InputEvent) -> void:
	var mb : InputEventMouseButton = event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		if _mouse_down:
			_mouse_down = false
			accept_event()
			if has_method("handle_accept_released"):
				call("handle_accept_released")
		return
	if disabled or focus_mode == Control.FOCUS_NONE:
		return
	var mm : InputEventMouseMotion = event as InputEventMouseMotion
	if mm:
		if mm.relative != Vector2.ZERO and not has_focus() and SogardNavInput.mouse_hover_allowed(self):
			grab_focus()
		return
	if not mb or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not SogardNavInput.mouse_allowed(self):
		return
	accept_event()
	if not has_focus():
		grab_focus()
	_mouse_down = handle_accept()
	if debug_me_verbose:
		print_rich(debug_name, ": mouse press consumed=", _mouse_down)

func _on_focus_entered() -> void:
	set_focused_visual(true)
	if sound_focus:
		_play(sound_focus)
	else:
		menuSfx.play_nav()

func _on_focus_exited() -> void:
	set_focused_visual(false)

func _apply_disabled() -> void:
	if not is_node_ready():
		return
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	if disabled and has_focus():
		release_focus()
	if disabled:
		_focused = false
	_apply_visual()

func _apply_visual() -> void:
	if not is_node_ready():
		return
	if plate:
		var sb : StyleBox = plate_focused if _focused and plate_focused else plate_normal
		if sb:
			plate.add_theme_stylebox_override("panel", sb)
		else:
			plate.remove_theme_stylebox_override("panel")
	_apply_label_style()
	var tex : Texture2D = POINTER_TEXTURES[clampi(pointer, 0, POINTER_TEXTURES.size() - 1)]
	var show_pointer : bool = _focused and tex != null
	if pointer_left:
		pointer_left.texture = tex
		pointer_left.visible = show_pointer and pointer_side != PointerSide.RIGHT
	if pointer_right:
		pointer_right.texture = tex
		pointer_right.visible = show_pointer and pointer_side != PointerSide.LEFT
	if anim:
		if show_pointer:
			if anim.current_animation != POKE_ANIM:
				anim.play(POKE_ANIM)
		elif anim.is_playing():
			anim.stop()
	if not show_pointer:
		poke_offset = 0
	if glow:
		glow.visible = _focused and glow_enabled
		if glow_anim:
			if glow.visible:
				if glow_anim.current_animation != FLICK_ANIM:
					glow_anim.play(FLICK_ANIM)
			elif glow_anim.is_playing():
				glow_anim.stop()
	_layout()

func _apply_label_style() -> void:
	if not label:
		return
	var c : Color = color_disabled if disabled else (color_focused if _focused else color_normal)
	label.add_theme_color_override("font_color", c)
	label.add_theme_color_override("font_shadow_color", FOCUS_SHADOW_COLOR if _focused else SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", focus_outline_size if _focused else 0)

##Pad glyph texture on controller platforms; on keyboard a text key chip read from InputMap via SogardInputGlyphs.key_label.
func _refresh_glyph() -> void:
	if not is_node_ready() or not glyph_chip:
		return
	var tex : Texture2D = null if glyph_key.is_empty() else SogardGlyphs.get_texture(glyph_platform, glyph_key)
	var key_text : String = ""
	if tex == null and not glyph_key.is_empty() and glyph_platform == SogardInputGlyphs.KEYBOARD:
		key_text = SogardInputGlyphs.key_label(glyph_key)
	_set_key_chip(key_text)
	glyph_chip.texture = tex
	glyph_chip.visible = tex != null or not key_text.is_empty()
	_layout()

##Shows a key chip with text inside glyph_chip, created on first use; empty text hides it.
func _set_key_chip(t : String) -> void:
	if t.is_empty():
		if _key_chip:
			_key_chip.visible = false
		return
	if not _key_chip:
		_key_chip = SogardHintBar.make_key_chip(t)
		_key_chip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glyph_chip.add_child(_key_chip)
		_key_chip.minimum_size_changed.connect(_layout)
	else:
		(_key_chip.get_child(0) as Label).text = t
	_key_chip.visible = true

##Glyph slot size: GLYPH_SIZE, widened to fit a visible key chip.
func _glyph_size() -> Vector2:
	if _key_chip and _key_chip.visible:
		return Vector2(maxf(GLYPH_SIZE.x, _key_chip.get_combined_minimum_size().x), GLYPH_SIZE.y)
	return GLYPH_SIZE

func _layout() -> void:
	if not is_node_ready():
		return
	var label_size : Vector2 = label.get_combined_minimum_size() if label else Vector2.ZERO
	var show_glyph : bool = glyph_chip != null and glyph_chip.visible
	var glyph_size : Vector2 = _glyph_size()
	var total : float = label_size.x
	if show_glyph:
		total += glyph_size.x + (float(GLYPH_GAP) if label_size.x > 0.0 else 0.0)
	var x : float = floorf((size.x - total) * 0.5)
	if show_glyph:
		glyph_chip.size = glyph_size
		glyph_chip.position = Vector2(x, floorf((size.y - glyph_size.y) * 0.5))
		x += glyph_size.x + float(GLYPH_GAP)
	if label:
		label.size = label_size
		label.position = Vector2(x, floorf((size.y - label_size.y) * 0.5) + float(label_y_offset)) + label_nudge
	_place_pointers()
	_place_glow()

func _place_pointers() -> void:
	if not is_node_ready():
		return
	if pointer_left and pointer_left.texture:
		var s : Vector2 = pointer_left.texture.get_size()
		pointer_left.size = s
		pointer_left.position = Vector2(-float(pointer_gap) - s.x + float(poke_offset), floorf((size.y - s.y) * 0.5))
	if pointer_right and pointer_right.texture:
		var s : Vector2 = pointer_right.texture.get_size()
		pointer_right.size = s
		pointer_right.position = Vector2(size.x + float(pointer_gap) - float(poke_offset), floorf((size.y - s.y) * 0.5))

func _place_glow() -> void:
	if not glow or not glow.texture:
		return
	var g : Vector2 = glow.texture.get_size()
	glow.size = g
	glow.position = ((size - g) * 0.5).floor()

func _play(s : AudioStream) -> void:
	if s and audioManager:
		audioManager.play(s, "UI")
#endregion FUNCTIONS
