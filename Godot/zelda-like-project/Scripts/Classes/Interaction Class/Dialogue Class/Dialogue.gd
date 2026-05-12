##[b][color=red]DEPRECATED[/color][/b] -- Use [b]InteractableComponentDialogue[/b] instead.[br]
##This class is broken at runtime: [code]Interact[/code] assigns [code]self[/code] (an Area2D) to[br]
##[code]Body_Player.current_interactable[/code], which is typed [code]InteractableComponent[/code].[br]
##Will be removed once all scenes have been migrated.
class_name Dialogue
extends Interact

#region VARIABLES

@export_category("Dialogue Settings")
@export var parent : EntityClass
##The speak component of this dialogue
@export var speaker : SpeakComponent
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	push_error("Dialogue is deprecated. Use InteractableComponentDialogue instead.")

func _init():
	context_key = "npc"

func interact(user: EntityClass = null):
	if debug_me:
		print("Interact called by ", user)
	if not speaker:
		if debug_me:
			print("Speak Component not configured for ", debug_name)
			return

	var data = speaker.start_interaction()
	if data.is_empty():
		return
	if user is Player:
		if user.player_ux and user.player_ux.dialogue_controller:
			print("PLAYER UI FOUND, CONTROLLER IS: ", user.player_ux.dialogue_controller)
			var dc = user.player_ux.dialogue_controller
			dc.start_dialogue(data, user.input)
			if not dc.dialogue_closed.is_connected(_on_dialogue_closed):
				dc.dialogue_closed.connect(_on_dialogue_closed, CONNECT_ONE_SHOT)

##Relays the dialogue_closed signal as interaction_finished on this Interact entity.
func _on_dialogue_closed():
	interaction_finished.emit()
	
#endregion FUNCTIONS
