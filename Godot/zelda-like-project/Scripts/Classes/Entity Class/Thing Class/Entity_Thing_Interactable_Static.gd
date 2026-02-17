##A [b][color=red]StaticInteractable[/color][/b] is an interactable that can be interacted with,[br]
##but [i]will not[/i] be moved by the player (though it can move itself).
class_name StaticInteractable
extends Interactable

#region VARIABLES
#region EXPORT VARIABLES
@export_group("Static Interactable Variables")
##whether or not this item is added to the player's inventory when interacted with.
@export var get_on_interact : bool = false
#TODO: make an 'item to add' variable once items are ready.
#endregion
#endregion

#region FUNCTIONS
#region READY
func _ready():
	super._ready()
	#establish variables
	category = "Static"
