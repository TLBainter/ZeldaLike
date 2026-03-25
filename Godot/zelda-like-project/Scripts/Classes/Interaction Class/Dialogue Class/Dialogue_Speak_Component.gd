##[b][color=red]SpeakComponent[/color][/b] is the component used to set an entity's speech.[br]
##This determines what they say, what dialogues they have access to, how those dialogues switch, etc.
class_name SpeakComponent
extends Component

#region VARIABLES

@export_category("Dialogue Settings")
##An array of dialogues to use, using the DialogueSequence resource.
@export var dialogue_sequences : Array[DialogueSequence]

##The index of the currently active dialogue sequence in the array
var _active_sequence_index : int = 0

#endregion VARIABLES

#region FUNCTIONS

func start_interaction() -> Dictionary:
	if dialogue_sequences.is_empty():
		if debug_me:
			print(debug_name, ": No dialogue sequence assigned!")
		return{}
	var current_sequence = dialogue_sequences[_active_sequence_index]
	var ref_id = current_sequence.get_next_ref_id()
	if debug_me:
		print("SpeakComponent requesting ref_id: ", ref_id, " — exists in DB: ", dialogueDB._dialogue_library.has(ref_id))
	var dialogue_data = dialogueDB.get_dialogue_data(ref_id)
	#Set the source component for the dialogue controller.
	if dialogue_data.is_empty():
		if debug_me:
			printerr(debug_name, ": No dialogue data found for ref_id ", ref_id)
		return {}
	dialogue_data["source_component"] = self
	if debug_me:
		print(debug_name, " starting dialogue Ref ID: ", ref_id)
	return dialogue_data

func dialogue_finished():
	if dialogue_sequences.is_empty():
		return
	var current_sequence = dialogue_sequences[_active_sequence_index]
	if current_sequence.is_exhausted():
		match current_sequence.on_finish:
			#If the sequence is set to RETURN...
			"Return":
				pass
			#If the sequence is set to SWITCH...
			"Switch":
				_switch_sequence(current_sequence.target_switch_index)
			#If the sequence is set to SWITCH IF...
			"Switch IF":
				#TODO: Fill this out once quest system is established.
				var condition_met = false
				if condition_met:
					_switch_sequence(current_sequence.target_switch_index)
				
func _switch_sequence(new_index : int):
	if new_index >= 0 and new_index < dialogue_sequences.size():
		_active_sequence_index = new_index
		if debug_me:
			print(debug_name, " switched to dialogue sequence index: ", new_index)
	else:
		if debug_me:
			print(debug_name, " attempted (and failed) to switch to sequence index: ", new_index)
#endregion FUNCTIONS
