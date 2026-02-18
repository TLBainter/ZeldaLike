##[b][color=red]Entity Class[/color][/b] is the [i]Parent Class[/i] of all entities in the game.[br]
##Subclasses include [b][color=yellow]Character[/color][/b] and [b][color=yellow]Object[/color][/b]
class_name EntityClass
extends Node2D

#region VARIABLES
#region COMPONENTS
@export_group("Entity Components")
##a reference to the entity's self as 'me'
@export var me : Node2D
##the entity's animation player
@export var anim_player : AnimationPlayer
##the entity's initial sprite
@export var sprite : Sprite2D
##the entity's shadow sprite
@export var shadow : Sprite2D
##the entity's state machine
@export var state_machine : StateMachine
##the entity's collider
@export var collider : Area2D
@export_group("Entity Components : Functionality")
##Health handler; expects type [color=green]HealthComponent[/color]
@export var health : HealthComponent
##Movement handler; excepts type [color=green]MovementComponent[/color]
@export var move : MoveComponent

#endregion
#region EXPORT VARIABLES
@export_group("Misc Entity Variables")
##the entity's Maximum Hit Points
@export var max_hp : int
##controls the y-sort of this entity.
@export var y_sort : bool = true
##the weight of the entity; allows it to hold down certain switches and resist being knocked back.
#TODO: Test these weight values and adjust as needed
@export_enum("Light:10", "Average:30", "Heavy:60", "Immovable:100") var weight : int
#endregion
#region INTERNAL VARIABLES
##the entity's Current Hit Points; sets itself to max_hp by default
var current_hp : int = max_hp
##whether the entity can take damage; false by default
var damageable : bool = false
##the group this entity should be assigned to; this is assigned by its next tier subclass
var group : String
##the type of entity this is; assigned by its next tier subclass (character or object)
var type : String
#endregion
#region DEBUG VARIABLES
@export_group("Debug")
##whether or not you want this entity to be debugged
@export var debug_me : bool = false
##the name you want the editor to display when referencing this entity
@export var debug_name : String
#endregion
#endregion

func _ready():
	#set the y sort
	sprite.y_sort_enabled = y_sort
	#disable y sorting for shadows
	if shadow != null:
		shadow.y_sort_enabled = false
