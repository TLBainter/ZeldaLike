##[b][color=red]NPC[/color][/b] is a character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds [b]Shopkeepers[/b], [b]Standard NPCs[/b], and [b]Story NPCs[/b].
class_name NPC
extends Character

#region VARIABLES
#region NPC COMPONENTS
@export_group("NPC Components")
##the area within which the player is detected.
@export var player_detector : Area2D
##the component with which the player may interact
@export var interact : Interact
#endregion
#region MISC EXPORT VARIABLES
@export_group("Misc NPC Variables")
##the NPC's name as it will be displayed
@export var npc_name : String
#endregion
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	subtype = "NPC"
	add_to_group("entities")
