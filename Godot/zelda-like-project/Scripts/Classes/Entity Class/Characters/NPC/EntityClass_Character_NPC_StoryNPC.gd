##Story-related NPC with quest triggers and complex state machines.
class_name StoryNPC
extends NPC

#region VARIABLES
#region COMPONENTS
@export_group("StoryNPC Components")
@export var dialogue : Dialogue
@export var quest_triggers : QuestTriggers
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	category = "StoryNPC"
#endregion
#endregion
