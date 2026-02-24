##[b][color=red]UIAudioControl[/color][/b] controls the audio that plays from the UX.
class_name UIAudioControl
extends AudioControl

#region VARIBALES
@export_category("Other Components")
##The root node of the player ui
@export var parent : PlayerUX
##The hearts grid container (expects heartsDisplay)
@export var hearts : HeartsDisplay
##The list of audio stream players associated with this entity (useful when UX controls multiple audio nodes).
##Format thusly: [i]{"sound_id": AudioStreamPlayer}[/i]
var active_players : Dictionary = {}
@export_category("Sound Libraries")
@export_group("Low Health")
##The sound that plays on a loop when the player's health is low
@export var low_health_sound : AudioStream
##Pitch when player is farthest from 0 HP but still below their low health threshold (flashing red hearts)
var min_low_health_sound_pitch : float = 1.0
##Pitch when player is nearest to 0 HP
var max_low_health_sound_pitch : float = 1.2
##The low_health_threshold of the player

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	default_bus = "UI"

##Updates the low health loop with a set value based on the character's current hit points, calculating a unique, local percentage.[br]
##This percentage is then used to determine how fast the sound should be playing.
func update_low_health_loop(current_hp: int, threshold: int):
	var sound_id = "low_health"
	#Ensure that the low health loop stops when the player has enough health or dies.
	if current_hp <= 0 or current_hp > threshold:
		_stop_sound_by_id(sound_id)
		return

	#Calculate 
	var ratio : float = float(current_hp) / float(threshold)
	var target_pitch = lerp(max_low_health_sound_pitch, min_low_health_sound_pitch, ratio)
	
	#Start the loop
	_manage_sound(sound_id, low_health_sound, target_pitch)

##Stop the low health loop from playing.
func _stop_sound_by_id(id : String):
	if active_players.has(id):
		var player = active_players[id]
		if player and player.playing:
			player.stop()
		active_players.erase(id)

##Start the low health loop.
func _manage_sound(id : String, sound : AudioStream, pitch : float):
	if active_players.has(id):
		var player = active_players[id]
		if not player.playing:
			player.play()
		player.pitch_scale = pitch
	else:
		var new_player = play_sound(sound, default_bus, pitch)
		if new_player:
			active_players[id] = new_player
#endregion FUNCTIONS
