##[b][color=red]playerUX[/color][/b] is primarily used to feed variable values to other entities within the player ui.
class_name PlayerUX
extends Control

#region SIGNALS

## A signal emitted to all UX elements ten times per second (instead of every frame) to check for UX overlaps.
signal check_ux_overlap
signal check_viewport_size

#endregion SIGNALS

#region VARIABLES
@export_group("PlayerUX External Components")
## a reference to the main player node.
@export var root : Player
## a reference to the player's character body 2D.
@onready var player : CharacterBody2D = root.body
## a reference to the player's camera
@onready var player_cam : PlayerCam = root.player_cam
## a reference to the player's input component
@export var input : PlayerInputComponent
@export_group("Player UX Internal Components")
## a reference to the heart container
@export var heartsContainer : HeartsDisplay
## a reference to the audio control node for player UI
@export var ui_audio : UIAudioControl
## a reference to the context button's text label (Button 4 Label)
@export var context_label : ContextLabel
## a reference to the dialogue controller
@export var dialogue_controller : DialogueUI

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
	
	#Set maximum hearts
	var hp_component : PlayerHealthComponent = root.health
	heartsContainer.set_max_hearts(hp_component.max_hearts)
	heartsContainer.update_hearts(hp_component.cur_health)
	hp_component.healthChanged.connect(_on_health_changed)
	#Calls the margin update on player UX launch.
	check_viewport_size.emit()

func _on_health_changed(new_hp, _max_hp, _change):
	heartsContainer.update_hearts(new_hp)
#endregion FUNCTIONS
