##Tracks player items and quantities. Attach as child of Player node.
##Items identified by ItemID string constants. Quantity-based items track count.
##
##This class implements the [IInventory] contract, providing standard inventory operations.
class_name InventoryComponentPlayer
extends InventoryComponent

#region SIGNALS

signal inventory_changed(item_id : String, quantity : int)

#endregion SIGNALS

#region VARIABLES

@export var start_items : PackedStringArray = []

var _items : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	for item_id in start_items:
		add_item(item_id)

#region QUERY

func has_item(item_id : String) -> bool:
	return _items.has(item_id) and _items[item_id] > 0

func get_quantity(item_id : String) -> int:
	if _items.has(item_id):
		return _items[item_id]
	return 0

#endregion QUERY

#region ADD / REMOVE

func add_item(item_id : String, amount : int = 1) -> void:
	if item_id.is_empty() or item_id == null:
		push_warning("InventoryComponentPlayer.add_item: item_id is null or empty, skipping.")
		return
	if _items.has(item_id):
		_items[item_id] += amount
	else:
		_items[item_id] = amount
	inventory_changed.emit(item_id, _items[item_id])
	if debug_me:
		print(debug_name, ": Added ", amount, "x ", item_id, ". Total: ", _items[item_id])

func remove_item(item_id : String, amount : int = 1) -> int:
	if item_id.is_empty() or item_id == null:
		push_warning("InventoryComponentPlayer.remove_item: item_id is null or empty, skipping.")
		return 0
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

func set_quantity(item_id : String, quantity : int) -> void:
	if item_id.is_empty() or item_id == null:
		push_warning("InventoryComponentPlayer.set_quantity: item_id is null or empty, skipping.")
		return
	if quantity <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = quantity
	inventory_changed.emit(item_id, get_quantity(item_id))
	if debug_me:
		print(debug_name, ": Set ", item_id, " to ", quantity)

#endregion ADD / REMOVE

#region UTILITY

func get_all_items() -> Dictionary:
	return _items.duplicate()

func clear_inventory() -> void:
	_items.clear()
	if debug_me:
		print(debug_name, ": Inventory cleared.")

#endregion UTILITY

#endregion FUNCTIONS
