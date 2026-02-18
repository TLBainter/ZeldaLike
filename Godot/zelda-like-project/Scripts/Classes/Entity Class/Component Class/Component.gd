##[b][color=red]Component[/color][/b] is the parent of all component classes. Make sweeping changes here.
class_name Component
extends Node

#region VARIABLES
#region DEBUG VARIABLES
@export_group("Debug")
##whether or not you want this entity to be debugged
@export var debug_me : bool = false
##the name you want the editor to display when referencing this entity
@export var debug_name : String = "Component"
#endregion
#endregion
