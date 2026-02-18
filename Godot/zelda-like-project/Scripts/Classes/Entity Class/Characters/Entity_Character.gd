##[b][color=red]Character[/color][/b] is a subclass of the [b][color=yellow]EntityClass[/color][/b] class.[br]
##This class encompasses [b]NPCs[/b], [b]Enemies[/b], and even the [b]Player[/b].
class_name Character
extends EntityClass

#region VARIABLES
#region COMPONENTS
@export_group("Character Components")
##the character's body
@export var body : CharacterBody2D
##the navigation agent for the character
@export var nav_agent : NavigationAgent2D
#endregion
#region EXPORT VARIABLES
@export_group("Misc Character Variables")
##the move speed of the character
#TODO: Test and confirm these move speeds.
@export_enum("Slow:30", "Normal:50", "Fast:75") var move_speed : int = int("Normal:50")
#endregion
#region INTERNAL VARIABLES
##the character's subtype; this is defined by its next subclass.
var subtype : String
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	type = "Character"
