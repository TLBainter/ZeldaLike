##[b][color=red]DestructibleManager / destructibleManager[/color][/b] is an autoload that tracks which destructible
##objects have been destroyed (grass, pots, breakables).[br]
##Destroyed state is owned by [b]saveManager[/b] - this class only holds the runtime dict.[br]
##[b]saveManager[/b] writes and restores destroyed state as part of its save file.[br]
##[br]
##Use [b]is_destroyed(id)[/b] to query state and [b]mark_destroyed(id)[/b] to record a destruction.
extends StateTrackingManager

@export var config: ManagerConfig

##Emitted after an object is marked as destroyed. [b]saveManager[/b] connects to this to queue an auto-save.
signal destructible_destroyed(id: String)

#region LIFECYCLE

func _ready() -> void:
	if config:
		# Apply config settings as needed (scaffolding for future use)
		pass

#endregion LIFECYCLE

#region PUBLIC API

##Returns [b]true[/b] if the object with [param id] has been destroyed.
func is_destroyed(id: String) -> bool:
	return is_tracked(id)

##Marks the object with [param id] as destroyed and notifies [b]saveManager[/b] to queue a save.
func mark_destroyed(id: String) -> void:
	mark(id)
	destructible_destroyed.emit(id)

##Returns a copy of all destroyed object IDs. Called by [b]saveManager[/b] during [method save].
func get_all_destroyed() -> Dictionary:
	return get_all()

##Replaces the destroyed-objects dict. Called by [b]saveManager[/b] during [method load_game].
func restore_destroyed(data: Dictionary) -> void:
	restore(data)

##Clears all destroyed-object state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	super.clear()

#endregion PUBLIC API
