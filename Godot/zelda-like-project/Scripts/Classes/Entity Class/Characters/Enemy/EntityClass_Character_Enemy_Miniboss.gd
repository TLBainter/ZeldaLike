##Miniboss character with death trigger and health bar display.
class_name Miniboss
extends Enemy

#region VARIABLES
#region COMPONENTS
@export_group("Miniboss Components")
@export var health_bar : Panel
@export var death_trigger : String

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "Miniboss"
