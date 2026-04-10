##[b][color=red]ContainerManager / containerManager[/color][/b] is an autoload that tracks which chests have been opened.[br]
##Opened state is persisted to disk so chests stay open across scene reloads and sessions.[br]
##[br]
##Use [b]is_opened(chest_id)[/b] to query state and [b]mark_opened(chest_id)[/b] to record an opening.
extends Node

#region CONSTANTS

const SAVE_PATH : String = "user://container_state.json"

#endregion CONSTANTS

#region VARIABLES

##Dictionary of opened chest IDs. Format: { chest_id (String) : true }
var _opened : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	_load()

##Returns [b]true[/b] if the chest with [param chest_id] has been opened.
func is_opened(chest_id : String) -> bool:
	return _opened.has(chest_id)

##Marks the chest with [param chest_id] as opened and saves to disk.
func mark_opened(chest_id : String) -> void:
	if chest_id.is_empty():
		push_warning("ContainerManager: mark_opened called with empty chest_id; skipping save.")
		return
	_opened[chest_id] = true
	_save()

#region PERSISTENCE

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("ContainerManager: could not open ", SAVE_PATH, " for writing.")
		return
	file.store_string(JSON.stringify(_opened))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("ContainerManager: could not open ", SAVE_PATH, " for reading.")
		return
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_opened = parsed
	else:
		push_error("ContainerManager: failed to parse ", SAVE_PATH, "; resetting state.")
		_opened = {}

#endregion PERSISTENCE

#endregion FUNCTIONS
