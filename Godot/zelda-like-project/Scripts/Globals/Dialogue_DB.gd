##[color=red][b]Dialogue Database/dialogueDB[/b][/color] is an autoload, global variable handling dialogue.[br]
##This reads the CSV file for dialogue and holds a dictionary of text lines.
extends Node

#region PATHS
const CSV_PATH : String = "res://External/DialogueCSV.csv"
const CHARACTER_PATH : String = "res://Scripts/Resources/Resource Files/Resources_Characters/"
#endregion PATHS

#region DATA STORAGE

##Stores dialogue
##Format: { Ref_ID (String) : { "char_id" : String, "lines" : Array[String] } }
var _dialogue_library : Dictionary = {}
##Stores character mappings between the character resources and the character ID column
##Format: {"character_name" : preload("res://Scripts/Resources/Resource Files/Resources_Characters/character_name.tres") }
var _character_registry : Dictionary = {}

#endregion DATA STORAGE

#region FUNCTIONS

func _ready():
	_load_character_resources()
	_parse_csv()

##Initiate character resources based on CSV and character folder path
func _load_character_resources():
	#reference to the directory where character resources are stored.
	var dir = DirAccess.open(CHARACTER_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".remap"):
				file_name = file_name.trim_suffix(".remap")
			if file_name.ends_with(".tres"):
				var char_res = load(CHARACTER_PATH + "/" + file_name) as CharacterResource
				if char_res:
					_character_registry[char_res.dialogue_id] = char_res
			file_name = dir.get_next()
	else:
		printerr("Dialogue Database could not open character folder at ", CHARACTER_PATH)

func _parse_csv():
	if not FileAccess.file_exists(CSV_PATH):
		printerr("Dialogue Database failed to open the Dialogue CSV at ", CSV_PATH)
		return
	
	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	
	var _headers = file.get_csv_line()
	
	while not file.eof_reached():
		#Set up rows
		var csv_row = file.get_csv_line()
		#Skip headers
		if csv_row.size() < 2:
			continue
		#Get ref id from first column
		var ref_id = csv_row[0]
		#Get char id from second column
		var char_id = csv_row[1]
		#Get lines from columns 3-8
		#TODO: Create translation system, which will use additional columns and assign a language to the lines based on the value of the column from which they were pulled.
		var lines : Array[String] = []
		for i in range(2, 8):
			if i < csv_row.size() and not csv_row[i].is_empty():
				lines.append(csv_row[i])
		
		#Actually creates the dialogue library from the CSV.
		_dialogue_library[ref_id] = {
			"char_id" : char_id,
			"lines" : lines
		}
		
func get_dialogue_data(ref_id : String) -> Dictionary:
	if _dialogue_library.has(ref_id):
		var entry = _dialogue_library[ref_id]
		#Set up the character resource for the dialogue.
		var char_res : CharacterResource = null
		if _character_registry.has(entry["char_id"]):
			char_res = _character_registry[entry["char_id"]]
		
		#provide the dictionary value for this dialogue resource.
		return {
			"character": char_res,
			"lines" : entry["lines"]
		}
	
	else:
		printerr("Dialogue Database: Reference ID ", ref_id, " not found in the database...")
		return {}
#endregion FUNCTIONS
