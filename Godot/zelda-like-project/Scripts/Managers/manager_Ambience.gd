##Autoload that plays location-specific ambience. Requesting null stops the layers. Music, if any, is handed to musicManager and keeps the normal song transition behaviour.
class_name AmbienceManager
extends Node

var _player: AmbiencePlayer
var _current: AmbienceResource = null

func _ready() -> void:
	_player = AmbiencePlayer.new()
	add_child(_player)

##Starts the given ambience, or stops the layers when null. Requesting the ambience already playing does nothing.
func request_ambience(ambience: AmbienceResource) -> void:
	if ambience == _current:
		return
	_current = ambience
	if ambience == null:
		_player.stop()
		return
	if ambience.has_music():
		musicManager.request_song(ambience.music, ambience.music_volume)
	_player.play(ambience)

##Stops all ambience layers. Music is left to musicManager.
func stop_ambience() -> void:
	_current = null
	_player.stop()
