##Array of dialogue strings from CSV, chained together by events.
class_name DialogueSequence
extends Resource

#region VARIABLES

@export_category("Dialogue Sequence Data")
## Corresponding Dialogue Ref from the CSV
@export var dialogue_refs : Array[String]
## How you want this array to be treated. Sequence will play the dialogue in order, Random will select a random ref from the list each time.
@export_enum("Sequential", "Random") var sequence_type : String = "Sequential"

@export_category("Exhaust Response")
##what happens when all lines in the ref have been seen?[br]
##[b]Return[/b] Stay in this dialogue sequence.[br]
##[b]Switch[/b] Switch to the specified dialogue sequence.[br]
##[b]Switch IF[/b] Switch to the specified dialogue sequence IF a specific condition is met.
@export_enum("Return", "Switch", "Switch IF") var on_finish : String = "Return"
##If you are switching, what dialogue in the speak component's array should we switch to?
@export var target_switch_index : int = 0
##If you are switching due to a specific condition, enter that condition here.[br]
##The condition should be a quest or event-related [b][color=red]bool[/b][/color] value.[br]
##The script will check whether that bool is true when dialogue is exhausted.
@export var condition_key : String = ""

##Tracks the current index of this instance of the dialogue sequence.
var _current_index : int = 0

#endregion VARIABLES

#region FUNCTIONS

func get_next_ref_id() -> String:
	if dialogue_refs.is_empty():
		return ""
	var ref_id = ""
	if sequence_type == "Random":
		ref_id = dialogue_refs.pick_random()
	else:
		ref_id = dialogue_refs[_current_index]
		if _current_index < dialogue_refs.size() - 1:
			_current_index += 1
	return ref_id

func is_exhausted() -> bool:
	if sequence_type == "Random":
		return false
	return _current_index >= dialogue_refs.size() - 1

#endregion FUNCTIONS
