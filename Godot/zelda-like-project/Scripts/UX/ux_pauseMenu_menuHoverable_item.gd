##[b][color=red]MenuHoverableItem[/color][/b] extends [b]MenuHoverable[/b] for inventory item panels.[br]
##Handles item sprite display (outline/owned), frame animation on hover,[br]
##flash effects, quantity labels, and inventory integration.
@tool
class_name MenuHoverableItem
extends MenuHoverable

#region VARIABLES

@export_category("Item Display")
@export_group("Item")
##The MenuItemResource this panel displays. If null, panel shows only its background.
@export var item_resource : MenuItemResource
##The TextureRect child used to display the item sprite (outline or animated).
@export var item_rect : TextureRect

@export_group("Animation")
##The speed of the item's looping animation in frames per second.
@export var anim_fps : float = 10.0
##The AnimationPlayer used for the flash effect when hovering a collected item.
@export var flash_player : AnimationPlayer

@export_group("Quantity")
##The Label child used to display item quantity. Hidden when not applicable.
@export var quantity_label : Label

#=======INTERNAL VARIABLES=======#

##Cached frames sliced from the item's main AtlasTexture strip.
var _item_frames : Array[AtlasTexture] = []
##Current animation frame index.
var _anim_frame : int = 0
##Time accumulator for frame animation.
var _anim_time : float = 0.0
##Whether the item animation is currently playing.
var _anim_playing : bool = false
##A reference to the player's inventory component; set at runtime by MenuController.
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

func _on_hoverable_ready() -> void:
	_slice_item_frames()
	_update_item_display()
	_update_quantity()

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

#region ITEM DISPLAY

##Slices the item's main AtlasTexture strip into individual frames.
func _slice_item_frames() -> void:
	_item_frames.clear()
	if not item_resource or not item_resource.main or not item_resource.main.atlas:
		return
	var strip = item_resource.main
	var base_x : int = int(strip.region.position.x)
	var base_y : int = int(strip.region.position.y)
	var strip_width : int = int(strip.region.size.x)
	var strip_height : int = int(strip.region.size.y)
	var frame_w : int = int(float(strip_width) / float(item_resource.h_frames))
	var frame_h : int = strip_height
	for i in range(item_resource.h_frames):
		var frame = AtlasTexture.new()
		frame.atlas = strip.atlas
		frame.region = Rect2(
			base_x + (i * frame_w),
			base_y,
			frame_w,
			frame_h
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

func _start_item_anim() -> void:
	if _item_frames.is_empty() or not player_has_item:
		return
	_anim_frame = 0
	_anim_time = 0.0
	_anim_playing = true
	set_process(true)
	if debug_me:
		print(debug_name, ": Item animation started.")

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

func _start_flash() -> void:
	if not item_resource or not item_resource.flash:
		return
	if not flash_player:
		return
	if not flash_player.has_animation("Flash"):
		return
	var anim = flash_player.get_animation("Flash")
	for track_idx in range(anim.get_track_count()):
		var path = anim.track_get_path(track_idx)
		if ":self_modulate" in str(path) and anim.track_get_key_count(track_idx) >= 2:
			anim.track_set_key_value(track_idx, 1, item_resource.flash_color)
			break
	flash_player.play("Flash")

func _stop_flash() -> void:
	if not flash_player:
		return
	if flash_player.is_playing():
		flash_player.stop()
	if item_rect:
		item_rect.modulate = Color(1, 1, 1, 1)

#endregion FLASH

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

#region INFO BOX

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
	text += "[color=gray][font_size=16]" + item_resource.description + "[/font_size][/color]"
	if item_resource.description_font:
		text += "[/font]"
	text += "\n"
	if item_resource.effect_font:
		var font_path = item_resource.effect_font.resource_path
		text += "[font=" + font_path + "]"
	text += "[color=white][font_size=16]" + item_resource.effect + "[/font_size][/color]"
	if item_resource.effect_font:
		text += "[/font]"
	info_box.bbcode_enabled = true
	info_box.text = text

#endregion INFO BOX

#region HOVER OVERRIDES

func _on_hover() -> void:
	if item_resource and player_has_item:
		_start_item_anim()
		_start_flash()
		_populate_info_box()

func _on_unhover() -> void:
	_stop_item_anim()
	_stop_flash()
	_update_item_display()
	_update_quantity()

#endregion HOVER OVERRIDES

#endregion FUNCTIONS
