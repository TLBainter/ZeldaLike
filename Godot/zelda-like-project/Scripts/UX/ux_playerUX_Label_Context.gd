##[b][color=red]ContextLabel[/color][/b] controls the text that appears over Action Button 4 (Context Button).[br]
##Use this to display things like 'Roll' or 'Speak' in set contexts.
class_name ContextLabel
extends PlayerUXLabel

#region VARIABLES
@export_category("Context Components")
@export var anim_player : AnimationPlayer
@onready var player : PlayerBody = root.root.body
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
	"drop"    : "Drop",
	"grab"    : "Grab",
	"lift"    : "Lift",
	"open"    : "Open",
	"roll"    : "Roll",
	"shop"    : "Shop",
	"speak"   : "Speak",
	"throw"   : "Throw",
	"use"     : "Use",
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
	#Connect to context label from the state machine.
	var coordinator = player.root.state_machine
	if coordinator and not coordinator.context_changed.is_connected(_on_context_changed):
		coordinator.context_changed.connect(_on_context_changed)
	#Connect animation_finished so post-swap clears chain into a new flip.
	if anim_player and not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)

func _on_context_changed(context_key : String):
	set_context(context_key)

func set_context(context_key : String):
	var display_text : String = ""
	#Check if the context map has the correct key.
	#If it does not, then turn the incoming context into the text.
	if context_map.has(context_key):
		display_text = context_map[context_key]
	else:
		display_text = context_key.capitalize()
	if debug_me:
		print(debug_name, ": set_context('", context_key, "') → display='", display_text, "'")
	update_label(display_text)

func update_label(new_text : String):
	# Compare against what we're GOING to show, not what's currently visible.
	# When a flip is in flight, _pending_text is the effective current target.
	var effective_text := _pending_text if (anim_player and anim_player.is_playing()) else text
	if effective_text == new_text:
		if debug_me:
			print(debug_name, ": update_label('", new_text, "') ; no change from effective '", effective_text, "', skipping")
		return
	if debug_me:
		print(debug_name, ": update_label('", new_text, "') ; was '", text, "' (pending '", _pending_text, "')", (" [flip animation]" if anim_player else ""))
	_pending_text = new_text
	if new_text.is_empty() and (not anim_player or not anim_player.is_playing()):
		# No animation in flight -- clear immediately without animating.
		text = ""
		return
	if anim_player:
		# If a flip is already running, just update _pending_text -- swap_text() will use it.
		# If we're in the post-swap reveal phase, _on_animation_finished will start a new
		# flip once the current animation completes, preventing the label from being
		# cut away before it becomes visible.
		if not anim_player.is_playing():
			anim_player.play("flip")
	else:
		text = new_text

func swap_text():
	if debug_me:
		print(debug_name, ": swap_text() ; displaying '", _pending_text, "'")
	text = _pending_text
	#pivot_offset = size / 2.0

##Called when the flip animation finishes.[br]
##If _pending_text differs from text (e.g., a clear arrived during the reveal phase),
##start another flip so the label transitions cleanly to the new value.
func _on_animation_finished(_anim_name : StringName):
	if text != _pending_text:
		if debug_me:
			print(debug_name, ": _on_animation_finished ; queuing flip '", text, "' → '", _pending_text, "'")
		anim_player.play("flip")

func reset():
	update_label(default_context_text)
	pass
	
#endregion FUNCTIONS
