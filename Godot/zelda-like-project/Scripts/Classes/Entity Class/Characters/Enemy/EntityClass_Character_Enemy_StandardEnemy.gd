##[b][color=red]StandardEnemy[/color][/b] is a character class stemming from [b]Entity[/b]/[b]Character[/b]/[b]Enemy[/b].[br]
##Standard Enemies are the most common enemy type. They patrol, chase, and attack the player.
class_name StandardEnemy
extends Enemy

#region VARIABLES
#region COMPONENTS
@export_group("Enemy Components")
##the strategy employed by this enemy; affects weighting of different combat actions,[br]
##making them more or less likely to do specific things.
@export_enum("Balanced", "Defensive", "Aggressive") var strategy : String
##a collection of other standard enemies that could spawn in this entity's place.
@export var variants : Array[StandardEnemy]

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "Standard"
