##NPC with an inventory from which wares or services can be purchased.
class_name Shopkeeper
extends NPC

#region VARIABLES
#region COMPONENTS
@export_group("Shopkeeper Components")
@export var inventory : InventoryComponent
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "Shopkeeper"
