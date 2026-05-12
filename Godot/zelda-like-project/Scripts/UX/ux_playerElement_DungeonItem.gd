class_name DungeonItemDisplay
extends "res://Scripts/UX/ux_playerElement_ComponentDisplay.gd"

#region CONSTANTS

const DUNGEON_ITEMS: Array = [ItemID.KEY, ItemID.MAP, ItemID.JOURNAL, ItemID.BOSS_KEY]

#endregion CONSTANTS

#region VARIABLES

@export_category("Components")
@export var root : PlayerUX
@export var dungeon_registry : DungeonRegistry
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

var _inventory
var _in_dungeon : bool = false
var _dungeon_name : String = ""

#endregion VARIABLES

#region FUNCTIONS

func initialize(inventory, root_ux : PlayerUX) -> void:
	_inventory = inventory
	root = root_ux
	initialize_component_display(inventory)
	SignalUtil.safe_connect(SceneTransitionManager, "transition_complete", Callable(self, "_on_transition_complete"))
	_refresh_dungeon_state()

func _connect_component_signals(_component: Node) -> void:
	SignalUtil.safe_connect(_inventory, "inventory_changed", Callable(self, "_on_inventory_changed"))

func _refresh_display() -> void:
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
	if _dungeon_name.is_empty():
		push_warning("DungeonItemDisplay: _dungeon_name is empty, item ID will be invalid.")
		return ""
	var prefix := _dungeon_name
	if dungeon_registry:
		prefix = dungeon_registry.get_prefix(_dungeon_name)
	return prefix + "_" + base_id

#endregion DUNGEON STATE

#region SIGNAL HANDLERS

func _on_transition_complete() -> void:
	_refresh_dungeon_state()
	if _in_dungeon:
		show_element()

func _on_inventory_changed(item_id : String, _quantity : int) -> void:
	if not _in_dungeon:
		return
	var relevant := []
	for base_id in DUNGEON_ITEMS:
		relevant.append(_get_item_id(base_id))
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
		var qty: int = _inventory.get_quantity(_get_item_id(ItemID.KEY))
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
