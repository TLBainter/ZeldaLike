##[b][color=red]MenuHoverable[/color][/b] is a navigable panel element in a menu.[br]
##Each instance represents one selectable slot in the menu. The player navigates[br]
##between hoverables using D-pad/stick input.[br]
##[br]
##Exports control the child TextureRect's appearance and update in-editor.[br]
##Each panel has its own cursor TextureRect that activates/deactivates on hover.
@tool
class_name MenuHoverable
extends Panel

#region VARIABLES

@onready var pause_menu : PauseMenu = owner

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
##The child TextureRect this panel controls.
@export var panel_rect : TextureRect:
	set(value):
		panel_rect = value
		_apply_content_properties()
##The texture to display in the content TextureRect.
@export var panel_texture : Texture2D:
	set(value):
		panel_texture = value
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
		_apply_content_properties()
##The pivot offset ratio X (0.0 = left, 0.5 = center, 1.0 = right).[br]
##Applied as a ratio of the TextureRect's size.
@export_range(0.0, 1.0) var content_pivot_x : float = 0.5:
	set(value):
		content_pivot_x = value
		_apply_content_properties()
##The pivot offset ratio Y (0.0 = top, 0.5 = center, 1.0 = bottom).[br]
##Applied as a ratio of the TextureRect's size.
@export_range(0.0, 1.0) var content_pivot_y : float = 0.5:
	set(value):
		content_pivot_y = value
		_apply_content_properties()

@export_category("Cursor")
##The animator for the cursor's 'active' animation.
@export var cursor_anim : AnimationPlayer
##The texture used for the cursor when this panel is hovered.[br]
##Each panel has its own cursor TextureRect child that shows/hides.
@export var cursor_texture : Texture2D:
	set(value):
		cursor_texture = value
		_apply_cursor_properties()
##The TextureRect child used as this panel's cursor overlay.
@export var cursor_rect : TextureRect:
	set(value):
		cursor_rect = value
		_apply_cursor_properties()
		
@export_category("Sounds")
@onready var nav_move_sounds : SoundLibrary = pause_menu.nav_move_sounds


@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "MenuHoverable"

#=======INTERNAL VARIABLES=======#

##Whether this panel is currently hovered by the cursor.
var _is_hovered : bool = false

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	if debug_me:
		if pause_menu:
			print(debug_name, " found pause menu with a value of ", pause_menu)
		elif not pause_menu:
			print(debug_name, " has not configured its pause menu!")
	_apply_content_properties()
	_apply_cursor_properties()
	#Cursor starts hidden.
	if cursor_rect:
		cursor_rect.visible = false

#region CONTENT PROPERTIES

##Applies all exported content properties to the child TextureRect.[br]
##Called from setters so changes appear in-editor.
func _apply_content_properties() -> void:
	if not panel_rect:
		return
	if panel_texture:
		panel_rect.texture = panel_texture
	#Apply anchors preset.
	panel_rect.set_anchors_preset(content_anchors_preset as Control.LayoutPreset)
	panel_rect.size = panel_texture.get_size()
	#Apply pivot offset as ratio of size.
	_update_pivot()

##Updates the pivot offset based on the ratio exports and current size.
func _update_pivot() -> void:
	if not panel_rect:
		return
	panel_rect.pivot_offset_ratio = Vector2(content_pivot_x, content_pivot_y)

#endregion CONTENT PROPERTIES

#region CURSOR PROPERTIES

##Applies cursor texture to the cursor TextureRect.[br]
##Called from setters so changes appear in-editor.
func _apply_cursor_properties() -> void:
	if not cursor_rect:
		return
	if cursor_texture:
		cursor_rect.texture = cursor_texture

#endregion CURSOR PROPERTIES

#region HOVER STATE

##Activates the cursor on this panel.
func hover() -> void:
	_is_hovered = true
	if nav_move_sounds:
		if not nav_move_sounds.sl.is_empty():
			var clip = nav_move_sounds.sl.pick_random()
			if audioManager:
				audioManager.play(clip, "UI")
	if cursor_rect:
		cursor_rect.visible = true
	if cursor_anim:
		cursor_anim.play("CursorActive")
	if debug_me:
		print(debug_name, ": Hovered.")

##Deactivates the cursor on this panel.
func unhover() -> void:
	_is_hovered = false
	if cursor_rect:
		cursor_rect.visible = false
	if cursor_anim and cursor_anim.is_playing():
		cursor_anim.play("RESET")
		cursor_anim.stop()
	if debug_me:
		print(debug_name, ": Unhovered.")

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
