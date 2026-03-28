##[b][color=red]PlayerInputComponent[/color][/b] handles all input from the player character, sending signals based on input.
class_name PlayerInputComponent
extends InputComponent

#region CONSTANTS
const DPAD_BUTTONS : Array[String] = ["dPadUp", "dPadRight", "dPadDown", "dPadLeft"]
#endregion CONSTANTS

#region SIGNALS
#region Button Signals
##Signal for when one of the four action buttons is pressed (actionButton 1 - 4)
signal actionButtonPressed(button : String)
##Signal for when one of the four DPad Directions is pressed (Up, Right, Down, or Left)
signal dPadPressed(index : int)
#endregion Button Signals
#region Cam Signals
##Signal when the cam up input is given
signal onCamMove(cam_move_input : Vector2, cam_move_strength : float)


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
	if move_input != null:
		#emit the move signal if it has a value, providing the Vector2 and float values.
		onMove.emit(move_input, move_strength)
		if debug_me:
			print(debug_name, "	has emitted its move_input value with a value of ", move_input, "\n	and a move_strength value of ", move_strength)
	#endregion
	#region Cam Input
	##handler for camera move input reception
	var cam_move_input : Vector2 = Input.get_vector("camLeft", "camRight", "camUp", "camDown")
	##determines the strength of the camera move input
	var cam_move_strength : float = move_input.length()
	if cam_move_input != null and cam_move_input != Vector2(0.0, 0.0):
		#emit the camMove signal if it has a value, providing the Vector2 and float values.
		onCamMove.emit(cam_move_input, cam_move_strength)
		if debug_me:
			print(debug_name, "	has emitted its cam_move_input value with a value of ", cam_move_input, "\n	and a cam_move_strength value of ", cam_move_strength)
	#endregion

func _unhandled_input(event : InputEvent):
	#PAUSE BUTTON HANDLING#
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			return #NOTE: Pause Menu handles its own close input
		_open_pause_menu()
	#BUTTON HANDLING#
	if not get_tree().paused:
	#ACTION BUTTON HANDLING#
		for action in ACTION_BUTTONS:
			if event.is_action_pressed(action):
				_action_button_press(action)
				break
	#DPAD HANDLING
		for i in range(DPAD_BUTTONS.size()):
				if event.is_action_pressed(DPAD_BUTTONS[i]):
					dPadPressed.emit(i + 1)
					break

#region Pause Menu

func _open_pause_menu():
	if not pause_menu_scene:
		return
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		#Reuse existing instance.
		_pause_menu_instance.open()
	else:
		#First time — instantiate and keep reference.
		_pause_menu_instance = pause_menu_scene.instantiate()
		get_tree().root.add_child(_pause_menu_instance)

#endregion PauseMenu

#region Button Press
#region Action Button handler
func _action_button_press(btn : String):
	actionButtonPressed.emit(btn)

#endregion Action Button handler
#endregion Button Press
