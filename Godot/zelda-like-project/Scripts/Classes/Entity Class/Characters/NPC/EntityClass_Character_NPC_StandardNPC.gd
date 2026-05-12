##Standard NPC with basic dialogue and interaction.
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
	category = "StandardNPC"
#endregion
#endregion
