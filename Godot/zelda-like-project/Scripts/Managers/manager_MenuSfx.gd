##Autoload that plays shared menu sounds. Requests are queued and flushed once per frame so duplicates collapse and special confirms override generic ones.
class_name MenuSfxManager
extends Node

const BUS_UI : StringName = &"UI"
const PRIORITY_CONFIRM : int = 0
const PRIORITY_CONFIRM_SPECIAL : int = 1

##Sound libraries used for each menu sound category.
@export var config : MenuSfxConfig = preload("res://Scripts/Resources/Resource Files/Resources_Sound Libraries/UX Libraries/ux_menu_sfx_config.tres")
##Prints each sound played at flush time.
@export var debug_me : bool = false
##Prints every queued and dropped request.
@export var debug_me_verbose : bool = false

var _flush_scheduled : bool = false
var _nav_silent_until_frame : int = -1
var _nav_pending : bool = false
var _confirm_library : SoundLibrary = null
var _confirm_priority : int = -1
var _page_library : SoundLibrary = null
var _slider_pending : bool = false
var _slider_bus : StringName = BUS_UI

##Queues the focus move sound. Dropped while nav is silenced.
func play_nav() -> void:
	if _is_nav_silent():
		_log_verbose("nav dropped (silenced)")
		return
	_nav_pending = true
	_schedule_flush()

##Queues the generic confirm sound.
func play_confirm() -> void:
	_queue_confirm(config.confirm if config else null, PRIORITY_CONFIRM)

##Queues the difficulty confirm sound. Overrides a generic confirm in the same frame.
func play_confirm_difficulty() -> void:
	_queue_confirm(config.confirm_difficulty if config else null, PRIORITY_CONFIRM_SPECIAL)

##Queues the start game confirm sound. Overrides a generic confirm in the same frame.
func play_confirm_start_game() -> void:
	_queue_confirm(config.confirm_start_game if config else null, PRIORITY_CONFIRM_SPECIAL)

##Queues the slider move sound on the given bus. Falls back to the UI bus when the bus is empty or missing.
func play_slider_move(bus : StringName) -> void:
	_slider_pending = true
	_slider_bus = bus
	_log_verbose("slider queued on " + String(bus))
	_schedule_flush()

##Queues the forward page transition sound and silences nav for this frame and the next.
func play_page_open() -> void:
	_queue_page(config.page_open if config else null)

##Queues the forward page transition sound for a page switch and silences nav for this frame and the next.
func play_page_switch() -> void:
	_queue_page(config.page_open if config else null)

##Queues the reversed page transition sound and silences nav for this frame and the next.
func play_page_close() -> void:
	_queue_page(config.page_close if config else null)

##Drops nav sounds for this frame and the next. Call before a programmatic grab_focus.
func silence_nav() -> void:
	_nav_silent_until_frame = Engine.get_process_frames() + 1
	_nav_pending = false
	_log_verbose("nav silenced until frame " + str(_nav_silent_until_frame))

##Plays a random sound from the library immediately. Does nothing when the library is null or empty.
func play_library(library : SoundLibrary, bus : StringName = BUS_UI) -> void:
	if library == null or library.sounds.is_empty():
		return
	var stream : AudioStream = library.sounds.pick_random()
	if stream == null:
		return
	var manager : Node = get_node_or_null(^"/root/audioManager")
	if manager == null:
		_log("audioManager missing")
		return
	manager.play(stream, String(bus))
	_log("played " + stream.resource_path + " on " + String(bus))

func _queue_confirm(library : SoundLibrary, priority : int) -> void:
	if priority > _confirm_priority:
		_confirm_library = library
		_confirm_priority = priority
		_log_verbose("confirm queued, priority " + str(priority))
	_schedule_flush()

func _queue_page(library : SoundLibrary) -> void:
	silence_nav()
	if _page_library == null:
		_page_library = library
		_log_verbose("page queued")
	_schedule_flush()

func _is_nav_silent() -> bool:
	return Engine.get_process_frames() <= _nav_silent_until_frame

func _schedule_flush() -> void:
	if _flush_scheduled:
		return
	_flush_scheduled = true
	_flush.call_deferred()

func _flush() -> void:
	if _confirm_library:
		play_library(_confirm_library)
	if _page_library:
		play_library(_page_library)
	if _nav_pending and not _is_nav_silent() and config:
		play_library(config.nav_move)
	elif _nav_pending:
		_log_verbose("nav dropped at flush")
	if _slider_pending and config:
		play_library(config.slider_move, _resolve_bus(_slider_bus))
	_reset_queue()

func _resolve_bus(bus : StringName) -> StringName:
	if bus == &"" or AudioServer.get_bus_index(bus) < 0:
		return BUS_UI
	return bus

func _reset_queue() -> void:
	_flush_scheduled = false
	_nav_pending = false
	_confirm_library = null
	_confirm_priority = -1
	_page_library = null
	_slider_pending = false
	_slider_bus = BUS_UI

func _log(message : String) -> void:
	if debug_me or debug_me_verbose:
		print("[menuSfx] ", message)

func _log_verbose(message : String) -> void:
	if debug_me_verbose:
		print("[menuSfx] ", message)
