##Sogard title screen host. Owns the MenuState machine and routes between the title buttons, file select, new game flow and the settings screen.
class_name MainMenu
extends Control

#region VARIABLES
enum MenuState { TITLE, PRESS_TO_START, MENU, FILE_SELECT, NEW_GAME_FLOW, SETTINGS }

@export_category("Sounds")
@export var sound_back : AudioStream

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

@onready var _main_menu     : Control        = $CanvasLayer/MainMenu
@onready var _file_select   : FileSelect     = $CanvasLayer/FileSelect
@onready var _new_game_flow : NewGameFlow    = $CanvasLayer/NewGameFlow
@onready var _settings      : SogardSettings = $CanvasLayer/Settings
@onready var _nav           : SogardNavInput = $CanvasLayer/MainMenu/SogardNavInput
@onready var _screen_in     : SogardScreenIn = $CanvasLayer/MainMenu/ScreenIn
@onready var _continue_btn  : SogardButton   = $CanvasLayer/MainMenu/ContinueButton
@onready var _new_game_btn  : SogardButton   = $CanvasLayer/MainMenu/NewGameButton
@onready var _settings_btn  : SogardButton   = $CanvasLayer/MainMenu/SettingsButton
@onready var _quit_btn      : SogardButton   = $CanvasLayer/MainMenu/QuitButton
@onready var _embers        : Control        = $CanvasLayer/MainMenu/Embers

var _state         : MenuState = MenuState.TITLE
var _is_new_game   : bool = false
var _selected_slot : int = -1
var _suspended     : Array[SogardNavInput] = []
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	_main_menu.visible     = true
	_file_select.visible   = false
	_new_game_flow.visible = false
	_settings.visible      = false

	_continue_btn.disabled = not saveManager.has_any_save()
	_nav.initial_focus = _new_game_btn if _continue_btn.disabled else _continue_btn

	for btn : SogardButton in [_continue_btn, _new_game_btn, _settings_btn, _quit_btn]:
		btn.focus_entered.connect(_on_button_focused.bind(btn))
	_continue_btn.activated.connect(_on_continue_activated)
	_new_game_btn.activated.connect(_on_new_game_activated)
	_settings_btn.activated.connect(_on_settings_activated)
	_quit_btn.activated.connect(_on_quit_activated)
	_settings.back_requested.connect(_on_settings_back)
	if settingsManager:
		_settings.setting_changed.connect(settingsManager.on_settings_changed)
	_file_select.slot_selected.connect(_on_slot_selected)
	_new_game_flow.flow_confirmed.connect(_on_flow_confirmed)
	_new_game_flow.flow_cancelled.connect(_on_flow_cancelled)

	_state = MenuState.MENU
	_grab_default_focus.call_deferred()
	if debug_me:
		print_rich(debug_name, ": ready, continue enabled=", not _continue_btn.disabled)

func _unhandled_input(event: InputEvent) -> void:
	match _state:
		MenuState.FILE_SELECT:
			if event.is_action_pressed("ui_cancel"):
				if sound_back and audioManager: audioManager.play(sound_back, "UI")
				menuSfx.play_page_close()
				_file_select.visible = false
				_restore_title_focus()

func _on_continue_activated() -> void:
	if _state != MenuState.MENU:
		return
	_is_new_game = false
	_open_file_select()

func _on_new_game_activated() -> void:
	if _state != MenuState.MENU:
		return
	_is_new_game = true
	_open_file_select()

func _on_settings_activated() -> void:
	if _state != MenuState.MENU:
		return
	_open_settings()

func _on_quit_activated() -> void:
	if _state != MenuState.MENU:
		return
	get_tree().quit()

##Moves the ember specks onto the focused button.
func _on_button_focused(btn : SogardButton) -> void:
	_embers.position = btn.position
	if debug_me_verbose:
		print_rich(debug_name, ": focus ", btn.name)

func _open_file_select() -> void:
	menuSfx.play_page_open()
	_nav.active = false
	_main_menu.visible   = false
	_file_select.visible = true
	_file_select.open(_is_new_game)
	_state = MenuState.FILE_SELECT
	if debug_me:
		print_rich(debug_name, ": [color=cyan]file select[/color] new_game=", _is_new_game)

func _on_slot_selected(slot: int) -> void:
	_selected_slot = slot
	if saveManager.has_save(slot):
		menuSfx.play_confirm_start_game()
		saveManager.load_game(slot)
	elif _is_new_game:
		_file_select.visible   = false
		_new_game_flow.visible = true
		_new_game_flow.start(_selected_slot)
		_state = MenuState.NEW_GAME_FLOW
	else:
		return

func _on_flow_confirmed(char_name: String, difficulty: String) -> void:
	_new_game_flow.visible = false
	menuSfx.play_confirm_start_game()
	saveManager.start_new_game(_selected_slot, char_name, difficulty)

func _on_flow_cancelled() -> void:
	menuSfx.play_page_close()
	_new_game_flow.visible = false
	_file_select.visible   = true
	_file_select.open(_is_new_game)
	_state = MenuState.FILE_SELECT

##Hides the title, suspends every other SogardNavInput and hands input to the settings screen.
func _open_settings() -> void:
	menuSfx.play_page_open()
	_suspended = SogardNavInput.suspend_others(_settings.nav)
	_nav.active = false
	_main_menu.visible = false
	_settings.visible = true
	if settingsManager:
		_settings.set_values(settingsManager.get_all())
	_settings.set_active(true)
	_state = MenuState.SETTINGS
	if debug_me:
		print_rich(debug_name, ": [color=cyan]settings[/color]")

##Closes the settings screen, resumes the suspended navs and returns focus to the Settings button.
func _on_settings_back() -> void:
	if _state != MenuState.SETTINGS:
		return
	menuSfx.play_page_close()
	_settings.set_active(false)
	_settings.visible = false
	SogardNavInput.resume_others(_suspended)
	_suspended = []
	_main_menu.visible = true
	_nav.active = true
	_state = MenuState.MENU
	_settings_btn.grab_focus()
	_screen_in.play()
	if debug_me:
		print_rich(debug_name, ": [color=orange]settings closed[/color]")

##Shows the title again after file select and reactivates its nav, focusing the button that opened file select.
func _restore_title_focus() -> void:
	_main_menu.visible = true
	_nav.active = true
	_state = MenuState.MENU
	_continue_btn.disabled = not saveManager.has_any_save()
	_nav.initial_focus = _new_game_btn if _continue_btn.disabled else _continue_btn
	menuSfx.silence_nav()
	if _is_new_game or _continue_btn.disabled:
		_new_game_btn.grab_focus()
	else:
		_continue_btn.grab_focus()
	_screen_in.play()
	if debug_me:
		print_rich(debug_name, ": [color=orange]title[/color]")

func _grab_default_focus() -> void:
	if _state != MenuState.MENU:
		return
	var target : SogardButton = _new_game_btn if _continue_btn.disabled else _continue_btn
	menuSfx.silence_nav()
	target.grab_focus()

#endregion FUNCTIONS
