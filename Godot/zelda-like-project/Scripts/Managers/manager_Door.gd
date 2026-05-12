##[b][color=red]DoorManager / doorManager[/color][/b] is an autoload that tracks which locked doors have been unlocked.[br]
##Unlocked state is owned by [b]saveManager[/b] - this class only holds the runtime dict.[br]
##[b]saveManager[/b] writes and restores unlocked state as part of its save file so all state is atomic.[br]
##[br]
##Use [b]is_unlocked(door_id)[/b] to query state and [b]mark_unlocked(door_id)[/b] to record an unlock.
extends StateTrackingManager

@export var config: ManagerConfig

##Emitted after a door is marked as unlocked. [b]saveManager[/b] connects to this to trigger an auto-save.
signal door_unlocked(door_id: String)

##Emitted after [method restore_unlocked] replaces the unlocked-door dict.[br]
##All [b]LockedDoor[/b] nodes listen to this and refresh their state on load.
signal doors_restored

#region LIFECYCLE

func _ready() -> void:
	if config:
		# Apply config settings as needed (scaffolding for future use)
		pass

#endregion LIFECYCLE

#region PUBLIC API

##Returns [b]true[/b] if the door with [param door_id] has been unlocked.
func is_unlocked(door_id: String) -> bool:
	return is_tracked(door_id)

##Marks the door with [param door_id] as unlocked and notifies [b]saveManager[/b] to persist.
func mark_unlocked(door_id: String) -> void:
	mark(door_id)
	door_unlocked.emit(door_id)

##Returns a copy of all unlocked door IDs. Called by [b]saveManager[/b] during [method save].
func get_all_unlocked() -> Dictionary:
	return get_all()

##Replaces the unlocked-door dict. Called by [b]saveManager[/b] during [method load_game].
func restore_unlocked(data: Dictionary) -> void:
	restore(data)
	doors_restored.emit()

##Clears all unlocked-door state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	super.clear()

#endregion PUBLIC API
