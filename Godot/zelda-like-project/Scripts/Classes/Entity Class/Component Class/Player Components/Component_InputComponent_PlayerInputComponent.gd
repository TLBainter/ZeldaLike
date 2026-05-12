##Handles all input from the player character, sends signals based on input.
class_name PlayerInputComponent
extends InputComponent

#region CONSTANTS
const DPAD_BUTTONS : Array[String] = ["dPadUp", "dPadRight", "dPadDown", "dPadLeft"]
const SPELL_BUTTON_SLOTS : Dictionary = {
	"actionButton1": 1,
	"actionButton2": 2,
	"actionButton3": 3
}
#endregion CONSTANTS

#region SIGNALS
#region Button Signals
signal action_button_pressed(button : String)
signal d_pad_pressed(index : int)
signal spell_cast_requested(slot : int, spell : MenuItemResource)
#endregion Button Signals
#region Cam Signals
signal on_cam_move(cam_move_input : Vector2, cam_move_strength : float)
#endregion Cam Signals
#endregion SIGNALS

#region VARIABLES

@export_group("External Components")
@export var pause_menu_scene : PackedScene
@export_group("Spell Integration")
@export var equipped_spells : EquippedSpellsComponent

#region Internal Variables
#region pause menu variables
var _pause_menu_instance : PauseMenu = null
#region Input References
const ACTION_BUTTONS = ["actionButton1", "actionButton2", "actionButton3", "actionButton4"]

#endregion VARIABLES

func _process(_delta):
	var move_input : Vector2 = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	if move_input.length() < 0.15:
		move_input = Vector2.ZERO
	var move_strength : float = move_input.length()
	on_move.emit(move_input, move_strength)
	if debug_me:
		print_rich(debug_name, ": [color=green][i]move emitted[/i][/color] input=[i]", move_input, "[/i] strength=[i]", move_strength, "[/i]")

	var cam_move_input : Vector2 = Input.get_vector("camLeft", "camRight", "camUp", "camDown")
	var cam_move_strength : float = move_input.length()
	if cam_move_input != null and cam_move_input != Vector2(0.0, 0.0):
		on_cam_move.emit(cam_move_input, cam_move_strength)
		if debug_me:
			print_rich(debug_name, ": [color=green][i]cam_move emitted[/i][/color] input=[i]", cam_move_input, "[/i] strength=[i]", cam_move_strength, "[/i]")

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
func _action_button_press(btn : String) -> void:
	if SPELL_BUTTON_SLOTS.has(btn) and equipped_spells:
		var slot : int = SPELL_BUTTON_SLOTS[btn]
		var spell : MenuItemResource = equipped_spells.get_spell(slot)
		if spell:
			spell_cast_requested.emit(slot, spell)
			return
	action_button_pressed.emit(btn)

func is_action_button_held(button: String) -> bool:
	return Input.is_action_pressed(button)

#endregion Button Press
