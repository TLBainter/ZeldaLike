##[b][color=red]HeartsDisplay[/color][/b] is a script used to control the overall heart display in the player GUI.[br]
##Note that this [i]does not[/i] control things like individual heart state changes, player health, etc.
class_name HeartsDisplay
extends GridContainer

#region VARIABLES
@export_category("Hearts Display Components")
##A reference to the heart gui scene; make sure the scene has the playerHeartGUI panel as its parent and is of the HeartGUI class!
@export var heart_gui : PackedScene
##A reference to the main ui control node
@export var root : PlayerUX
##A reference to the audio control component in the player ux
@onready var ui_audio : UIAudioControl = root.ui_audio
var min_pulse_speed : float = 1.0
var max_pulse_speed : float = 1.2
@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion VARIABLES

#region FUNCTIONS

func set_max_hearts(max_hearts : int):
	for child in get_children():
		child.queue_free()
	for i in range(max_hearts):
		var heart = heart_gui.instantiate()
		add_child(heart)

func update_hearts(cur_health : int):

	##variable which gets the currently-active heart in the index
	var active_heart_index = int(ceil(cur_health / 4.0)) -1
	var hearts = get_children()
	var max_hp : int = int(hearts.size() * 4)
	##The threshold at which the hearts will start flashing due to low health[br]
	##Note that to prevent the value from being kept at 1 in the early game, it has a minimum of 4.[br]
	##This will ensure the last heart always flashes when it's the only one remaining!
	var low_hp_threshold : int = clampi(int(floor(max_hp * 0.25)), 4, 15)
	##How quickly the heart will pulse; affected by low health to sync with faster heartbeat sound
	var pulse_speed : float = 1.0
	##whether or not the character currently has low hp
	var hp_low : bool = (cur_health <= low_hp_threshold and cur_health > 0)
	ui_audio.update_low_health_loop(cur_health, low_hp_threshold)
	if hp_low and ui_audio:
		var ratio : float = float(cur_health) / float(low_hp_threshold)
		pulse_speed = lerp(max_pulse_speed, min_pulse_speed, ratio)
	if debug_me:
		print("Player has ", hearts.size(), " hearts")
		print("Player's max hp is ", max_hp)
		print("Player's low_hp_threshold is ", low_hp_threshold)
	for i in range(hearts.size()):
		##Gets and defines individual hearts for later use
		var individual_heart = hearts[i] as HeartGUI
		##the amount of 'fill' for a heart (0-4).[br]
		##used in ux_playerHearts_individualGUI to define the appearance of a given heart
		var heart_fill_value = clampi(cur_health - (i * 4), 0, 4)
		individual_heart.update(heart_fill_value)
		##boolean value to determine whether or not the chosen heart should or should not pulse
		var pulse : bool = (i == active_heart_index and heart_fill_value > 0)
		individual_heart.pulse(pulse, pulse_speed)
		var flash = (hp_low and heart_fill_value > 0)
		individual_heart.flash(flash)

#endregion FUNCTIONS
