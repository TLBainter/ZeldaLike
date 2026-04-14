@icon("res://Editor Tools/Icons/icon_concoctionUse.svg")
##[b][color=red]ConcoctionItemUse[/color][/b] extends [b]ItemUseComponent[/b] for concoctions/salves.[br]
##Receives use requests, validates inventory and stacking rules,[br]
##then applies the concoction's immediate and ongoing effects to the player.[br]
##[br]
##Attach as a child of the Player node.
class_name ConcoctionItemUse
extends ItemUseComponent

#region VARIABLES

@export_category("Concoction Components")
##The player's inventory component for checking/consuming salves.
@export var inventory : InventoryComponent

#endregion VARIABLES

#region FUNCTIONS

##Attempts to use a concoction by its MenuItemResource.[br]
##Returns true if used successfully, false if blocked.[br]
##[br]
##Checks:[br]
##1. Player has at least 1 in inventory.[br]
##2. Item has an ItemFunction assigned.[br]
##3. If consumable and not stackable, no active effect of this type is running.
func use_concoction(item_resource : MenuItemResource) -> bool:
	if not item_resource:
		if debug_me:
			print(debug_name, ": No item resource provided!")
		return false
	var item_id = item_resource.item_id
	if item_id.is_empty():
		if debug_me:
			print(debug_name, ": Item has no item_id!")
		return false
	if not inventory or not inventory.has_item(item_id):
		if debug_me:
			print(debug_name, ": Player doesn't have ", item_id)
		return false
	var item_func = item_resource.item_function
	if not item_func:
		if debug_me:
			print(debug_name, ": ", item_id, " has no item_function!")
		return false
	if item_func is ItemFunctionConsumable:
		if not item_func.stackable and has_active_effect(item_id):
			if debug_me:
				print(debug_name, ": ", item_id, " already active and not stackable!")
			return false
	inventory.remove_item(item_id, 1)
	apply_effects(item_func, item_id)
	if debug_me:
		print(debug_name, ": Used concoction ", item_id, "!")
	return true

#endregion FUNCTIONS
