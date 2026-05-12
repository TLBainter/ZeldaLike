class_name MainMenu
extends Control

enum MenuState { TITLE, PRESS_TO_START, MENU, FILE_SELECT, NEW_GAME_FLOW }

@onready var _main_menu    : Control         = $CanvasLayer/MainMenu
@onready var _title_card   : Panel           = $"CanvasLayer/MainMenu/Title Card"
@onready var _press_start  : Panel           = $"CanvasLayer/MainMenu/Press to Start Panel"
@onready var _anim         : AnimationPlayer = $CanvasLayer/MainMenu/TitleAnimPlayer
@onready var _continue_btn : Panel           = $"CanvasLayer/MainMenu/Main Menu Buttons Container/Continue Button"
@onready var _new_game_btn : Panel           = $"CanvasLayer/MainMenu/Main Menu Buttons Container/New Game Button"
@onready var _settings_btn : Panel           = $"CanvasLayer/MainMenu/Main Menu Buttons Container/Settings Button"
@onready var _quit_btn     : Panel           = $"CanvasLayer/MainMenu/Main Menu Buttons Container/Quit Button"
@onready var _file_select  : FileSelect      = $CanvasLayer/FileSelect
@onready var _new_game_flow: NewGameFlow     = $CanvasLayer/NewGameFlow

var _state         : MenuState = MenuState.TITLE
var _is_new_game   : bool  = false
var _selected_slot : int   = -1

func _ready() -> void:
	_main_menu.visible     = true
	_file_select.visible   = false
	_new_game_flow.visible = false

	var tm : Animation = _anim.get_animation(&"TitleMove")
	if tm:
		tm.loop_mode = Animation.LOOP_NONE

	_make_btn_interactive(_new_game_btn)
	_make_btn_interactive(_settings_btn)
	_make_btn_interactive(_quit_btn)

	if not saveManager.has_any_save():
		_continue_btn.self_modulate = Color(0.5, 0.5, 0.5, 1.0)
		_continue_btn.mouse_filter  = MOUSE_FILTER_IGNORE
	else:
		_make_btn_interactive(_continue_btn)

	_anim.play("TileScreen")
	var tw := create_tween()
	tw.tween_property(_title_card, "self_modulate:a", 1.0, 0.5)

	_anim.animation_finished.connect(_on_anim_finished)
	_continue_btn.gui_input.connect(_on_continue_input)
	_new_game_btn.gui_input.connect(_on_new_game_input)
	_settings_btn.gui_input.connect(_on_settings_input)
	_quit_btn.gui_input.connect(_on_quit_input)
	_file_select.slot_selected.connect(_on_slot_selected)
	_new_game_flow.flow_confirmed.connect(_on_flow_confirmed)
	_new_game_flow.flow_cancelled.connect(_on_flow_cancelled)

func _unhandled_input(event: InputEvent) -> void:
	match _state:
		MenuState.TITLE:
			if _is_any_press(event):
				var tw := create_tween()
				tw.tween_property(_press_start, "modulate:a", 1.0, 0.2)
				_state = MenuState.PRESS_TO_START
		MenuState.PRESS_TO_START:
			if event.is_action_pressed("pause"):
				if _anim.is_playing() and _anim.current_animation == &"TitleMove":
					_anim.seek(0.0, true)
					_anim.stop(true)
					_on_anim_finished(&"TitleMove")
				else:
					_anim.stop()
					_anim.play("TitleMove")
					_state = MenuState.MENU
		MenuState.MENU:
			if event.is_action_pressed("pause"):
				if _anim.is_playing() and _anim.current_animation == &"TitleMove":
					var tm := _anim.get_animation(&"TitleMove")
					_anim.seek(tm.length, true)
					_anim.stop(true)
				else:
					_anim.play_backwards("TitleMove")
					_state = MenuState.PRESS_TO_START
		MenuState.FILE_SELECT:
			if event.is_action_pressed("ui_cancel"):
				_file_select.visible = false
				_main_menu.visible   = true
				_state = MenuState.MENU

func _on_continue_input(event: InputEvent) -> void:
	if _state != MenuState.MENU or not _is_left_click(event):
		return
	_is_new_game = false
	_open_file_select()

func _on_new_game_input(event: InputEvent) -> void:
	if _state != MenuState.MENU or not _is_left_click(event):
		return
	_is_new_game = true
	_open_file_select()

func _on_settings_input(_event: InputEvent) -> void:
	pass

func _on_quit_input(event: InputEvent) -> void:
	if _state != MenuState.MENU or not _is_left_click(event):
		return
	get_tree().quit()

func _open_file_select() -> void:
	_main_menu.visible   = false
	_file_select.visible = true
	_file_select.open(_is_new_game)
	_state = MenuState.FILE_SELECT

func _on_slot_selected(slot: int) -> void:
	_selected_slot = slot
	if _is_new_game:
		_file_select.visible   = false
		_new_game_flow.visible = true
		_new_game_flow.start()
		_state = MenuState.NEW_GAME_FLOW
	else:
		saveManager.load_game(slot)

func _on_flow_confirmed(char_name: String, difficulty: String) -> void:
	_new_game_flow.visible = false
	saveManager.start_new_game(_selected_slot, char_name, difficulty)

func _on_flow_cancelled() -> void:
	_new_game_flow.visible = false
	_file_select.visible   = true
	_file_select.open(_is_new_game)
	_state = MenuState.FILE_SELECT

func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name != &"TitleMove":
		return
	if _state == MenuState.PRESS_TO_START:
		_anim.play("TileScreen")
		var tw := create_tween()
		tw.tween_property(_press_start, "modulate:a", 1.0, 0.2)

func _is_any_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		var ke := event as InputEventKey
		return ke.pressed and not ke.echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	return false

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
