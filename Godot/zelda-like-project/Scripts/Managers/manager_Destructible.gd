##[b][color=red]DestructibleManager / destructibleManager[/color][/b] is an autoload that tracks which destructible
##objects have been destroyed (grass, pots, breakables).[br]
##Destroyed state is owned by [b]saveManager[/b] — this class only holds the runtime dict.[br]
##[b]saveManager[/b] writes and restores [b]_destroyed[/b] as part of its save file.[br]
##[br]
##Use [b]is_destroyed(id)[/b] to query state and [b]mark_destroyed(id)[/b] to record a destruction.
extends Node

##Emitted after an object is marked as destroyed. [b]saveManager[/b] connects to this to queue an auto-save.
signal destructible_destroyed(id: String)

#region VARIABLES

##Dictionary of destroyed object IDs. Format: { id (String) : true }
var _destroyed: Dictionary = {}

#endregion VARIABLES

#region PUBLIC API

##Returns [b]true[/b] if the object with [param id] has been destroyed.
func is_destroyed(id: String) -> bool:
	return _destroyed.has(id)

##Marks the object with [param id] as destroyed and notifies [b]saveManager[/b] to queue a save.
func mark_destroyed(id: String) -> void:
	if id.is_empty():
		push_warning("DestructibleManager: mark_destroyed called with empty id; skipping.")
		return
	_destroyed[id] = true
	destructible_destroyed.emit(id)

##Returns a copy of all destroyed object IDs. Called by [b]saveManager[/b] during [method save].
func get_all_destroyed() -> Dictionary:
	return _destroyed.duplicate()

##Replaces the destroyed-objects dict. Called by [b]saveManager[/b] during [method load_game].
func restore_destroyed(data: Dictionary) -> void:
	_destroyed = data.duplicate()

##Clears all destroyed-object state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	_destroyed = {}

#endregion PUBLIC API
