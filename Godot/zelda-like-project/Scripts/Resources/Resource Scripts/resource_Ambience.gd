@icon("res://Editor Tools/Icons/icon_audio.svg")
##[b][color=red]AmbienceResource[/color][/b] bundles a song plus simultaneous ambience layers, each with its own volume, loop and start settings.[br]
##The "Preview Ambience" inspector button plays it in the editor.
class_name AmbienceResource
extends Resource

##Optional song handed to the MusicManager when this ambience is requested.
@export var music: SongResource
##Linear volume of the song, 0 is silent and 1 is full volume.
@export_range(0.0, 1.0, 0.01) var music_volume: float = 1.0
##Layers that play at the same time as each other and the song.
@export var layers: Array[AmbienceLayerResource] = []

##Returns true when a valid song is assigned.
func has_music() -> bool:
	return music != null and music.is_valid()

##Returns the song volume in decibels, or -80 dB when the volume is zero.
func get_music_volume_db() -> float:
	if music_volume <= 0.0:
		return -80.0
	return linear_to_db(music_volume)
