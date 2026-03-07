##[b][color=red]Enemy[/color][/b] is a character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds [b]Bosses[/b], [b]Mini Bosses[/b], and [b]Standard Enemies[/b].
class_name Enemy
extends Character

#region VARIABLES
#region ENEMY COMPONENTS
@export_group("Enemy Components")
##the area within which the player is detected.
@export var player_detector : Area2D
#region MISC EXPORT VARIABLES
@export_group("Misc Enemy Variables")
##the NPC's name as it will be displayed
@export var enemy_name : String
#endregion
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	subtype = "Enemy"
	add_to_group("enemies")
