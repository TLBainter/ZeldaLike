##Replaces the default [b]row[/b] integer editor for [b]CharacterAnimationDirectionEntry[/b].[br]
##Inline: SpinBox (row value) + read-only LineEdit (generated clip name, e.g. "WalkDown").[br]
##Bottom row 1: Embedded compass direction picker (left) + square animated preview that expands with the inspector width (right).[br]
##Bottom row 2: Static strip of every frame in the row (full width).
@tool
class_name RowPreviewProperty
extends EditorProperty

const DISPLAY_SCALE := 2

## Grid layout: each inner array is one row; -1 = disabled center cell.
const GRID_LAYOUT: Array = [[3, 4, 5], [2, -1, 6], [1, 0, 7]]
## Arrow glyphs indexed by Direction enum value.
const DIR_ARROWS: Dictionary = {0: "↓", 1: "↙", 2: "←", 3: "↖", 4: "↑", 5: "↗", 6: "→", 7: "↘"}
## Animation name suffixes indexed by Direction enum value.
const DIR_SUFFIXES: Array = ["Down", "DownLeft", "Left", "UpLeft", "Up", "UpRight", "Right", "DownRight"]

## Single-frame TextureRect that cycles through an AtlasTexture array while hovered.
## Stops when the mouse leaves or the widget becomes invisible (entry collapsed).
class AnimPreviewControl extends TextureRect:
	var frames: Array = []
	var frame_rate: float = 10.0
	var _current_frame: int = 0
	var _elapsed: float = 0.0
	var _playing: bool = false

	func _init() -> void:
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		custom_minimum_size = Vector2(96, 96)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = "Hover to preview animation"
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		visibility_changed.connect(_on_visibility_changed)

	func set_frames(new_frames: Array, rate: float) -> void:
		frames = new_frames
		frame_rate = maxf(rate, 1.0)
		stop()

	func stop() -> void:
		_playing = false
		_current_frame = 0
		_elapsed = 0.0
		texture = frames[0] if not frames.is_empty() else null

	func _process(delta: float) -> void:
		if not _playing or frames.size() < 2:
			return
		_elapsed += delta
		var frame_duration: float = 1.0 / frame_rate
		if _elapsed >= frame_duration:
			_elapsed = fmod(_elapsed, frame_duration)
			_current_frame = (_current_frame + 1) % frames.size()
			texture = frames[_current_frame]

	func _on_mouse_entered() -> void:
		if frames.size() < 2:
			return
		_playing = true
		_current_frame = 0
		_elapsed = 0.0

	func _on_mouse_exited() -> void:
		stop()

	func _on_visibility_changed() -> void:
		if not is_visible_in_tree():
			stop()


## Dimmed vertical caption label rendered via draw_set_transform.
## Used as section headers beside the compass and animated preview.
class _VLabel extends Control:
	var _text: String = ""

	func _init(text: String) -> void:
		_text = text
		mouse_filter = MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func _get_minimum_size() -> Vector2:
		if not is_inside_tree():
			return Vector2(14, 0)
		var font := get_theme_default_font()
		var fsize := get_theme_default_font_size()
		var tw := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		return Vector2(font.get_height(fsize) + 2, tw + 4)

	func _draw() -> void:
		var font := get_theme_default_font()
		var fsize := get_theme_default_font_size()
		var tw := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		var ascent := font.get_ascent(fsize)
		var descent := font.get_descent(fsize)
		# PI/2 rotation: text reads top-to-bottom; ascenders extend right, descenders left.
		var ox := size.x / 2.0 - (ascent - descent) / 2.0
		var oy := size.y / 2.0 - tw / 2.0
		draw_set_transform(Vector2(ox, oy), PI / 2.0, Vector2.ONE)
		draw_string(font, Vector2.ZERO, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.55, 0.55, 0.55))


var _character: Character
var _anim_resource_ref: WeakRef

var _spinbox: SpinBox
var _name_label: LineEdit
var _dir_buttons: Dictionary = {}
var _dir_updating: bool = false
var _current_dir: int = 0
var _frames_container: HBoxContainer
var _anim_preview: AnimPreviewControl
var _updating: bool = false

func _init(character: Character, anim_resource: CharacterAnimationResource) -> void:
	_character = character
	_anim_resource_ref = weakref(anim_resource)

	# Inline: SpinBox + read-only name label
	var inline_row := HBoxContainer.new()
	inline_row.add_theme_constant_override("separation", 4)
	inline_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_spinbox = SpinBox.new()
	_spinbox.min_value = 0
	_spinbox.max_value = 999
	_spinbox.step = 1
	_spinbox.value_changed.connect(_on_row_changed)
	inline_row.add_child(_spinbox)

	_name_label = LineEdit.new()
	_name_label.editable = false
	_name_label.placeholder_text = "(no name)"
	_name_label.tooltip_text = "Generated animation clip name (read-only)"
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inline_row.add_child(_name_label)

	add_child(inline_row)

	# Bottom layout
	var bottom_vbox := VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 4)

	# Row 1: compass grid (left) + square animated preview (right, expands)
	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 8)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.85, 0.65, 0.05)
	pressed_style.set_corner_radius_all(4)
	pressed_style.content_margin_left   = 4.0
	pressed_style.content_margin_right  = 4.0
	pressed_style.content_margin_top    = 4.0
	pressed_style.content_margin_bottom = 4.0
	pressed_style.border_width_left   = 1
	pressed_style.border_width_right  = 1
	pressed_style.border_width_top    = 1
	pressed_style.border_width_bottom = 1
	pressed_style.border_color = Color(1.0, 0.84, 0.32)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for grid_row: Array in GRID_LAYOUT:
		for dir_val: int in grid_row:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(32, 32)
			btn.focus_mode = Control.FOCUS_NONE
			if dir_val < 0:
				btn.disabled = true
				btn.flat = true
			else:
				btn.toggle_mode = true
				btn.text = DIR_ARROWS[dir_val]
				btn.add_theme_stylebox_override("pressed", pressed_style)
				btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.07, 0.0))
				_dir_buttons[dir_val] = btn
				btn.toggled.connect(_on_dir_button_toggled.bind(dir_val))
			grid.add_child(btn)
	preview_row.add_child(grid)

	var vlabel_dir := _VLabel.new("Direction Selector")
	preview_row.add_child(vlabel_dir)

	var vlabel_anim := _VLabel.new("Animation Preview")
	preview_row.add_child(vlabel_anim)

	_anim_preview = AnimPreviewControl.new()
	preview_row.add_child(_anim_preview)

	bottom_vbox.add_child(preview_row)

	# Row 2: static frame strip
	_frames_container = HBoxContainer.new()
	_frames_container.add_theme_constant_override("separation", 2)
	bottom_vbox.add_child(_frames_container)

	add_child(bottom_vbox)
	set_bottom_editor(bottom_vbox)


func _update_property() -> void:
	var row_val: int = get_edited_object().get("row")
	_current_dir = get_edited_object().get("direction")
	_updating = true
	_spinbox.value = row_val
	_updating = false
	_dir_updating = true
	for d: int in _dir_buttons:
		(_dir_buttons[d] as Button).button_pressed = (d == _current_dir)
	_dir_updating = false
	_update_name_label()
	_build_preview(row_val)


func _on_row_changed(value: float) -> void:
	if _updating:
		return
	emit_changed("row", int(value))


func _on_dir_button_toggled(pressed: bool, dir_val: int) -> void:
	if _dir_updating:
		return
	if not pressed:
		_dir_updating = true
		(_dir_buttons[dir_val] as Button).button_pressed = true
		_dir_updating = false
		return
	_dir_updating = true
	for d: int in _dir_buttons:
		if d != dir_val:
			(_dir_buttons[d] as Button).button_pressed = false
	_dir_updating = false
	_current_dir = dir_val
	_update_name_label()
	emit_changed("direction", dir_val)


func _update_name_label() -> void:
	var anim_res := _anim_resource_ref.get_ref() as CharacterAnimationResource
	if not anim_res or anim_res.animation_name.is_empty():
		_name_label.text = ""
		return
	var suffix: String = DIR_SUFFIXES[_current_dir] if _current_dir >= 0 and _current_dir < DIR_SUFFIXES.size() else "Down"
	_name_label.text = anim_res.animation_name + suffix


func _build_preview(row_val: int) -> void:
	for child in _frames_container.get_children():
		child.queue_free()
	_anim_preview.set_frames([], 10.0)

	var anim_res := _anim_resource_ref.get_ref() as CharacterAnimationResource
	if not anim_res or not is_instance_valid(_character):
		return

	var sprite_res: CharacterSpriteResource = null
	for sheet: CharacterSpriteResource in _character.visual_sprite_sheets:
		if sheet and sheet.sheet_name == anim_res.sprite_sheet_name:
			sprite_res = sheet
			break

	if not sprite_res or not sprite_res.texture:
		_add_dim_label("(no sprite sheet)")
		return

	var sprite_size: int = sprite_res.sprite_size
	if sprite_size <= 0:
		_add_dim_label("(invalid sprite size)")
		return

	var vframes: int = sprite_res.get_vframes()
	if row_val >= vframes:
		_add_dim_label("row %d out of range (0-%d)" % [row_val, max(0, vframes - 1)])
		return

	var hframes: int = sprite_res.get_hframes()
	var frame_count: int
	if anim_res.frame_count > 0 and anim_res.frame_count <= hframes:
		frame_count = anim_res.frame_count
	else:
		var sheet_img: Image = sprite_res.texture.get_image() if sprite_res.texture else null
		frame_count = CharacterAnimator._detect_frame_count(sheet_img, hframes, vframes, row_val)

	var display_size: int = sprite_size * DISPLAY_SCALE
	var atlas_frames: Array = []

	for i: int in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_res.texture
		atlas.region = Rect2(i * sprite_size, row_val * sprite_size, sprite_size, sprite_size)
		atlas.filter_clip = true
		atlas_frames.append(atlas)

		var tr := TextureRect.new()
		tr.texture = atlas
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(display_size, display_size)
		_frames_container.add_child(tr)

	_anim_preview.set_frames(atlas_frames, anim_res.frame_rate)


func _add_dim_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_frames_container.add_child(lbl)
