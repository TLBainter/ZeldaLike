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
##A reference to the player's health component; used for upgrade cap checks.
var health : PlayerHealthComponent:
	set(value):
		health = value
		if not Engine.is_editor_hint() and inventory:
			_update_item_display()
##Returns whether the player currently owns this item.
var player_has_item : bool:
	get:
		if not inventory or not item_resource or item_resource.item_id.is_empty():
			return false
		return inventory.has_item(item_resource.item_id)
##Casts item_resource to MenuItemUpgradeResource; null if it is not an upgrade resource.
var _as_upgrade : MenuItemUpgradeResource:
	get:
		return item_resource as MenuItemUpgradeResource

##When item_resource is a base mobility item and the player already owns its
##upgrade, returns the upgrade's MenuItemResource; otherwise returns item_resource.
var _active_resource : MenuItemResource:
	get:
		if not item_resource or not inventory:
			return item_resource
		var upgrade_id : String = ItemID.MOBILITY_UPGRADES.get(item_resource.item_id, "")
		if upgrade_id != "" and inventory.has_item(upgrade_id):
			return ItemID.MENU_ITEM_RESOURCES.get(upgrade_id, item_resource)
		return item_resource

##Returns true when the player has reached the effective cap for this upgrade,
##accounting for base stats already included in max_quantity.
func _is_upgrade_at_max(upgrade: MenuItemUpgradeResource, qty: int) -> bool:
	if upgrade.max_quantity <= 0:
		return false
	var base_health := health.base_max_health if health else 0
	var adjusted := upgrade.get_adjusted_max_total(base_health)
	return adjusted > 0 and qty >= adjusted

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
##For upgrade resources, slices the current part's anim strip instead.
func _slice_item_frames() -> void:
	_item_frames.clear()
	var upgrade := _as_upgrade
	if upgrade:
		var qty := _get_quantity()
		var current_parts := upgrade.num_parts if _is_upgrade_at_max(upgrade, qty) else upgrade.get_current_parts(qty)
		var part := upgrade.get_part_data(current_parts)
		if not part or not part.part_anim_sprite or not part.part_anim_sprite.atlas:
			return
		_slice_strip(part.part_anim_sprite, part.anim_h_frames)
	else:
		var res := _active_resource
		if not res or not res.main or not res.main.atlas:
			return
		_slice_strip(res.main, res.h_frames)

##Slices [param strip] into [param h_frames] individual AtlasTexture frames, appending to _item_frames.
func _slice_strip(strip : AtlasTexture, h_frames : int) -> void:
	var base_x : int = int(strip.region.position.x)
	var base_y : int = int(strip.region.position.y)
	var frame_w : int = int(float(strip.region.size.x) / float(h_frames))
	var frame_h : int = int(strip.region.size.y)
	for i in range(h_frames):
		var frame = AtlasTexture.new()
		frame.atlas = strip.atlas
		frame.region = Rect2(base_x + (i * frame_w), base_y, frame_w, frame_h)
		frame.filter_clip = true
		_item_frames.append(frame)
	if debug_me:
		print(debug_name, ": Sliced ", _item_frames.size(), " frames.")

##Updates the item_rect texture based on ownership and upgrade state.
func _update_item_display() -> void:
	if not item_rect or not item_resource:
		return
	var upgrade := _as_upgrade
	if upgrade:
		_update_upgrade_display(upgrade)
		return
	if player_has_item:
		_slice_item_frames()
		var tex : Texture2D = _cell_texture()
		if tex:
			item_rect.texture = tex
	else:
		var res := _active_resource
		if res and res.outline:
			item_rect.texture = res.outline

##Static cell sprite for an owned non-upgrade item: the active resource's mini_icon when set, else frame 0 of the sliced main strip (stardust has no mini_icon), else null.
func _cell_texture() -> Texture2D:
	var res := _active_resource
	if res and res.mini_icon:
		return res.mini_icon
	if not _item_frames.is_empty():
		return _item_frames[0]
	return null

##Large art for the info altar, read from the resource: main strip frame 0 when owned, the current part sprite for upgrades, the outline when not owned.
func info_texture() -> Texture2D:
	var upgrade := _as_upgrade
	if upgrade:
		return _upgrade_static_texture(upgrade) if player_has_item else upgrade.outline
	var res := _active_resource
	if not res:
		return null
	if not player_has_item:
		return res.outline
	return main_frame(res)

##Returns frame 0 of res.main as a new AtlasTexture, or res.mini_icon when res has no main strip.
static func main_frame(res : MenuItemResource) -> Texture2D:
	if not res:
		return null
	if not res.main or not res.main.atlas:
		return res.mini_icon
	var frame := AtlasTexture.new()
	frame.atlas = res.main.atlas
	var w : float = float(int(res.main.region.size.x / float(maxi(res.h_frames, 1))))
	frame.region = Rect2(res.main.region.position, Vector2(w, res.main.region.size.y))
	frame.filter_clip = true
	return frame

##Returns the static part sprite for the upgrade's current part count, or null when the part has none.
func _upgrade_static_texture(upgrade : MenuItemUpgradeResource) -> Texture2D:
	var qty := _get_quantity()
	var target_part : int
	if _is_upgrade_at_max(upgrade, qty):
		target_part = upgrade.num_parts
	else:
		target_part = upgrade.get_current_parts(qty)
	var part := upgrade.get_part_data(target_part)
	if part and part.part_static_sprite:
		return part.part_static_sprite
	return null

##Sets the correct static texture for the current upgrade part state.
func _update_upgrade_display(upgrade : MenuItemUpgradeResource) -> void:
	if not item_rect:
		return
	if not player_has_item:
		if upgrade.outline:
			item_rect.texture = upgrade.outline
		return
	var tex : Texture2D = _upgrade_static_texture(upgrade)
	if tex:
		item_rect.texture = tex

#endregion ITEM DISPLAY

#region ITEM ANIMATION

##Cycles the upgrade part strip while hovered; non-upgrade cells keep their static _cell_texture().
func _start_item_anim() -> void:
	if not player_has_item:
		return
	var upgrade := _as_upgrade
	if not upgrade or _get_quantity() == 0:
		return
	_slice_item_frames()
	if _item_frames.is_empty():
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
	var upgrade := _as_upgrade
	if upgrade:
		_update_upgrade_display(upgrade)
	elif item_rect and player_has_item:
		var tex : Texture2D = _cell_texture()
		if tex:
			item_rect.texture = tex
	if debug_me:
		print(debug_name, ": Item animation stopped.")

#endregion ITEM ANIMATION

#region FLASH

func _start_flash() -> void:
	var res := _active_resource
	if not res or not res.flash:
		return
	if not flash_player:
		return
	if not flash_player.has_animation("Flash"):
		return
	var anim = flash_player.get_animation("Flash")
	for track_idx in range(anim.get_track_count()):
		var path = anim.track_get_path(track_idx)
		if ":self_modulate" in str(path) and anim.track_get_key_count(track_idx) >= 2:
			anim.track_set_key_value(track_idx, 1, res.flash_color)
			break
	flash_player.play("Flash")

func _stop_flash() -> void:
	if not flash_player:
		return
	if flash_player.is_playing():
		flash_player.stop()
	if item_rect:
		item_rect.modulate = Color(1, 1, 1, 1)
		item_rect.self_modulate = Color(1, 1, 1, 1)

#endregion FLASH

#region QUANTITY

##Returns the player's current quantity of this item, or 0 if inventory is unavailable.
func _get_quantity() -> int:
	return inventory.get_quantity(item_resource.item_id) if inventory else 0

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

##Dialogue lines for this item: the upgrade's full text once maxed, else the active resource's text.
func _info_lines() -> Array:
	var upgrade := _as_upgrade
	var qty := _get_quantity() if upgrade else 0
	var at_max := upgrade != null and _is_upgrade_at_max(upgrade, qty)
	var ref_id : String = ""
	if at_max and upgrade.full_text_ref_id != "":
		ref_id = upgrade.full_text_ref_id
	elif _active_resource:
		ref_id = _active_resource.text_ref_id
	if ref_id.is_empty():
		return []
	var data : Dictionary = dialogueDB.get_dialogue_data(ref_id)
	return data.get("lines", [])

##Display name of the owned item from dialogue line 0, or "" when not owned.
func info_name() -> String:
	if not item_resource or not player_has_item:
		return ""
	var lines := _info_lines()
	return str(lines[0]).trim_suffix(" Concoction") if lines.size() > 0 else ""

##Frames for the info altar animation: the owned item's sliced strip, else empty; upgrades with no parts return empty.
func info_frames() -> Array[AtlasTexture]:
	var frames : Array[AtlasTexture] = []
	if not item_resource or not player_has_item:
		return frames
	if _as_upgrade and _get_quantity() == 0:
		return frames
	_slice_item_frames()
	frames.assign(_item_frames)
	return frames

##Writes the description only (Body 16 from the scene) or the "No description yet." placeholder; the name is shown by the pause menu's InfoName label.
func _populate_info_box() -> void:
	if not info_box or not item_resource:
		return
	if not player_has_item:
		_clear_info_box()
		return
	var upgrade := _as_upgrade
	var qty := _get_quantity() if upgrade else 0
	var at_max := upgrade != null and _is_upgrade_at_max(upgrade, qty)
	var lines := _info_lines()
	var desc_text : String = str(lines[2]) if lines.size() > 2 else ""
	if upgrade and not at_max:
		desc_text = upgrade.resolve_remaining_text(desc_text, qty)
	info_box.bbcode_enabled = true
	if desc_text.strip_edges().is_empty():
		info_box.text = "[center][color=#b98c90]No description yet.[/color][/center]"
	else:
		info_box.text = "[center]" + desc_text + "[/center]"

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
