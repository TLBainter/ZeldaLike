##[b][color=red]Player[/color][/b] is the player character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds holds the control data for the player.
class_name Player
extends Character

#region VARIABLES
#region NPC COMPONENTS
@export_category("Player Components")
##Stamina handler; excepts type [color=green]StaminaComponent[/color]
@export var stamina : StaminaComponent
##Input handler; expects type [color=green]InputComponent[/color]
@export var input : InputComponent
##A reference to the player UX element.
@export var player_ux : PlayerUX
##reference to the player's camera
@export var player_cam : PlayerCam
@export_category("Player Flags")
##Whether or not the player can currently roll
var can_roll : bool = true
##Whether or not the player can currently move
var can_move : bool = true
#endregion
#region MISC EXPORT VARIABLES
#
#endregion
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	subtype = "Player"
	input.actionButtonPressed.connect(_on_action_button_pressed)

func _on_action_button_pressed(btn):
	match btn:
		"actionButton4":
			print("button4")
		#TODO: Add action button 3 logic
		"actionButton3":
			print("button3")
		#TODO: Add action button 2 logic
		"actionButton2":
			print("button2")
		#TODO: Add action button 1 logic
		"actionButton1":
			print("button1")

#region ACTION BUTTON 4

#endregion ACTION BUTTON 4

#region INTERACTIVITY CONTROL
##Prevent the character from moving at all
func freeze_input(should_freeze : bool):
	input.set_physics_process(not should_freeze)
	if should_freeze:
		body.velocity = Vector2.ZERO
		if anim:
			anim.stop()
	can_move = (not should_freeze)
		
#endregion INTERACTIVITY CONTROL
