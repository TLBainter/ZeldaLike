##[b][color=red]ButtonSprite[/color][/b] handles the button visuals in the UX.
class_name ButtonSprite
extends TextureRect

#region VARIABLES
@export_category("Components")
##A reference to the UI control node
@export var root : PlayerUX
##A reference to the player's input component
@onready var input : PlayerInputComponent = root.input
@export_category("Debug")
##Whether or not you want this entity to print to the debugger
@export var debug_me : bool = false
@export var debug_name : String = "Button"
#endregion VARIABLES
