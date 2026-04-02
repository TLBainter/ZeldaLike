##[b][color=red]MenuHoverable[/color][/b] is the base class for navigable panel elements in a menu.[br]
##Handles navigation links, panel TextureRect, cursor display, and info box basics.[br]
@tool
class_name MenuHoverable
extends Panel

#region VARIABLES

@export_category("Navigation")
##The hoverable to navigate to when pressing UP.
@export var up_nav : MenuHoverable
##The hoverable to navigate to when pressing DOWN.
@export var down_nav : MenuHoverable
##The hoverable to navigate to when pressing LEFT.
@export var left_nav : MenuHoverable
##The hoverable to navigate to when pressing RIGHT.
@export var right_nav : MenuHoverable

@export_category("Content TextureRect")
@export_group("Panel")
##The child TextureRect this panel controls (background).
@export var panel_rect : TextureRect:
	set(value):
		panel_rect = value
		if is_inside_tree():
			_apply_content_properties()
##The texture to display in the content TextureRect.
@export var panel_texture : Texture2D:
	set(value):
		panel_texture = value
		if is_inside_tree():
			_apply_content_properties()
##The anchors preset for the content TextureRect.
@export_enum(
	"Top Left:0", "Top Right:1", "Bottom Right:2", "Bottom Left:3",
	"Center Left:4", "Center Top:5", "Center Right:6", "Center Bottom:7",
	"Center:8", "Left Wide:9", "Top Wide:10", "Right Wide:11",
	"Bottom Wide:12", "VCenter Wide:13", "HCenter Wide:14", "Full Rect:15"
) var content_anchors_preset : int = 15:
	set(value):
		content_anchors_preset = value
		if is_inside_tree():
			_apply_content_properties()
##The pivot offset ratio X (0.0 = left, 0.5 = center, 1.0 = right).
@export_range(0.0, 1.0) var content_pivot_x : float = 0.5:
	set(value):
		content_pivot_x = value
		if is_inside_tree():
			_apply_content_properties()
##The pivot offset ratio Y (0.0 = top, 0.5 = center, 1.0 = bottom).
@export_range(0.0, 1.0) var content_pivot_y : float = 0.5:
	set(value):
		content_pivot_y = value
		if is_inside_tree():
			_apply_content_properties()

@export_category("Info Box")
##The RichTextLabel used to display info when hovered.
@export var info_box : RichTextLabel

@export_category("Cursor")
##The texture used for the cursor when this panel is hovered.
@export var cursor_texture : Texture2D:
	set(value):
		cursor_texture = value
		if is_inside_tree():
			_apply_cursor_properties()
##The TextureRect child used as this panel's cursor overlay.
@export var cursor_rect : TextureRect:
	set(value):
		cursor_rect = value
		if is_inside_tree():
			_apply_cursor_properties()
##A reference to the animation player for the cursor.
@export var cursor_anim = Node

@export_category("Spell Assignment")
@export_group("Button Sprites")
##The texture to display when this spell is assigned to Action Button 1.
@export var button_1_sprite : Texture2D
##The texture to display when this spell is assigned to Action Button 2.
@export var button_2_sprite : Texture2D
##The texture to display when this spell is assigned to Action Button 3.
@export var button_3_sprite : Texture2D

@export_group("Components")
##The TextureRect that shows which button this spell is assigned to.
@export var assignment_rect : TextureRect

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_me_verbose : bool = false
@export var debug_name : String = "MenuHoverable"

#=======INTERNAL VARIABLES=======#

##Whether this panel is currently hovered by the cursor.
var _is_hovered : bool = false

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	if not Engine.is_editor_hint():
		process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_apply_content_properties()
	_apply_cursor_properties()
	if cursor_rect:
		cursor_rect.visible = false
	if not Engine.is_editor_hint():
		_on_hoverable_ready()
	set_process(false)

##Virtual. Called at the end of _ready() for subclass-specific setup.
func _on_hoverable_ready() -> void:
	pass

#region CONTENT PROPERTIES

##Applies all exported content properties to the child TextureRect.
func _apply_content_properties() -> void:
	if not panel_rect:
		return
	if panel_texture:
		panel_rect.texture = panel_texture
		panel_rect.size = panel_texture.get_size()
	panel_rect.set_anchors_preset(content_anchors_preset as Control.LayoutPreset)
	_update_pivot()

##Updates the pivot offset based on the ratio exports and current size.
func _update_pivot() -> void:
	if not panel_rect:
		return
	var rect_size = panel_rect.size
	if rect_size == Vector2.ZERO and panel_texture:
		rect_size = panel_texture.get_size()
	panel_rect.pivot_offset = Vector2(
		rect_size.x * content_pivot_x,
		rect_size.y * content_pivot_y
	)

#endregion CONTENT PROPERTIES

#region CURSOR PROPERTIES

##Applies cursor texture to the cursor TextureRect.
func _apply_cursor_properties() -> void:
	if not cursor_rect:
		return
	if cursor_texture:
		cursor_rect.texture = cursor_texture

#endregion CURSOR PROPERTIES

#region INFO BOX

##Virtual. Populates the info box when hovered. Override in subclasses.
func _populate_info_box() -> void:
	pass

##Clears the info box text.
func _clear_info_box() -> void:
	if not info_box:
		return
	info_box.text = ""

#endregion INFO BOX

#region HOVER STATE

##Activates the cursor on this panel. Subclasses should call super.
func hover() -> void:
	_is_hovered = true
	if cursor_rect:
		cursor_rect.visible = true
	if cursor_anim and cursor_anim.has_animation("CursorActive"):
		cursor_anim.play("CursorActive")
	_on_hover()
	if debug_me:
		print(debug_name, ": Hovered.")

##Deactivates the cursor on this panel. Subclasses should call super.
func unhover() -> void:
	_is_hovered = false
	if cursor_rect:
		cursor_rect.visible = false
	if cursor_anim and cursor_anim.is_playing():
		cursor_anim.stop()
	_on_unhover()
	_clear_info_box()
	if debug_me:
		print(debug_name, ": Unhovered.")

##Virtual. Called when this panel is hovered. Override for subclass-specific effects.
func _on_hover() -> void:
	pass

##Virtual. Called when this panel is unhovered. Override for subclass-specific cleanup.
func _on_unhover() -> void:
	pass

##Returns the hoverable in the given direction, or null if none.
func get_nav(direction : String) -> MenuHoverable:
	match direction:
		"up": return up_nav
		"down": return down_nav
		"left": return left_nav
		"right": return right_nav
	return null

#endregion HOVER STATE

#endregion FUNCTIONS
