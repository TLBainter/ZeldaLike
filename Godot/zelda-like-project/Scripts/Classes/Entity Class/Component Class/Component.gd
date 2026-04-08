##[b][color=red]Component[/color][/b] is the parent of all component classes. Make sweeping changes here.
class_name Component
extends Node

#region VARIABLES
#region DEBUG VARIABLES
@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion
#endregion

#region FUNCTIONS
## Walks up the scene tree and returns the first ancestor that is an EntityClass.
## Use this instead of hard-coded paths like $"../.." to resolve the owning entity.
func _find_entity_parent() -> EntityClass:
	var p := get_parent()
	while p:
		if p is EntityClass:
			return p
		p = p.get_parent()
	return null

## Returns the [StatsResource] from the owning entity, or null if unavailable.
## Convenience wrapper around [method _find_entity_parent] that also validates the stats chain.
func _get_entity_stats() -> StatsResource:
	var entity = _find_entity_parent()
	if entity and "stats" in entity and entity.stats and entity.stats.resource:
		return entity.stats.resource
	return null

##Prints [b]msg[/b] prefixed with [b]debug_name[/b] when [b]debug_me[/b] is enabled.
func _debug_log(msg: String) -> void:
	if debug_me:
		print_rich(debug_name, ": ", msg)

##Prints [b]msg[/b] prefixed with [b]debug_name[/b] when [b]debug_me_verbose[/b] is enabled.
func _debug_verbose(msg: String) -> void:
	if debug_me_verbose:
		print_rich(debug_name, ": ", msg)
#endregion
