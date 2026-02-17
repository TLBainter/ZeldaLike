##[b][color=red]Miniboss[/color][/b] is a character class stemming from [b]Entity[/b]/[b]Character[/b]/[b]Enemy[/b].[br]
##Minibosses have a death trigger, such as dropping an item or unlocking a door. They also display a health bar on the screen.
class_name Miniboss
extends Enemy

#region VARIABLES
#region COMPONENTS
@export_group("Miniboss Components")
##the miniboss's health bar; refers to a panel. Should be in the player UI.
#TODO: Create boss health bar panel
@export var health_bar : Panel
##the death trigger signal sent to the scene.
@export var death_trigger : String

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	category = "Miniboss"
