##Base NPC class (Shopkeeper, Standard, and Story NPCs inherit from this).
class_name NPC
extends Character

#region VARIABLES
#region NPC COMPONENTS
@export_group("NPC Components")
@export var player_detector : Area2D
@export var interact : Interact
#endregion
#region MISC EXPORT VARIABLES
@export_group("Misc NPC Variables")
@export var npc_name : String
#endregion
#region INTERNAL VARIABLES
var category : String
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	subtype = "NPC"
	add_to_group("entities")
