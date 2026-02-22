##[b][color=red]playerUX[/color][/b] is primarily used to feed variable values to other entities within the player ui.
class_name PlayerUX
extends Control

#region SIGNALS

## A signal emitted to all UX elements ten times per second (instead of every frame) to check for UX overlaps.
signal check_ux_overlap

#endregion SIGNALS

#region VARIABLES
@export_group("PlayerUX External Components")
## a reference to the main player node.
@export var me : Player
## a reference to the player's character body 2D.
@onready var player : CharacterBody2D = me.body
@export_group("Child Controls")
##Controls the speed at which entities within Player UX fade out when the player is beneath them.
@export var player_detection_fadeout_speed : float = 5.0
##The minimum alpha value for the UI, even when fading.
@export var ux_min_alpha : float = 0.1
@export_group("PlayerUX Debug")
@export var debug_me : bool = false
@export var debug_me_verbose : bool = false
@export var debug_name : String = "Player UI"
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#Creates a timer for reference by other UX elements.
	#This timer ticks ten times per second, which is more efficient than Physics Process (every frame).
	var ux_check_timer = Timer.new()
	ux_check_timer.wait_time = 0.1
	ux_check_timer.autostart = true
	ux_check_timer.timeout.connect(check_ux_overlap.emit)
	add_child(ux_check_timer)
	if debug_me:
		print("ux_check_timer created!")
#endregion FUNCTIONS
