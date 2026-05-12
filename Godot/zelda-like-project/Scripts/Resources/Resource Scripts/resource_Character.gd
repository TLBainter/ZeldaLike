##Contains data for a single character, used to populate character info throughout entities.
##Includes display name, dialogue ID, icon, and voice sounds.
class_name CharacterResource
extends Resource

#region VARIABLES

@export_category("Settings")
@export_group("Dialogue Settings")
##The display name of the character
@export_subgroup("Dialogue Display")
@export var display_name : String = "Character's Name"
##The character's id for reference by the dialogue CSV. Add more in the [color=purple]resource_Dialogue_Character.gd[/color] file.
@export_enum("default", "test") var dialogue_id : String = "default"
##The icon that will display for the character when spoken to.
@export var icon : Texture2D
@export_subgroup("Dialogue Sound")
##An array of different sounds that may play at random when a letter is added to the displayed text string.
@export var voice : Array[AudioStream]

#endregion VARIABLES
