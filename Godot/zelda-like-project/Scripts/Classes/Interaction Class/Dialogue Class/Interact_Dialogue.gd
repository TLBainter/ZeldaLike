##[b][color=red]Dialogue[/color][/b] handles all dialogue a character has at their disposal,[br]
##moving through the dialogue as directed. Numerous dialogue controls are available.
class_name Dialogue
extends Interact

#region VARIABLES

@export_category("Dialogue Settings")
##The speak component of this dialogue
@export var root : EntityClass
@export var speaker : SpeakComponent
#endregion VARIABLES

#region FUNCTIONS
func _init():
	context_key = "npc"

func interact(user = null):
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

#TODO: Add dialogue close animation.
##Relays the dialogue_closed signal as interaction_finished on this Interact entity.
func _on_dialogue_closed():
	#TODO: Put dialogue close animation and other elements here.
	interaction_finished.emit()
	
#endregion FUNCTIONS
