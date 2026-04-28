@icon("res://Editor Tools/Icons/icon_sound-effect.svg")
##[b][color=red]SoundLibrary[/color][/b] is utilized to collect a group of sounds into one singular resource.[br]
##This allows the sound library to be reused for different entities, instead of needing to manually copy elements between them.
class_name SoundLibrary
extends Resource

@export var sounds : Array[AudioStream]
