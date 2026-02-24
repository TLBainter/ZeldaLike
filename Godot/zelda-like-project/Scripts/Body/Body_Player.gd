##[b][color=red]playerBody[/color][/b] is a class primarily used for easy detection.
class_name PlayerBody
extends Body

#region VARIABLES
@onready var me : Player = $".."
@onready var player_ux : PlayerUX = me.player_ux
@onready var context_label : ContextLabel = player_ux.context_label
@onready var input : PlayerInputComponent = me.input
var current_interactable : Interact = null
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#region INITIALIZE
	#INITIALIZE#
	if player_ux == null:
		player_ux = me.player_ux
		if debug_me:
			print("player_ux was null and is now ", player_ux)
	if context_label == null:
		context_label = player_ux.context_label
		if debug_me:
			print("context_label was null and is now ", context_label)
	if input == null:
		input = me.input
		if debug_me:
			print("input was null and is now ", input)
	#END INITIALIZE
	#endregion INTIALIZE

#endregion FUNCTIONS
