## Interface contract for inventory components.
##
## Implement these methods in any class that acts as an inventory.
## This defines the expected API for accessing and modifying item collections.
class_name IInventory
extends Node

func has_item(item_id: String) -> bool:
	push_error("IInventory.has_item not implemented")
	return false

func get_quantity(item_id: String) -> int:
	push_error("IInventory.get_quantity not implemented")
	return 0

func add_item(item_id: String, quantity: int = 1) -> bool:
	push_error("IInventory.add_item not implemented")
	return false

func remove_item(item_id: String, quantity: int = 1) -> bool:
	push_error("IInventory.remove_item not implemented")
	return false
