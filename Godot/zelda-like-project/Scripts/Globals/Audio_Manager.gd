##Controls overall game audio. Plays globally-sourced audio (not location-specific).
class_name AudioManager
extends Node

var audio_players : Array[AudioStreamPlayer]

##Plays audio on new or available audio stream player.
##Returns player instance for controlling pitch or ending looping sounds.
func play (stream : AudioStream, bus : String = "Sound Effects", pitch : float = 1.0) -> AudioStreamPlayer:
	var ap : AudioStreamPlayer = _get_available_audio_player()
	ap.stream = stream
	ap.bus = bus
	ap.pitch_scale = pitch
	ap.volume_db = 0.0
	ap.play()
	return ap

func _get_available_audio_player () -> AudioStreamPlayer:
	for ap in audio_players:
		if not ap.playing:
			return ap
	return _create_new()

func _create_new () -> AudioStreamPlayer:
	var ap : AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(ap)
	audio_players.append(ap)
	return ap
