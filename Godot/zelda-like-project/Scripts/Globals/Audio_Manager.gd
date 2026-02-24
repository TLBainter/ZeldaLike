##[b][color=red]AudioManager[/color][/b] controls the overall game audio through multiple instances.[br]
##Anything that should be played globally (not instanced to a specific location) should appear here.
class_name AudioManager
extends Node

var audio_players : Array[AudioStreamPlayer]

##Plays audio on a new audio stream player (or existing one, if it is freed up)[br]
##[b]stream[/b]: expects the AudioStream file.[br]
##[b]bus[/b]: expects the bus to play on, choosing from Music, Ambience, UI, Character, or Environment.[br]
##[b][i]NOTE[/i][/b]: The bus will default to Sound Effects, so you do not have to send the SFX value!
func play (stream : AudioStream, bus : String = "Sound Effects"):
	var ap : AudioStreamPlayer = _get_available_audio_player()
	ap.stream = stream
	ap.bus = bus
	ap.play()

func _get_available_audio_player () -> AudioStreamPlayer:
	#look for an unused audio player
	for ap in audio_players:
		if not ap.playing:
			return ap
	#create a new audio player if there are not enough audio players
	return _create_new()

##Creates a new audio stream player if not enough players exist.
func _create_new () -> AudioStreamPlayer:
	##ap is the new audio player that was returned for the array
	var ap : AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(ap)
	#add this new audio player to the audio_players array
	audio_players.append(ap)
	return ap
