##[b][color=red]Shopkeeper[/color][/b] is an extension of [b]Entity[/b]/[b]Character[/b]/[b]NPC[/b] used for shops.[br]
##Characters with this type have assigned inventories from which wares or services can be purchased.
class_name Shopkeeper
extends NPC

#region VARIABLES
#region COMPONENTS
@export_group("Shopkeeper Components")
##a reference to the Node inventory component of the shopkeep.
@export var inventory : InventoryComponent
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "Shopkeeper"
