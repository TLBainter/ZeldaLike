##[b][color=red]StandardNPC[/color][/b] is an extension of [b]Entity[/b]/[b]Character[/b]/[b]NPC[/b] used for most NPCs.[br]
##Characters with this type have assigned inventories from which wares or services can be purchased.
class_name StandardNPC
extends NPC

#region VARIABLES
#region COMPONENTS
@export_group("Standard NPC Components")

#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	category = "StandardNPC"
#endregion
#endregion
