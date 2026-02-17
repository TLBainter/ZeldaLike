##[b][color=red]StoryNPC[/color][/b] is an extension of [b]Entity[/b]/[b]Character[/b]/[b]NPC[/b] used for story-related NPCs.[br]
##Characters of this type have quest triggers and more complex state machines.
class_name StoryNPC
extends NPC

#region VARIABLES
#region COMPONENTS
@export_group("Shopkeeper Components")
##a reference to the Node dialogue component of the NPC.
@export var dialogue : Dialogue
##a reference to the Node quest trigger component of the NPC.
@export var quest_triggers : QuestTriggers
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	category = "StoryNPC"
#endregion
#endregion
