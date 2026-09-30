## Editor-only node that previews an [b]AmbienceResource[/b]: music through [b]AmbienceSongPreviewPlayer[/b] and layers through [b]AmbiencePlayer[/b].
@tool
class_name AmbiencePreview
extends Node

var _layers: AmbiencePlayer
var _song: AmbienceSongPreviewPlayer

func _init() -> void:
	_layers = AmbiencePlayer.new()
	add_child(_layers)
	_song = AmbienceSongPreviewPlayer.new()
	add_child(_song)

## Stops any running preview, then plays the ambience music (if any) and all valid layers.
func preview(ambience: AmbienceResource) -> void:
	stop()
	if ambience == null:
		return
	var song: SongResource = ambience.music
	if song != null and song.loop != null:
		var volume: float = ambience.music_volume
		var volume_db: float = linear_to_db(volume) if volume > 0.0 else -80.0
		_song.play_song(song, volume_db)
	_layers.play(ambience)

## Stops the preview music and all preview layers.
func stop() -> void:
	_layers.stop()
	_song.stop()
