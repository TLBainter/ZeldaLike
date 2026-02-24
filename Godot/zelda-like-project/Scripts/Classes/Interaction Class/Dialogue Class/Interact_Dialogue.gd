##[b][color=red]Dialogue[/color][/b] handles all dialogue a character has at their disposal,[br]
##moving through the dialogue as directed. Numerous dialogue controls are available.
class_name Dialogue
extends Interact

#region VARIABLES
@export_category("Dialogue Settings")
@export var conversation_id : String = "greeting"
#endregion VARIABLES

#region FUNCTIONS
func _init():
	context_key = "npc"

func interact():
	if debug_me:
		print("DEBUG: You're speaking with conversation ID: ", conversation_id)

#endregion FUNCTIONS
