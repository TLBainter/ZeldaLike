##[b][color=red]Interactable[/color][/b] refers to any object that can be interacted with,[br]
##including switches, levers, pots, chests, etc.
class_name Interactable
extends Thing

#region VARIABLES
#region COMPONENTS
@export_group("Interactable Components")
##a reference to this Interactable's [b]Interact[/b] component.
@export var interact : Interact
#region EXPORT VARIABLES
@export_group("Interactable Variables")
##the signal that is to be sent with this entity is interacted with.
@export var signal_to_send : String
##the target(s) of the signal once it is sent.
@export var signal_target : Array[Noninteractable]
#endregion
#region INTERNAL VARIABLES
var category : String
#endregion

#region FUNCTIONS
#region READY
func _ready():
	super._ready()
	#establish variables
	subtype = "Interactable"
