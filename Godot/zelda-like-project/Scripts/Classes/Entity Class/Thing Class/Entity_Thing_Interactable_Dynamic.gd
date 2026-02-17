##A [b][color=red]DynamicInteractable[/color][/b] is an interactable that can be interacted with,[br]
##in multiple ways, including breaking, damaging, lifting, throwing, etc.
class_name DynamicInteractable
extends Interactable

#region VARIABLES
#region EXPORT VARIABLES
@export_group("Dynamic Interactable Variables")
##Whether this entity can be destroyed by the player.
@export var breakable : bool = false
##Whether this entity can be lifted by the player.
@export var liftable : bool = false
##Whether this entity can be thrown by the player.
@export var throwable : bool = false
##Whether this entity can be pushed by the player.
@export var pushable : bool = false
##Whether this entity can be pulled by the player.
@export var pullable : bool = false
##Things this entity may drop when destroyed.
@export var drop_table : DropTable
#endregion
#endregion

#region FUNCTIONS
#region READY
func _ready():
	super._ready()
	#establish variables
	category = "Dynamic"
#endregion
#endregion
