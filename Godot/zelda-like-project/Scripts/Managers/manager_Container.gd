##[b][color=red]ContainerManager / containerManager[/color][/b] is an autoload that tracks which chests have been opened.[br]
##Opened state is owned by [b]saveManager[/b] — this class only holds the runtime dict.[br]
##[b]saveManager[/b] writes and restores [b]_opened[/b] as part of its save file so all state is atomic.[br]
##[br]
##Use [b]is_opened(chest_id)[/b] to query state and [b]mark_opened(chest_id)[/b] to record an opening.
extends Node

##Emitted after a container is marked as opened. [b]saveManager[/b] connects to this to trigger an auto-save.
signal container_opened(chest_id : String)

##Emitted after [method restore_opened] replaces the opened-chest dict.[br]
##All [b]InteractableComponentContainer[/b] nodes listen to this and refresh their visual state.
signal containers_restored

#region VARIABLES

##Dictionary of opened chest IDs. Format: { chest_id (String) : true }
var _opened : Dictionary = {}

#endregion VARIABLES

#region PUBLIC API

##Returns [b]true[/b] if the chest with [param chest_id] has been opened.
func is_opened(chest_id : String) -> bool:
	return _opened.has(chest_id)

##Marks the chest with [param chest_id] as opened and notifies [b]saveManager[/b] to persist.
func mark_opened(chest_id : String) -> void:
	if chest_id.is_empty():
		push_warning("ContainerManager: mark_opened called with empty chest_id; skipping.")
		return
	_opened[chest_id] = true
	container_opened.emit(chest_id)

##Returns a copy of all opened chest IDs. Called by [b]saveManager[/b] during [method save].
func get_all_opened() -> Dictionary:
	return _opened.duplicate()

##Replaces the opened-chest dict. Called by [b]saveManager[/b] during [method load_game].
func restore_opened(data : Dictionary) -> void:
	_opened = data.duplicate()
	containers_restored.emit()

##Clears all opened-chest state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	_opened = {}

#endregion PUBLIC API
