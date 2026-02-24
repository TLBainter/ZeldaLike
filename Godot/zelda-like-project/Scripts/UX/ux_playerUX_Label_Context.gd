##[b][color=red]ContextLabel[/color][/b] controls the text that appears over Action Button 4 (Context Button).[br]
##Use this to display things like 'Roll' or 'Speak' in set contexts.
class_name ContextLabel
extends PlayerUXLabel

#region VARIABLES
@export_category("Context Components")
@export var anim_player : AnimationPlayer
@onready var player : PlayerBody = player_ux.me.body
@export_category("Context Settings")
@export_group("Defaults")
##The default text that appears on the context label.[br]
##Keep null unless you have a good reason for something else (such as for testing).
@export var default_context_text : String = ""
@export_group("Context Dictionary")
##A map of the different contexts; if a context value comes into this script with a match, it will change.[br]
##If it does not have a match, the context label will be set to the context value (capitalized)
var context_map : Dictionary = {
	"default" : "",
	"container" : "Open",
	"dodge" : "Roll",
	"door" : "Open",
	"locked" : "Unlock",
	"npc" : "Speak",
	"pickup" : "Lift",
	"roll" : "Roll",
	"secret" : "?",
	"shop" : "Shop",
	"throw" : "Throw",
	"usable" : "Use"
}
@export_group("Transition Settings")
##Text to be loaded into the context label
var _pending_text : String = ""

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#pivot_offset = size / 2.0
	text = default_context_text
	reset()

func set_context(context_key : String):
	var display_text : String = ""
	#Check if the context map has the correct key.
	#If it does not, then turn the incoming context into the text.
	if context_map.has(context_key):
		display_text = context_map[context_key]
	else:
		display_text = context_key.capitalize()
	update_label(display_text)

func update_label(new_text : String):
	if text == new_text:
		return
	_pending_text = new_text
	if anim_player:
		anim_player.play("flip")
	else:
		text = new_text

func swap_text():
	text = _pending_text
	#pivot_offset = size / 2.0

func context_refresh():
	if player.current_interactable != null:
		set_context(player.current_interactable.context_key)
	elif player.me.can_roll:
		set_context("roll")
	else:
		reset()

func reset():
	update_label(default_context_text)
	pass
	
#endregion FUNCTIONS
