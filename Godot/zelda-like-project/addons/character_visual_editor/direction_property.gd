##Compass-rose direction picker displayed in the Inspector for [b]CharacterAnimationDirectionEntry.direction[/b].[br]
##Shows a 3×3 grid of arrow buttons; clicking a button sets the direction and highlights the selection.
##[codeblock]
## [↖][↑][↗]   UpLeft(3), Up(4), UpRight(5)
## [←][ ][→]   Left(2),  center, Right(6)
## [↙][↓][↘]   DownLeft(1), Down(0), DownRight(7)
##[/codeblock]
@tool
class_name DirectionCompassProperty
extends EditorProperty

## Grid layout: each inner array is one row; -1 = disabled center cell.
const GRID_LAYOUT: Array = [[3, 4, 5], [2, -1, 6], [1, 0, 7]]
## Arrow glyphs indexed by Direction enum value.
const DIR_ARROWS: Dictionary = {0: "↓", 1: "↙", 2: "←", 3: "↖", 4: "↑", 5: "↗", 6: "→", 7: "↘"}

var _dir_buttons: Dictionary = {}  # Direction int → Button
var _updating: bool = false

func _init() -> void:
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
	for row: Array in GRID_LAYOUT:
		for dir_val: int in row:
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
				btn.toggled.connect(_on_button_toggled.bind(dir_val))
			grid.add_child(btn)
	var center := CenterContainer.new()
	center.add_child(grid)
	add_child(center)
	set_bottom_editor(center)

func _update_property() -> void:
	_updating = true
	var current: int = get_edited_object().get("direction")
	for dir_val: int in _dir_buttons:
		(_dir_buttons[dir_val] as Button).button_pressed = (dir_val == current)
	_updating = false

func _on_button_toggled(pressed: bool, dir_val: int) -> void:
	if _updating:
		return
	if not pressed:
		# Keep the active button pressed so one is always selected.
		_updating = true
		(_dir_buttons[dir_val] as Button).button_pressed = true
		_updating = false
		return
	# Unpress all other buttons.
	_updating = true
	for d: int in _dir_buttons:
		if d != dir_val:
			(_dir_buttons[d] as Button).button_pressed = false
	_updating = false
	emit_changed("direction", dir_val)
