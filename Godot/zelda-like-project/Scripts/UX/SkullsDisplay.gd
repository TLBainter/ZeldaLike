##[b][color=red]SkullsDisplay[/color][/b] is a script used to control the overall skull display in the player GUI.[br]
##Note that this [i]does not[/i] control things like individual skull state changes, player health, etc.
class_name SkullsDisplay
extends GridContainer

#region VARIABLES
@export_category("Skulls Display Components")
##A reference to the skull gui scene; make sure the scene has the playerSkullGUI panel as its parent and is of the SkullGUI class!
@export var skull_gui : PackedScene
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

func set_max_skulls(max_skulls : int):
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in range(max_skulls):
		var skull = skull_gui.instantiate()
		add_child(skull)

func update_skulls(cur_health : int):

	##variable which gets the currently-active skull in the index
	var active_skull_index = int(ceil(cur_health / 4.0)) -1
	var skulls = get_children()
	var max_hp : int = int(skulls.size() * 4)
	##The threshold at which the skulls will start flashing due to low health[br]
	##Note that to prevent the value from being kept at 1 in the early game, it has a minimum of 4.[br]
	##This will ensure the last skull always flashes when it's the only one remaining!
	var low_hp_threshold : int = clampi(int(floor(max_hp * 0.25)), 4, 15)
	##How quickly the skull will pulse; affected by low health to sync with faster heartbeat sound
	var pulse_speed : float = 1.0
	##whether or not the character currently has low hp
	var hp_low : bool = (cur_health <= low_hp_threshold and cur_health > 0)
	ui_audio.update_low_health_loop(cur_health, low_hp_threshold)
	if hp_low and ui_audio:
		var ratio : float = float(cur_health) / float(low_hp_threshold)
		pulse_speed = lerp(max_pulse_speed, min_pulse_speed, ratio)
	if debug_me:
		print("Player has ", skulls.size(), " skulls")
		print("Player's max hp is ", max_hp)
		print("Player's low_hp_threshold is ", low_hp_threshold)
	if debug_me_verbose:
		print_rich(debug_name, ": [color=cyan]=== Skulls Size Snapshot ===[/color] cur_health=", cur_health)
		print_rich(debug_name, ": GridContainer | size=", size, " | custom_min=", custom_minimum_size, " | h_sep=", get_theme_constant(&"h_separation"), " | v_sep=", get_theme_constant(&"v_separation"))
	for i in range(skulls.size()):
		##Gets and defines individual skull GUIs for later use
		var individual_skull = skulls[i] as SkullGUI
		##the amount of 'fill' for a skull (0-4).[br]
		##used in SkullGUI to define the appearance of a given skull
		var skull_fill_value = clampi(cur_health - (i * 4), 0, 4)
		individual_skull.update(skull_fill_value)
		##boolean value to determine whether or not the chosen skull should or should not pulse
		var pulse : bool = (i == active_skull_index and skull_fill_value > 0)
		individual_skull.pulse(pulse, pulse_speed)
		var flash = (hp_low and skull_fill_value > 0)
		individual_skull.flash(flash)
		if debug_me_verbose:
			var atlas_region_str : String = "n/a"
			if individual_skull.sprite and individual_skull.sprite.texture is AtlasTexture:
				atlas_region_str = str((individual_skull.sprite.texture as AtlasTexture).region)
			print_rich(debug_name, ": Skull[", i, "]",
				" pulsing=", pulse,
				" | Panel.size=", individual_skull.size,
				" | Panel.custom_min=", individual_skull.custom_minimum_size,
				" | Sprite.size=", individual_skull.sprite.size,
				" | Sprite.scale=", individual_skull.sprite.scale,
				" | Sprite.pivot_offset=", individual_skull.sprite.pivot_offset,
				" | Sprite.custom_min=", individual_skull.sprite.custom_minimum_size,
				" | atlas_region=", atlas_region_str)

#endregion FUNCTIONS
