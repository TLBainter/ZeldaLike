##[b][color=red]AudioManager[/color][/b] controls the overall game audio through multiple instances.[br]
##Anything that should be played globally (not instanced to a specific location) should appear here.
class_name AudioManager
extends Node

var audio_players : Array[AudioStreamPlayer]

func play (stream : AudioStream):
	var ap : AudioStreamPlayer = _get_available_audio_player()
	ap.stream = stream
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
