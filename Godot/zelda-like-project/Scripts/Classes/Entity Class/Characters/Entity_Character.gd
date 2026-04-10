##[b][color=red]Character[/color][/b] is a subclass of the [b][color=yellow]EntityClass[/color][/b] class.[br]
##This class encompasses [b]NPCs[/b], [b]Enemies[/b], and even the [b]Player[/b].
class_name Character
extends EntityClass

#region VARIABLES
#region COMPONENTS
@export_group("Character Components")
##the character's body
@export var body : CharacterBody2D
##the area used for feet-based collision detection (e.g. trap damage targeting)
@export var foot_area : Area2D
##the navigation agent for the character
@export var nav_agent : NavigationAgent2D
#endregion
#region EXPORT VARIABLES
@export_group("Misc Character Variables")
## Current move speed. Set at runtime by movement states from StatsComponent.
var move_speed : float = 50.0
## True while the character is executing a dash or backstep (blocks MoveComponent velocity writes).
var is_dashing : bool = false
## True while the character is invulnerable and cannot receive damage.
var is_invulnerable : bool = false
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
	type = "Character"
