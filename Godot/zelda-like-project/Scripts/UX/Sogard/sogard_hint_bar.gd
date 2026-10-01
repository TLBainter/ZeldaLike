##Right-aligned row of button glyph + label hints for Sogard screens. Rebuilt from "key:Label" strings and faded in on every change.
@tool
class_name SogardHintBar
extends HBoxContainer

#region VARIABLES
const PAIR_SEPARATION : int = 4
const GLYPH_SEPARATION : int = 3
const GLYPH_SIZE : Vector2 = Vector2(16, 16)

@export_category("Settings")
##Hints as "key:Label" (keys a b x y lb rb start dpad act1 act2 act3). Join keys with + ("lb+rb:Category"). Empty key shows the label alone, empty label the glyphs alone; other keys render as text chips.
@export var hints : Array[String] = []:
	set(v):
		hints = v
		if is_node_ready():
			_rebuild(true)
##Glyph set: "xbox", "ps" or "switch", or "keyboard" for text key plates. Pulled from settingsManager on entering the tree.
@export var glyph_platform : String = "xbox":
	set(v):
		if glyph_platform == v:
			return
		glyph_platform = v
		if is_node_ready():
			_rebuild(false)
##Optional plate drawn behind each pad glyph.
@export var glyph_plate : StyleBox
##Plate for text key chips. Null uses a #3d393e fill with a 1 px #7a7580 border.
@export var key_plate : StyleBox
##Hint label color: muted #a08f8c on front-end screens, bone #e9e0cf on pause-themed screens.
@export var hint_color : Color = Color("#a08f8c"):
	set(v):
		hint_color = v
		if is_node_ready():
			_rebuild(false)
##Fade-in time in milliseconds after each change. 0 disables the fade.
@export var fade_ms : int = 120
##Fade-in step count.
@export var fade_steps : int = 2

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion VARIABLES

#region FUNCTIONS
func _enter_tree() -> void:
	if not Engine.is_editor_hint() and settingsManager:
		glyph_platform = settingsManager.get_glyph_platform()

func _ready() -> void:
	add_to_group("sogard_glyph")
	alignment = BoxContainer.ALIGNMENT_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild(not hints.is_empty())

##Replaces the hints and replays the fade.
func set_hints(pairs : Array[String]) -> void:
	hints = pairs

##Settings hook: swaps every pad glyph to platform p.
func set_glyph_platform(p : String) -> void:
	glyph_platform = p

func _rebuild(fade : bool) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	for spec in hints:
		add_child(_make_pair(spec))
	if fade and fade_ms > 0 and not Engine.is_editor_hint():
		SogardStepper.run(self, self, ^"modulate:a", 0.0, 1.0, fade_ms, fade_steps)
	if debug_me:
		print_rich(debug_name, ": [color=cyan]hints[/color] ", hints)

func _make_pair(spec : String) -> Control:
	var idx : int = spec.find(":")
	var keys : PackedStringArray = spec.substr(0, idx).split("+", false) if idx >= 0 else PackedStringArray()
	var pair : HBoxContainer = HBoxContainer.new()
	pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pair.add_theme_constant_override("separation", PAIR_SEPARATION)
	if not keys.is_empty():
		var glyphs : HBoxContainer = HBoxContainer.new()
		glyphs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyphs.add_theme_constant_override("separation", GLYPH_SEPARATION)
		for k in keys:
			glyphs.add_child(_make_glyph(k.strip_edges()))
		pair.add_child(glyphs)
	var text : String = spec.substr(idx + 1) if idx >= 0 else spec
	if text.is_empty() and not keys.is_empty():
		return pair
	var lbl : Label = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.theme_type_variation = &"SogardSerif8"
	lbl.add_theme_color_override("font_color", hint_color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.text = text
	pair.add_child(lbl)
	return pair

func _make_glyph(k : String) -> Control:
	if not SogardGlyphs.KEYS.has(k.to_lower()):
		return _make_key_chip(k)
	if glyph_platform == SogardInputGlyphs.KEYBOARD:
		return _make_key_chip(k if Engine.is_editor_hint() else SogardInputGlyphs.key_label(k))
	var tex : TextureRect = TextureRect.new()
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.custom_minimum_size = GLYPH_SIZE
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tex.texture = SogardGlyphs.get_texture(glyph_platform, k)
	if not glyph_plate:
		return tex
	var plate : PanelContainer = PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", glyph_plate)
	plate.add_child(tex)
	return plate

func _make_key_chip(k : String) -> Control:
	return make_key_chip(k, key_plate)

##Builds a text key plate showing text; plate null uses default_key_plate(). Shared by hint bars, Sogard buttons and spell slot badges.
static func make_key_chip(text : String, plate_style : StyleBox = null) -> PanelContainer:
	var plate : PanelContainer = PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.custom_minimum_size = GLYPH_SIZE
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.add_theme_stylebox_override("panel", plate_style if plate_style else default_key_plate())
	var lbl : Label = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.theme_type_variation = &"SogardSerif8"
	lbl.add_theme_color_override("font_color", Color("#f2f2f2"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.text = text
	plate.add_child(lbl)
	return plate

##Default key chip plate: #3d393e fill, 1 px #7a7580 border, 3 px side margins.
static func default_key_plate() -> StyleBoxFlat:
	var sb : StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#3d393e")
	sb.border_color = Color("#7a7580")
	sb.set_border_width_all(1)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	sb.anti_aliasing = false
	return sb
#endregion FUNCTIONS
