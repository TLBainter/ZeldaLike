@tool
@icon("res://Editor Tools/Icons/icon_audio.svg")
##One ambience layer: a SoundLibrary played on its own voice with its own volume, loop and start settings.
class_name AmbienceLayerResource
extends Resource

enum LoopMode { CONTINUOUS, COUNT, INTERVAL }
enum StartMode { ON_LOAD, AFTER_DELAY, RANDOM_DELAY }

##Sounds picked at random each time the layer plays.
@export var library: SoundLibrary
##Linear volume of this layer, 0 is silent and 1 is full volume.
@export_range(0.0, 1.0, 0.01) var volume: float = 1.0

@export_group("Loop")
##CONTINUOUS replays forever, COUNT plays loop_count times, INTERVAL waits a random loop interval between plays.
@export var loop_mode: LoopMode = LoopMode.CONTINUOUS:
	set(value):
		loop_mode = value
		notify_property_list_changed()
##Total number of plays when loop_mode is COUNT.
@export_range(1, 999) var loop_count: int = 1
##Shortest wait between plays when loop_mode is INTERVAL.
@export_range(0.0, 600.0, 0.1, "suffix:s") var loop_interval_min: float = 5.0
##Longest wait between plays when loop_mode is INTERVAL.
@export_range(0.0, 600.0, 0.1, "suffix:s") var loop_interval_max: float = 5.0

@export_group("Start")
##ON_LOAD plays immediately, AFTER_DELAY waits start_delay, RANDOM_DELAY waits a random time between start_delay_min and start_delay_max.
@export var start_mode: StartMode = StartMode.ON_LOAD:
	set(value):
		start_mode = value
		notify_property_list_changed()
##Wait before the first play when start_mode is AFTER_DELAY.
@export_range(0.0, 600.0, 0.1, "suffix:s") var start_delay: float = 0.0
##Shortest wait before the first play when start_mode is RANDOM_DELAY.
@export_range(0.0, 600.0, 0.1, "suffix:s") var start_delay_min: float = 0.0
##Longest wait before the first play when start_mode is RANDOM_DELAY.
@export_range(0.0, 600.0, 0.1, "suffix:s") var start_delay_max: float = 5.0

func _validate_property(property: Dictionary) -> void:
	match property.name:
		"loop_count":
			if loop_mode != LoopMode.COUNT:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"loop_interval_min", "loop_interval_max":
			if loop_mode != LoopMode.INTERVAL:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"start_delay":
			if start_mode != StartMode.AFTER_DELAY:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"start_delay_min", "start_delay_max":
			if start_mode != StartMode.RANDOM_DELAY:
				property.usage = PROPERTY_USAGE_NO_EDITOR

##Returns true when the layer has a library with at least one sound.
func is_valid() -> bool:
	return library != null and not library.sounds.is_empty()

##Returns the layer volume in decibels, or -80 dB when the volume is zero.
func get_volume_db() -> float:
	if volume <= 0.0:
		return -80.0
	return linear_to_db(volume)

##Returns the wait in seconds before the first play, based on start_mode.
func pick_start_delay() -> float:
	match start_mode:
		StartMode.AFTER_DELAY:
			return start_delay
		StartMode.RANDOM_DELAY:
			return randf_range(start_delay_min, maxf(start_delay_min, start_delay_max))
	return 0.0

##Returns a random wait in seconds between plays for INTERVAL mode.
func pick_loop_interval() -> float:
	return randf_range(loop_interval_min, maxf(loop_interval_min, loop_interval_max))
