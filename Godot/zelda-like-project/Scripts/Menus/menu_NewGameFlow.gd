class_name NewGameFlow
extends Control

signal flow_confirmed(char_name: String, difficulty: String)
signal flow_cancelled()

@onready var _name_panel    : Panel          = $NameInputPanel
@onready var _name_input    : LineEdit       = $"NameInputPanel/VBoxContainer/NameInput"
@onready var _diff_panel    : Panel          = $DifficultyPanel
@onready var _confirm_panel : Panel          = $ConfirmPanel
@onready var _confirm_label : RichTextLabel  = $"ConfirmPanel/VBoxContainer/ConfirmLabel"

var _char_name  : String = ""
var _difficulty : String = ""

func _ready() -> void:
	var name_row    := $"NameInputPanel/VBoxContainer/ButtonRow"
	var diff_vbox   := $"DifficultyPanel/VBoxContainer"
	var confirm_row := $"ConfirmPanel/VBoxContainer/ButtonRow"

	var name_back    : Panel = name_row.get_node("BackButton")
	var name_confirm : Panel = name_row.get_node("ConfirmButton")
	var story_btn    : Panel = diff_vbox.get_node("StoryButton")
	var standard_btn : Panel = diff_vbox.get_node("StandardButton")
	var epic_btn     : Panel = diff_vbox.get_node("EpicButton")
	var diff_back    : Panel = diff_vbox.get_node("BackButton")
	var no_btn       : Panel = confirm_row.get_node("NoButton")
	var yes_btn      : Panel = confirm_row.get_node("YesButton")

	name_back.gui_input.connect(_on_name_back_input)
	name_confirm.gui_input.connect(_on_name_confirm_input)
	story_btn.gui_input.connect(_on_difficulty_input.bind("Story"))
	standard_btn.gui_input.connect(_on_difficulty_input.bind("Standard"))
	epic_btn.gui_input.connect(_on_difficulty_input.bind("Epic"))
	diff_back.gui_input.connect(_on_diff_back_input)
	no_btn.gui_input.connect(_on_confirm_no_input)
	yes_btn.gui_input.connect(_on_confirm_yes_input)

	var btns : Array[Panel] = [name_back, name_confirm, story_btn, standard_btn, epic_btn, diff_back, no_btn, yes_btn]
	for btn in btns:
		_make_btn_interactive(btn)

func start() -> void:
	_char_name  = ""
	_difficulty = ""
	_name_input.text   = ""
	_name_panel.visible    = true
	_diff_panel.visible    = false
	_confirm_panel.visible = false

func _on_name_confirm_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	var name_text : String = _name_input.text.strip_edges()
	if name_text.is_empty():
		return
	_char_name = name_text
	_name_panel.visible = false
	_diff_panel.visible = true

func _on_name_back_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	flow_cancelled.emit()

func _on_difficulty_input(event: InputEvent, difficulty: String) -> void:
	if not _is_left_click(event):
		return
	_difficulty = difficulty
	_confirm_label.text = "Begin as %s\non %s difficulty?" % [_char_name, _difficulty]
	_diff_panel.visible    = false
	_confirm_panel.visible = true

func _on_diff_back_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	_diff_panel.visible = false
	_name_panel.visible = true

func _on_confirm_yes_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	flow_confirmed.emit(_char_name, _difficulty)

func _on_confirm_no_input(event: InputEvent) -> void:
	if not _is_left_click(event):
		return
	flow_cancelled.emit()

func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton \
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
		and (event as InputEventMouseButton).pressed

func _make_btn_interactive(btn: Panel) -> void:
	for child in btn.get_children():
		if child is Control:
			(child as Control).mouse_filter = MOUSE_FILTER_IGNORE
	btn.mouse_entered.connect(func(): _tween_btn(btn, Color(1.3, 1.3, 1.3, 1.0)))
	btn.mouse_exited.connect(func():  _tween_btn(btn, Color.WHITE))

func _tween_btn(btn: Panel, color: Color) -> void:
	var tw := btn.create_tween()
	tw.tween_property(btn, "self_modulate", color, 0.1)
