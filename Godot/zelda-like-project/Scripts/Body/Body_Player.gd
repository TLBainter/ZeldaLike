##[b][color=red]playerBody[/color][/b] is a class primarily used for easy detection.
class_name PlayerBody
extends Body

#region VARIABLES
@onready var root : Player = $".."
@onready var player_ux : PlayerUX = root.player_ux
@onready var context_label : ContextLabel = player_ux.context_label
@onready var input : PlayerInputComponent = root.input
var current_interactable : InteractableComponent = null
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#region INITIALIZE
	if player_ux == null:
		player_ux = root.player_ux
		if debug_me:
			print("player_ux was null and is now ", player_ux)
	if context_label == null:
		context_label = player_ux.context_label
		if debug_me:
			print("context_label was null and is now ", context_label)
	if input == null:
		input = root.input
		if debug_me:
			print("input was null and is now ", input)
	#endregion INTIALIZE

#endregion FUNCTIONS
