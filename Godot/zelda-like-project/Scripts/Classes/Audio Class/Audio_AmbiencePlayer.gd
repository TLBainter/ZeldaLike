@tool
##Plays every layer of an AmbienceResource at once, one AmbienceLayerPlayer per layer. Handles layers only; music is not played here.
class_name AmbiencePlayer
extends Node

##The ambience currently playing, or null.
var current: AmbienceResource:
	get:
		return _current

var _current: AmbienceResource = null

##Stops the current ambience and starts one layer player for each valid layer of the given ambience.
func play(ambience: AmbienceResource) -> void:
	stop()
	_current = ambience
	if ambience == null:
		return
	for layer in ambience.layers:
		if layer == null or not layer.is_valid():
			continue
		var layer_player := AmbienceLayerPlayer.new()
		add_child(layer_player)
		layer_player.start(layer)

##Stops and frees all layer players.
func stop() -> void:
	for child in get_children():
		if child is AmbienceLayerPlayer:
			(child as AmbienceLayerPlayer).stop()
			child.queue_free()
	_current = null
