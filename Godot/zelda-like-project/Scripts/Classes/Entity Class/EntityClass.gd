##[b][color=red]Entity Class[/color][/b] is the [i]Parent Class[/i] of all entities in the game.[br]
##Subclasses include [b][color=yellow]Character[/color][/b] and [b][color=yellow]Object[/color][/b]
class_name EntityClass
extends Node2D

#region VARIABLES
#region COMPONENTS
@export_group("Entity Components")
##a reference to the entity's self as 'root'
@export var root : Node2D
##the entity's animated sprite, if it has one.
@export var animated_sprite : AnimatedSprite2D
##the entity's initial sprite
@export var sprite : Sprite2D
##the entity's animation player.
@export var anim : AnimationPlayer
##the entity's shadow sprite
@export var shadow : Sprite2D
##the entity's state machine
@export var state_machine : StateCoordinator
##the entity's collider
@export var collider : CollisionShape2D
##the entity's audio controller
@export var audio : AudioControl
##the stats component for this entity, which provides data to many other components
@export var stats : StatsComponent
@export_group("Entity Components : Functionality")
##Health handler; expects type [color=green]HealthComponent[/color]
@export var health : HealthComponent
##Movement handler; excepts type [color=green]MovementComponent[/color]
@export var move : MoveComponent
##Optional interaction zone component; add an [b]InteractableComponent[/b] scene to make this entity interactable.
@export var interactable : InteractableComponent

#endregion
#region EXPORT VARIABLES
@export_group("Misc Entity Variables")
##controls the y-sort of this entity.
@export var y_sort : bool = true
#endregion
#region INTERNAL VARIABLES
##whether the entity can take damage; false by default
var damageable : bool = false
##the group this entity should be assigned to; this is assigned by its next tier subclass
var group : String
##the type of entity this is; assigned by its next tier subclass (character or object)
var type : String
#endregion
#region DEBUG VARIABLES
@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion
#endregion

func _ready():
	if sprite != null:
		sprite.y_sort_enabled = y_sort
	if animated_sprite != null:
		animated_sprite.y_sort_enabled = y_sort
	if shadow != null:
		shadow.y_sort_enabled = false
