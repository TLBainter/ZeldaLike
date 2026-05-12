##[b][color=red]StateTrackingManager[/color][/b] is a base class for managers that track state using a[br]
##dictionary (such as doors, containers, and destructibles).[br]
##Subclasses override [b]_get_signal_name()[/b] to specify the signal to emit when state changes.[br]
##State is owned by [b]saveManager[/b] - this class only holds the runtime dict.[br]
class_name StateTrackingManager
extends Node

#region VARIABLES

##Internal dictionary for tracking state. Format: { id (String) : true }
var _state: Dictionary = {}

#endregion VARIABLES

#region VIRTUAL METHODS

#endregion VIRTUAL METHODS

#region PUBLIC API

##Returns [b]true[/b] if the item with [param id] is tracked.
func is_tracked(id: String) -> bool:
	return _state.has(id)

##Marks the item with [param id] as tracked. Subclasses emit their typed signal after calling this.
func mark(id: String) -> void:
	if id.is_empty():
		push_warning("StateTrackingManager.mark() called with empty id; skipping.")
		return
	_state[id] = true

##Returns a copy of all tracked IDs. Called by [b]saveManager[/b] during [method save].
func get_all() -> Dictionary:
	return _state.duplicate()

##Replaces the state dict. Called by [b]saveManager[/b] during [method load_game].
func restore(data: Dictionary) -> void:
	_state = data.duplicate()

##Clears all tracked state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	_state = {}

#endregion PUBLIC API
