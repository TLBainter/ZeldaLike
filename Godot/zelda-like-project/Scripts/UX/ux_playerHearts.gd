##[b][color=red]HeartsDisplay[/color][/b] is a script used to control the overall heart display in the player GUI.[br]
##Note that this [i]does not[/i] control things like individual heart state changes, player health, etc.
class_name HeartsDisplay
extends GridContainer

#region VARIABLES
@export_category("Hearts Display Components")
##A reference to the heart gui scene; make sure the scene has the playerHeartGUI panel as its parent and is of the HeartGUI class!
@export var heart_gui : PackedScene
@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "Hearts Grid Container"

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
#Calculate 10% HP threshold
	#reverse engineer max hp
	var max_hp : int = int(hearts.size() * 4)
	##The threshold at which the hearts will start flashing due to low health[br]
	##Note that to prevent the value from being kept at 1 in the early game, it has a minimum of 4.[br]
	##This will ensure the last heart always flashes when it's the only one remaining!
	var low_hp_threshold : int = clampi(int(floor(max_hp * 0.25)), 4, 15)
	##whether or not the character currently has low hp
	var hp_low : bool = (cur_health <= low_hp_threshold and cur_health > 0)
	if debug_me:
		print("Player has ", hearts, " hearts")
		print("Player's max hp is ", max_hp)
		print("Player's low_hp_threshold is ", low_hp_threshold)
	for i in range(hearts.size()):
		##Gets and defines individual hearts for later use
		var individual_heart = hearts[i] as HeartGUI
	#Update visual of each heart based on its fill value
		##the amount of 'fill' for a heart (0-4).[br]
		##used in ux_playerHearts_individualGUI to define the appearance of a given heart
		var heart_fill_value = clampi(cur_health - (i * 4), 0, 4)
		#send the update to the heart gui
		individual_heart.update(heart_fill_value)
	#Pulse the heart
		##boolean value to determine whether or not the chosen heart should or should not pulse
		var pulse : bool = (i == active_heart_index and heart_fill_value > 0)
		individual_heart.pulse(pulse)
	#Flash the heart
		var flash = (hp_low and heart_fill_value > 0)
		individual_heart.flash(flash)
