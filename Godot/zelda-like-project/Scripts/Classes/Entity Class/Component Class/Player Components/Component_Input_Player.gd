##[b][color=red]PlayerInputComponent[/color][/b] handles all input from the player character, sending signals based on input.
class_name PlayerInputComponent
extends InputComponent

#region CONSTANTS
const DPAD_BUTTONS : Array[String] = ["dPadUp", "dPadRight", "dPadDown", "dPadLeft"]
#endregion CONSTANTS

#region SIGNALS
#region Button Signals
##Signal for when one of the four action buttons is pressed (actionButton 1 - 4)
signal action_button_pressed(button : String)
##Signal for when one of the four DPad Directions is pressed (Up, Right, Down, or Left)
signal d_pad_pressed(index : int)
#endregion Button Signals
#region Cam Signals
##Signal when the cam up input is given
signal on_cam_move(cam_move_input : Vector2, cam_move_strength : float)


#endregion Cam Signals
#endregion SIGNALS

#region VARIABLES

@export_group("External Components")
##A reference to the pause menu's scene file.
@export var pause_menu_scene : PackedScene

#region Internal Variables
#region pause menu variables
var _pause_menu_instance : PauseMenu = null
#region Input References
const ACTION_BUTTONS = ["actionButton1", "actionButton2", "actionButton3", "actionButton4"]

#endregion VARIABLES

func _process(_delta):
	#region Move Input
	##handler for move input reception
	var move_input : Vector2 = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	if move_input.length() < 0.15:
		move_input = Vector2.ZERO
	##determines the strength of the move input
	var move_strength : float = move_input.length()
	on_move.emit(move_input, move_strength)
	if debug_me:
		print_rich(debug_name, ": [color=green][i]move emitted[/i][/color] input=[i]", move_input, "[/i] strength=[i]", move_strength, "[/i]")
	#endregion
	#region Cam Input
	##handler for camera move input reception
	var cam_move_input : Vector2 = Input.get_vector("camLeft", "camRight", "camUp", "camDown")
	##determines the strength of the camera move input
	var cam_move_strength : float = move_input.length()
	if cam_move_input != null and cam_move_input != Vector2(0.0, 0.0):
		on_cam_move.emit(cam_move_input, cam_move_strength)
		if debug_me:
			print_rich(debug_name, ": [color=green][i]cam_move emitted[/i][/color] input=[i]", cam_move_input, "[/i] strength=[i]", cam_move_strength, "[/i]")
	#endregion

func _unhandled_input(event : InputEvent):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			return
		_open_pause_menu()
	if not get_tree().paused:
		for action in ACTION_BUTTONS:
			if event.is_action_pressed(action):
				_action_button_press(action)
				break
		for i in range(DPAD_BUTTONS.size()):
				if event.is_action_pressed(DPAD_BUTTONS[i]):
					d_pad_pressed.emit(i + 1)
					break

#region Pause Menu

func _open_pause_menu():
	if not pause_menu_scene:
		return
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		_pause_menu_instance.open()
	else:
		_pause_menu_instance = pause_menu_scene.instantiate()
		get_tree().root.add_child(_pause_menu_instance)

#endregion PauseMenu

#region Button Press
#region Action Button handler
func _action_button_press(btn : String):
	action_button_pressed.emit(btn)

## Returns true if the given action button is currently held down.
func is_action_button_held(button: String) -> bool:
	return Input.is_action_pressed(button)

#endregion Action Button handler
#endregion Button Press
