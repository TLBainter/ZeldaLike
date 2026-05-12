@icon("res://Editor Tools/Icons/icon_music.svg")
class_name SongResource
extends Resource

@export var opener: AudioStream
@export var loop: AudioStream
@export var exit: AudioStream

##Validates that the song has the required loop stream.
func is_valid() -> bool:
	return loop != null
