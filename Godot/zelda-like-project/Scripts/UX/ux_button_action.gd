##[b][color=red]ActionButtonSprite[/color][/b] handles the visuals of a button in the UI.[br]
##Used for the action buttons (A/B/X/Y, Up, Down, Right, Left, etc.)
class_name ActionButtonSprite
extends ButtonSprite

#region VARIABLES
@export_category("Components")
##A reference to this button's animation player
@export var anim_player : AnimationPlayer
@export_category("Settings")
##The action name this sprite represents
@export_enum("actionButton1", "actionButton2", "actionButton3", "actionButton4", "dPadUp", "dPadDown", "dPadRight", "dPadLeft") var action_name : String = "choose a button"
##The tint to show the button as when available
@export var available_tint : Color = Color(1, 1, 1, 1)
##the tint and visibility to apply when the button is unavailable
@export var unavailable_tint : Color = Color(0.5, 0.5, 0.5, 0.5)
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	if input:
		if debug_me:
			print("Got input component for button ", action_name)
		if not input.actionButtonPressed.is_connected(_on_action_button_pressed):
			input.actionButtonPressed.connect(_on_action_button_pressed)
		#TODO: Fix this logic; it may not always be true. Setting availability should happen outside of this script, being called by other entities.
		#Perhaps set_available should have a default state stored within itself.
		set_available(true)
	else:
		if debug_me:
			print("Could not get input component for button ", action_name)

func _on_action_button_pressed(btn : String):
	if btn == action_name:
		_play_press_anim()

func _play_press_anim():
	if anim_player:
		##Names the animation to play; it is imperative that this match the animation in the ActionButtonAnimator!
		var anim_to_play : String = action_name + "_press"
		if anim_player.has_animation(anim_to_play):
			anim_player.stop()
			anim_player.play(anim_to_play)
		elif debug_me:
			printerr("Animation not found: ", anim_to_play, " on button ", debug_name)

func set_available(active : bool):
	if active:
		modulate = available_tint
	else:
		modulate = unavailable_tint

#endregion FUNCTIONS
