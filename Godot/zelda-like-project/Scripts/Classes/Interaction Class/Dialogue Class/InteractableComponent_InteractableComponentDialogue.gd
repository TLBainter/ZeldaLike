##[b][color=red]InteractableComponentDialogue[/color][/b] is a pluggable dialogue interaction zone.[br]
##Extends [b]InteractableComponent[/b] with dialogue-specific logic.[br]
##[br]
##Assign a [b]SpeakComponent[/b] and place this as a child of the entity.[br]
##The [b]interact_type[/b] is fixed to [b]DIALOGUE[/b] (context key: "npc").
@tool
class_name InteractableComponentDialogue
extends InteractableComponent

#region EXPORTS
@export_group("Dialogue Settings")
##The speak component that holds this entity's dialogue sequences.
@export var speaker: SpeakComponent
#endregion

#region FUNCTIONS

func _ready() -> void:
	interact_type = InteractType.DIALOGUE
	super._ready()

##Starts dialogue with [param user] (expected to be a [Player]).[br]
##Connects [b]dialogue_closed[/b] -> [b]interaction_finished[/b] via ONE_SHOT.
func interact(user: EntityClass = null) -> void:
	if not speaker:
		push_error(name + ": no SpeakComponent assigned")
		return
	var data = speaker.start_interaction()
	if data.is_empty():
		return
	if user is Player and user.player_ux and user.player_ux.dialogue_controller:
		var dc = user.player_ux.dialogue_controller
		dc.start_dialogue(data, user.input)
		if not dc.dialogue_closed.is_connected(_on_dialogue_closed):
			dc.dialogue_closed.connect(_on_dialogue_closed, CONNECT_ONE_SHOT)

func _on_dialogue_closed() -> void:
	interaction_finished.emit()

#endregion
