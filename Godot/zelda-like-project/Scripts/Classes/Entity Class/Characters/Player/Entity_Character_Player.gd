##[b][color=red]Player[/color][/b] is the player character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds holds the control data for the player.
class_name Player
extends Character

#region VARIABLES
#region NPC COMPONENTS
@export_group("Player Components")
##Stamina handler; excepts type [color=green]StaminaComponent[/color]
@export var stamina : StaminaComponent
##Input handler; expects type [color=green]InputComponent[/color]
@export var input : InputComponent
##A reference to the player UX element.
@export var player_ux : Control
#endregion
#region MISC EXPORT VARIABLES
#
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
	subtype = "NPC"
