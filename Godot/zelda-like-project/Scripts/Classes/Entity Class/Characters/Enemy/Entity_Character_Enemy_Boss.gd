##[b][color=red]Boss[/color][/b] is a character class stemming from [b]Entity[/b]/[b]Character[/b]/[b]Enemy[/b].[br]
##Bosses have two phases, triggered at a certain level of health loss, and a death trigger. They also display a health bar on the screen.
class_name Boss
extends Enemy

#region VARIABLES
#region COMPONENTS
@export_group("Boss Components")
##the boss's health bar; refers to a panel. Should be in the player UI.
@export var health_bar : Panel
##the percentage of the boss's health they must lose before transitioning to their second phase.
@export var phase_transition : float
##the death trigger signal sent to the scene.
@export var death_trigger : String

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "Boss"
