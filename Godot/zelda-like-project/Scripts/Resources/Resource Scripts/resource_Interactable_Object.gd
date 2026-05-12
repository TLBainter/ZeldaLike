##Defines DynamicInteractable properties; allows sharing config across similar objects.
class_name InteractableObject
extends Resource

#region VARIABLES

@export_category("Interaction Capabilities")
@export_group("Object Interactions")
##Whether the player can break this object.
@export var breakable : bool = false
##Whether this object can be lifted by the player.
@export var liftable : bool = false
##Wheter this object can be thrown by the player.
@export var throwable : bool = false
##Whether this object can be pulled by the player.
@export var pullable : bool = false
##Whether this object can be pushed by the player.
@export var pushable : bool = false
##Whether this object can be 'punched' with the boxing gloves (or whatever that item ends up being called).
@export var punchable : bool = false
@export_group("Throw Settings")
##Base throw distance in pixels. Weight will reduce this.
@export var throw_distance : float = 120.0
##Throw speed in pixels per second.
@export var throw_speed : float = 150.0
##Peak height of the visual arc in pixels.
@export var throw_arc_height : float = 8.0

@export_category("Object Properties")
@export_group("Durability")
@export var durability : int = 1
@export_group("Material")
@export var material : ObjectMaterial

@export_category("Drop Table")
@export var drop_table : DropTable
#endregion VARIABLES

#region FUNCTIONS

#endregion FUNCTIONS
