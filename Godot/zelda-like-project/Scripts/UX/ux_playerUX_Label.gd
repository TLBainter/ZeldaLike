##[b][color=red]PlayerUXLabel[/color][/b] is the base class for dynamic text that appears in the UI under the PlayerInGameCanvas
class_name PlayerUXLabel
extends Label

#region VARIABLES
@export_category("Label Components")
@export var root : PlayerUX
@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion VARIABLES

#region FUNCTIONS
##Updates the text of a label; can be overridden by child classes for more specific formatting.
func update_label(new_text : String):
	text = new_text
	if debug_me:
		print(debug_name, " label updated to: ")
		print("\t", new_text)
#endregion FUNCTIONS
