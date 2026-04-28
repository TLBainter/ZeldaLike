class_name DungeonItemDisplay
extends UXElement

#region VARIABLES

@export_category("Components")
@export var root : PlayerUX
@export_group("Textures")
@export var boss_key_texture : TextureRect
@export var journal_texture : TextureRect
@export var map_texture : TextureRect
@export var key_texture : TextureRect
@export_group("Quantity")
@export var key_quantity_display : RichTextLabel

@export_category("Colors")
@export var key_color_zero : Color = Color(0.35, 0.35, 0.35, 1.0)
@export var key_color_positive : Color = Color.WHITE

var _inventory : InventoryComponentPlayer
var _in_dungeon : bool = false
var _dungeon_name : String = ""

#endregion VARIABLES

#region FUNCTIONS

func initialize(inventory : InventoryComponentPlayer, root_ux : PlayerUX) -> void:
	_inventory = inventory
	root = root_ux
	if _inventory and not _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.connect(_on_inventory_changed)
	if SceneTransitionManager and not SceneTransitionManager.transition_complete.is_connected(_on_transition_complete):
		SceneTransitionManager.transition_complete.connect(_on_transition_complete)
	_refresh_dungeon_state()

#region DUNGEON STATE

func _refresh_dungeon_state() -> void:
	var level := _get_current_level()
	if level and level.get_effective_type() == Level.LevelType.DUNGEON:
		_in_dungeon = true
		_dungeon_name = level.get_effective_name().to_lower()
	else:
		_in_dungeon = false
		_dungeon_name = ""
	_update_display()

func _get_current_level() -> Level:
	if root and root.player:
		return Level.get_level_ancestor(root.player)
	return null

func _get_item_id(base_id : String) -> String:
	return _dungeon_name + "_" + base_id

#endregion DUNGEON STATE

#region SIGNAL HANDLERS

func _on_transition_complete() -> void:
	_refresh_dungeon_state()
	if _in_dungeon:
		show_element()

func _on_inventory_changed(item_id : String, _quantity : int) -> void:
	if not _in_dungeon:
		return
	var relevant := [
		_get_item_id(ItemID.KEY),
		_get_item_id(ItemID.MAP),
		_get_item_id(ItemID.JOURNAL),
		_get_item_id(ItemID.BOSS_KEY),
	]
	if item_id in relevant:
		_update_display()
		show_element()

#endregion SIGNAL HANDLERS

#region DISPLAY

func _update_display() -> void:
	if not _in_dungeon or not _inventory:
		hide_immediately()
		return

	if key_texture:
		key_texture.visible = true
	if key_quantity_display:
		var qty := _inventory.get_quantity(_get_item_id(ItemID.KEY))
		key_quantity_display.text = str(qty)
		key_quantity_display.add_theme_color_override("default_color", key_color_positive if qty > 0 else key_color_zero)

	if boss_key_texture:
		boss_key_texture.self_modulate.a = 1.0 if _inventory.has_item(_get_item_id(ItemID.BOSS_KEY)) else 0.0
	if journal_texture:
		journal_texture.self_modulate.a  = 1.0 if _inventory.has_item(_get_item_id(ItemID.JOURNAL))  else 0.0
	if map_texture:
		map_texture.self_modulate.a      = 1.0 if _inventory.has_item(_get_item_id(ItemID.MAP))       else 0.0

#endregion DISPLAY

#region VISIBILITY OVERRIDES

func force_show(should_force : bool) -> void:
	if should_force and not _in_dungeon:
		return
	super.force_show(should_force)

func _can_fade_out() -> bool:
	return true

#endregion VISIBILITY OVERRIDES

#endregion FUNCTIONS
