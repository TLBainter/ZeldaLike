##[b][color=red]DialogueUI[/color][/b] is used to control the display of text, audio playing, button advancement, and more.
class_name DialogueUI
extends Control

#region SIGNALS

##Emitted when the dialogue UI finishes and closes.[br]
##THe Interact node associated listens for this to emit its own interaction_finished signal that states listen for.
signal dialogue_closed

#endregion SIGNALS

#region VARIABLES
@export_category("Dialogue Components")
@export var root : PlayerUX
##A reference to the text label.
@export var dialogue_label : Label
##A reference to the name display for the speaking character.
@export var char_name : Label
##A reference to the character icon display.
@export var char_icon : TextureRect

@export_category("Dialogue Settings")
##How fast text will scroll.
@export var text_speed : float = 30.0
##The range of pitch and tempo for the voice blips that play as text advances.[br]
##Higher values create a broader range.
@export var voice_range : float = 0.1

#region STATE
##The current number of lines in the dialogue
var _current_lines : Array[String] = []
##The line currently being typed
var _current_line_index : int = 0
##A reference to the speak component in use
var _active_speak_component : SpeakComponent
##A reference to the character resource in use
var _current_character_res : CharacterResource
## a reference to the player's input component
var _connected_input : PlayerInputComponent
#endregion STATE
#region PROCESS
##How many characters can currently be seen in the text
var _visible_chars : float = 0.0
##The total number of characters to be displayed
var _total_chars : int = 0
##The last character in the list of characters that was typed
var _last_played_char_index : int = -1
##Whether or not we are currently adding characters to the label
var _is_typing : bool = false
#endregion PROCESS

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	initialize(false)

##Whether or not you want to display the dialogue and have text run.
func initialize(init : bool):
	visible = init
	set_process(init)

func _on_input_received(btn : String):
	match btn:
		"actionButton1":
			advance()
		"actionButton2":
			advance()

func start_dialogue(data : Dictionary, input_comp : PlayerInputComponent = null):
	if data.is_empty():
		return
	
	_current_lines = data["lines"]
	_current_character_res = data["character"]
	_active_speak_component = data.get("source_component")
	_current_line_index = 0
	if _current_character_res:
		char_name.text = _current_character_res.display_name
		char_icon.texture = _current_character_res.icon
	if input_comp:
		_connected_input = input_comp
		if not _connected_input.action_button_pressed.is_connected(_on_input_received):
			_connected_input.action_button_pressed.connect(_on_input_received)
	initialize(true)
	_show_next_line()

func _show_next_line():
	if _current_line_index >= _current_lines.size():
		_end_dialogue()
		return
	var line_text = _current_lines[_current_line_index]
	if textResolver:
		line_text = textResolver.resolve(line_text)
	dialogue_label.text = line_text
	_visible_chars = 0.0
	_total_chars = line_text.length()
	_last_played_char_index = -1
	dialogue_label.visible_characters = 0
	_is_typing = true
	set_process(true)

##Advance to the next line. Can be used to interrupt typing first.
func advance():
	if _is_typing:
		_finish_typing()
	else:
		_current_line_index += 1
		if _current_line_index >= _current_lines.size():
			_end_dialogue()
		else:
			_show_next_line()

func _play_voice_blip():
	if not _current_character_res or _current_character_res.voice.is_empty():
		return
	
	if root and root.ui_audio:
		var blip = _current_character_res.voice.pick_random()
		var pitch = randf_range(1.0 - voice_range, 1.0 + voice_range)
		root.ui_audio.play_voice_blip(blip, pitch)
	
func _process(delta : float):
	if not _is_typing:
		set_process(false)
		return
	_visible_chars += text_speed * delta
	var current_int_chars = int(_visible_chars)
	dialogue_label.visible_characters = current_int_chars
	if current_int_chars > _last_played_char_index:
		_play_voice_blip()
		_last_played_char_index = current_int_chars
	
	if _visible_chars >= _total_chars:
		_finish_typing()

func _finish_typing():
	_is_typing = false
	dialogue_label.visible_ratio = 1.0
	set_process(false)

##Finish the dialogue entirely
func _end_dialogue():
	if _connected_input and _connected_input.action_button_pressed.is_connected(_on_input_received):
		_connected_input.action_button_pressed.disconnect(_on_input_received)
		_connected_input = null
	initialize(false)
	if _active_speak_component:
		_active_speak_component.dialogue_finished()
	if root and root.root:
		root.root.freeze_input(false)
		dialogue_closed.emit()


#endregion FUNCTIONS
