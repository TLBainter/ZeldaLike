##Boss character with two phases and health bar display.
class_name Boss
extends Enemy

#region VARIABLES
#region COMPONENTS
@export_group("Boss Components")
@export var health_bar : Panel
@export var phase_transition : float
@export var death_trigger : String

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "Boss"
