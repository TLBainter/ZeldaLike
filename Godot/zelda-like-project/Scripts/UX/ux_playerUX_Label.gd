##[b][color=red]PlayerUXLabel[/color][/b] is the base class for dynamic text that appears in the UI under the PlayerInGameCanvas
class_name PlayerUXLabel
extends Label

#region VARIABLES
@export_category("Label Components")
@export var player_ux : PlayerUX
@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "PlayerUXLabel"
#endregion VARIABLES

#region FUNCTIONS
##Updates the text of a label; can be overridden by child classes for more specific formatting.
func update_label(new_text : String):
	text = new_text
	if debug_me:
		print(debug_name, " label updated to: ")
		print("\t", new_text)
#endregion FUNCTIONS
