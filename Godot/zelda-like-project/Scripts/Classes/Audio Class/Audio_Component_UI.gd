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
@export_group("Dialogue Sound Manager")
##The audio stream player reference for the voice player. Keeps things in a single player since we play a sound multiple times per frame.
var _voice_player : AudioStreamPlayer


#endregion VARIABLES

#region FUNCTIONS

func _ready():
	default_bus = "UI"

func intialize_voice_player():
	if _voice_player:
		return
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Dialogue"
	add_child(_voice_player)
	if debug_me:
		print(debug_name, " created a new voice player", _voice_player)
	
func play_voice_blip(stream : AudioStream, pitch : float = 1.0):
	if not _voice_player:
		intialize_voice_player()
	if _voice_player and stream:
		_voice_player.stop()
		_voice_player.stream = stream
		_voice_player.pitch_scale = pitch
		_voice_player.play()

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
