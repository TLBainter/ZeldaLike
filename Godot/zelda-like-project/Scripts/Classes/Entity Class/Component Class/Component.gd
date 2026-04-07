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
#endregion
