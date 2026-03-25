##[b][color=red]InventoryComponent[/color][/b] tracks which items the player has and how many.[br]
##Attach as a child of the Player node.[br]
##[br]
##Items are identified by their [b]ItemID[/b] string constants.[br]
##Quantity-based items (ingredients, concoctions) track count.[br]
##Non-quantity items (spells, dungeon items) are simply owned or not owned.
class_name InventoryComponentPlayer
extends InventoryComponent

#region SIGNALS

##Emitted when any item's ownership or quantity changes.[br]
##[b]item_id[/b]: The ItemID constant.[br]
##[b]quantity[/b]: The new quantity (1 for non-quantity items when owned, 0 when removed).
signal inventory_changed(item_id : String, quantity : int)

#endregion SIGNALS

#region VARIABLES

#=======INTERNAL VARIABLES=======#

##Stores all item data.[br]
##Format: { "item_id" : int quantity }[br]
##An item not in the dictionary means the player doesn't have it.
var _items : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

#region QUERY

##Returns whether the player has the given item (quantity > 0).
func has_item(item_id : String) -> bool:
	return _items.has(item_id) and _items[item_id] > 0

##Returns the quantity of the given item. Returns 0 if not owned.
func get_quantity(item_id : String) -> int:
	if _items.has(item_id):
		return _items[item_id]
	return 0

#endregion QUERY

#region ADD / REMOVE

##Adds a quantity of an item. For non-quantity items, use amount = 1.
func add_item(item_id : String, amount : int = 1) -> void:
	if _items.has(item_id):
		_items[item_id] += amount
	else:
		_items[item_id] = amount
	inventory_changed.emit(item_id, _items[item_id])
	if debug_me:
		print(debug_name, ": Added ", amount, "x ", item_id, ". Total: ", _items[item_id])

##Removes a quantity of an item. Clamps to 0.[br]
##Returns the actual amount removed.
func remove_item(item_id : String, amount : int = 1) -> int:
	if not _items.has(item_id):
		return 0
	var current = _items[item_id]
	var removed = mini(current, amount)
	_items[item_id] = current - removed
	if _items[item_id] <= 0:
		_items.erase(item_id)
	inventory_changed.emit(item_id, get_quantity(item_id))
	if debug_me:
		print(debug_name, ": Removed ", removed, "x ", item_id, ". Remaining: ", get_quantity(item_id))
	return removed

##Sets the quantity of an item directly. Use 0 to remove it.
func set_quantity(item_id : String, quantity : int) -> void:
	if quantity <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = quantity
	inventory_changed.emit(item_id, get_quantity(item_id))
	if debug_me:
		print(debug_name, ": Set ", item_id, " to ", quantity)

#endregion ADD / REMOVE

#region UTILITY

##Returns a copy of the full inventory dictionary.
func get_all_items() -> Dictionary:
	return _items.duplicate()

##Clears the entire inventory.
func clear_inventory() -> void:
	_items.clear()
	if debug_me:
		print(debug_name, ": Inventory cleared.")

#endregion UTILITY

#endregion FUNCTIONS
