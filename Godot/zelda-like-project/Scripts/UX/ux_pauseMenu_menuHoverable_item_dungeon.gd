##[b][color=red]MenuHoverableItemDungeon[/color][/b] extends [b]MenuHoverableItem[/b] for the per-dungeon key, map, journal and boss key slots.[br]
##Shows an empty socket outside dungeons; inside a dungeon shows the item art grayed out until it is collected.
@tool
class_name MenuHoverableItemDungeon
extends MenuHoverableItem

#region VARIABLES

@export_category("Dungeon")
##Material applied to the item art while the item is not collected; the same desaturate material the pause menu uses for unequipped spells.
@export var desaturate_material : Material

##Item id prefix of the current dungeon; set by PauseMenu through set_dungeon_context().
var _dungeon_prefix : String = ""
##Whether the player is currently inside a dungeon level; set by PauseMenu through set_dungeon_context().
var _in_dungeon : bool = false

#endregion VARIABLES

#region FUNCTIONS

##Stores the current dungeon prefix and in-dungeon flag, then refreshes the item art and quantity label.
func set_dungeon_context(prefix : String, in_dungeon : bool) -> void:
	_dungeon_prefix = prefix
	_in_dungeon = in_dungeon
	_update_item_display()
	_update_quantity()

##Returns prefix + "_" + base id while inside a dungeon, else an empty string so the slot never matches an inventory item.
func _effective_item_id() -> String:
	if not item_resource or not _in_dungeon or _dungeon_prefix.is_empty():
		return ""
	return _dungeon_prefix + "_" + item_resource.item_id

##Empty socket outside a dungeon; inside one, shows the item art in color when collected and desaturated when not.
func _update_item_display() -> void:
	if not item_rect or not item_resource:
		return
	if not _in_dungeon:
		item_rect.texture = null
		item_rect.material = null
		return
	_slice_item_frames()
	var tex : Texture2D = _cell_texture()
	if not tex:
		tex = item_resource.outline
	item_rect.texture = tex
	item_rect.material = null if player_has_item else desaturate_material

#endregion FUNCTIONS
