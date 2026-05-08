##[b][color=red]GameConstants[/color][/b] centralizes magic numbers used across the movement system.[br]
##Reference these instead of raw literals to keep all tuning values in one place.
class_name GameConstants
extends RefCounted

##Minimum joystick input magnitude before movement is registered.
const JOYSTICK_DEADZONE : float = 0.15
##Input magnitude threshold above which the character transitions from walk to run.
const RUN_THRESHOLD     : float = 0.49
##Grid-snapping distance used when pushing or pulling objects.
const SNAP_DISTANCE     : float = 8.0
