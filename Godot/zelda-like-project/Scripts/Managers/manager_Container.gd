##[b][color=red]ContainerManager / containerManager[/color][/b] is an autoload that tracks which chests have been opened.[br]
##Opened state is owned by [b]saveManager[/b] - this class only holds the runtime dict.[br]
##[b]saveManager[/b] writes and restores opened state as part of its save file so all state is atomic.[br]
##[br]
##Use [b]is_opened(chest_id)[/b] to query state and [b]mark_opened(chest_id)[/b] to record an opening.
extends StateTrackingManager

@export var config: ManagerConfig

##Emitted after a container is marked as opened. [b]saveManager[/b] connects to this to trigger an auto-save.
signal container_opened(chest_id : String)

##Emitted after [method restore_opened] replaces the opened-chest dict.[br]
##All [b]InteractableComponentContainer[/b] nodes listen to this and refresh their visual state.
signal containers_restored

#region LIFECYCLE

func _ready() -> void:
	if config:
		# Apply config settings as needed (scaffolding for future use)
		pass

#endregion LIFECYCLE

#region PUBLIC API

##Returns [b]true[/b] if the chest with [param chest_id] has been opened.
func is_opened(chest_id : String) -> bool:
	return is_tracked(chest_id)

##Marks the chest with [param chest_id] as opened and notifies [b]saveManager[/b] to persist.
func mark_opened(chest_id : String) -> void:
	mark(chest_id)
	container_opened.emit(chest_id)

##Returns a copy of all opened chest IDs. Called by [b]saveManager[/b] during [method save].
func get_all_opened() -> Dictionary:
	return get_all()

##Replaces the opened-chest dict. Called by [b]saveManager[/b] during [method load_game].
func restore_opened(data : Dictionary) -> void:
	restore(data)
	containers_restored.emit()

##Clears all opened-chest state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	super.clear()

#endregion PUBLIC API
