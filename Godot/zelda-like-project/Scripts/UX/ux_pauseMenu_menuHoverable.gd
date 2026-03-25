##[b][color=red]MenuHoverable[/color][/b] is a navigable panel element in a menu.[br]
##Each instance represents one selectable slot in the menu. The player navigates[br]
##between hoverables using D-pad/stick input.[br]
##[br]
##Exports control the child TextureRect's appearance and update in-editor.[br]
##Each panel has its own cursor TextureRect that activates/deactivates on hover.[br]
##[br]
##Supports [b]MenuItemResource[/b] to display item sprites, outlines,[br]
##looping animations on hover, flash effects, and info box population.
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
##The child TextureRect this panel controls (background/outline).
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
##The pivot offset ratio X (0.0 = left, 0.5 = center, 1.0 = right).
@export_range(0.0, 1.0) var content_pivot_x : float = 0.5:
	set(value):
		content_pivot_x = value
		_apply_content_properties()
##The pivot offset ratio Y (0.0 = top, 0.5 = center, 1.0 = bottom).
@export_range(0.0, 1.0) var content_pivot_y : float = 0.5:
	set(value):
		content_pivot_y = value
		_apply_content_properties()

@export_category("Item Display")
@export_group("Item")
##The MenuItemResource this panel displays. If null, panel shows only its background.
@export var item_resource : MenuItemResource
##The TextureRect child used to display the item sprite (outline or animated).[br]
##This is separate from panel_rect — it sits on top of the background.
@export var item_rect : TextureRect

@export_group("Animation")
##The speed of the item's looping animation in frames per second.
@export var anim_fps : float = 10.0
##The AnimationPlayer used for the flash effect when hovering a collected item.
@export var flash_player : AnimationPlayer

@export_group("Info Box")
##The RichTextLabel used to display item info when hovered.[br]
##Each hoverable can reference the same shared info box.
@export var info_box : RichTextLabel

@export_group("Quantity")
##The Label child used to display item quantity. Hidden when not applicable.
@export var quantity_label : Label

@export_category("Cursor")
##The texture used for the cursor when this panel is hovered.
@export var cursor_texture : Texture2D:
	set(value):
		cursor_texture = value
		_apply_cursor_properties()
##The TextureRect child used as this panel's cursor overlay.
@export var cursor_rect : TextureRect:
	set(value):
		cursor_rect = value
		_apply_cursor_properties()
##A reference to the animation player for the cursor.
@export var cursor_anim = Node

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "MenuHoverable"

#=======INTERNAL VARIABLES=======#

##Whether this panel is currently hovered by the cursor.
var _is_hovered : bool = false
##Cached frames sliced from the item's main AtlasTexture strip.
var _item_frames : Array[AtlasTexture] = []
##Current animation frame index.
var _anim_frame : int = 0
##Time accumulator for frame animation.
var _anim_time : float = 0.0
##Whether the item animation is currently playing.
var _anim_playing : bool = false
##A reference to the player's inventory component; used for gathering data.
var inventory : InventoryComponent:
	set(value):
		inventory = value
		if not Engine.is_editor_hint():
			if _item_frames.is_empty():
				_slice_item_frames()
			_update_item_display()
			_update_quantity()
##Returns whether the player currently owns this item.
var player_has_item : bool:
	get:
		if not inventory or not item_resource or item_resource.item_id.is_empty():
			return false
		return inventory.has_item(item_resource.item_id)

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
		_slice_item_frames()
		_update_item_display()
		_update_quantity()
	set_process(false)

func _process(delta : float) -> void:
	if not _anim_playing or _item_frames.is_empty():
		return
	_anim_time += delta
	var frame_duration = 1.0 / anim_fps
	if _anim_time >= frame_duration:
		_anim_time -= frame_duration
		_anim_frame = (_anim_frame + 1) % _item_frames.size()
		if item_rect:
			item_rect.texture = _item_frames[_anim_frame]

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

#region ITEM DISPLAY

##Slices the item's main AtlasTexture strip into 9 individual frames.
func _slice_item_frames() -> void:
	_item_frames.clear()
	if not item_resource or not item_resource.main or not item_resource.main.atlas:
		return
	var strip = item_resource.main
	var base_x : float = strip.region.position.x
	var base_y : float = strip.region.position.y
	var frame_size : float = strip.region.size.y
	for i in range(9):
		var frame = AtlasTexture.new()
		frame.atlas = strip.atlas
		frame.region = Rect2(
			base_x + (i * frame_size),
			base_y,
			frame_size,
			frame_size
		)
		frame.filter_clip = true
		_item_frames.append(frame)
	if debug_me:
		print(debug_name, ": Sliced ", _item_frames.size(), " item frames.")

##Updates the item_rect to show outline or frame 0 based on ownership.
func _update_item_display() -> void:
	if not item_rect or not item_resource:
		return
	if player_has_item:
		if not _item_frames.is_empty():
			item_rect.texture = _item_frames[0]
	else:
		if item_resource.outline:
			item_rect.texture = item_resource.outline

#endregion ITEM DISPLAY

#region ITEM ANIMATION

##Starts the looping frame animation for the item sprite.
func _start_item_anim() -> void:
	if _item_frames.is_empty() or not player_has_item:
		return
	_anim_frame = 0
	_anim_time = 0.0
	_anim_playing = true
	set_process(true)
	if debug_me:
		print(debug_name, ": Item animation started.")

##Stops the item animation and resets to frame 0.
func _stop_item_anim() -> void:
	_anim_playing = false
	_anim_frame = 0
	_anim_time = 0.0
	set_process(false)
	if item_rect and not _item_frames.is_empty() and player_has_item:
		item_rect.texture = _item_frames[0]
	if debug_me:
		print(debug_name, ": Item animation stopped.")

#endregion ITEM ANIMATION

#region FLASH

##Starts the flash animation if the item supports it.
func _start_flash() -> void:
	if not item_resource or not item_resource.flash:
		return
	if not flash_player:
		return
	if not flash_player.has_animation("Flash"):
		return
	var anim = flash_player.get_animation("Flash")
	#Find the modulate track and set its second key to the resource's flash color.
	for track_idx in range(anim.get_track_count()):
		var path = anim.track_get_path(track_idx)
		if ":self_modulate" in str(path) and anim.track_get_key_count(track_idx) >= 2:
			anim.track_set_key_value(track_idx, 1, item_resource.flash_color)
			break
	flash_player.play("Flash")

##Stops the flash animation.
func _stop_flash() -> void:
	if not flash_player:
		return
	if flash_player.is_playing():
		flash_player.stop()
	if item_rect:
		item_rect.modulate = Color(1, 1, 1, 1)

#endregion FLASH

#region INFO BOX

##Populates the info box RichTextLabel with the item's data.
func _populate_info_box() -> void:
	if not info_box or not item_resource:
		return
	if not player_has_item:
		_clear_info_box()
		return
	var text = ""
	text += "[color=red][font_size=28]" + item_resource.name + "[/font_size][/color]\n"
	if item_resource.description_font:
		var font_path = item_resource.description_font.resource_path
		text += "[font=" + font_path + "]"
	text += "[color=gray][font_size=12]" + item_resource.description + "[/font_size][/color]"
	if item_resource.description_font:
		text += "[/font]"
	text += "\n"
	if item_resource.effect_font:
		var font_path = item_resource.effect_font.resource_path
		text += "[font=" + font_path + "]"
	text += "[color=white][font_size=14]" + item_resource.effect + "[/font_size][/color]"
	if item_resource.effect_font:
		text += "[/font]"
	info_box.bbcode_enabled = true
	info_box.text = text

##Clears the info box text.
func _clear_info_box() -> void:
	if not info_box:
		return
	info_box.text = ""

#endregion INFO BOX

#region CURSOR PROPERTIES

##Applies cursor texture to the cursor TextureRect.
func _apply_cursor_properties() -> void:
	if not cursor_rect:
		return
	if cursor_texture:
		cursor_rect.texture = cursor_texture

#endregion CURSOR PROPERTIES

#region QUANTITY

func _update_quantity() -> void:
	if not quantity_label:
		return
	if not item_resource or not item_resource.display_quantity:
		quantity_label.visible = false
		return
	if not player_has_item:
		quantity_label.visible = false
		return
	var qty = inventory.get_quantity(item_resource.item_id) if inventory else 0
	if qty <= 0:
		quantity_label.visible = false
	else:
		quantity_label.visible = true
		quantity_label.text = str(qty)

#endregion QUANTITY

#region HOVER STATE

##Activates the cursor on this panel and starts item effects.
func hover() -> void:
	_is_hovered = true
	if cursor_rect:
		cursor_rect.visible = true
	if cursor_anim and cursor_anim.has_animation("CursorActive"):
		cursor_anim.play("CursorActive")
	if item_resource and player_has_item:
		_start_item_anim()
		_start_flash()
		_populate_info_box()
	if debug_me:
		print(debug_name, ": Hovered.")

##Deactivates the cursor on this panel and stops item effects.
func unhover() -> void:
	_is_hovered = false
	if cursor_rect:
		cursor_rect.visible = false
	if cursor_anim and cursor_anim.is_playing():
		cursor_anim.stop()
	_stop_item_anim()
	_stop_flash()
	_clear_info_box()
	_update_item_display()
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
