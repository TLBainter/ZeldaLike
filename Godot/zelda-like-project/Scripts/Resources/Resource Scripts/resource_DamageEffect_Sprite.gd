@tool
##[b][color=red]DamageEffectSprite[/color][/b] defines a single sprite-strip animation to play as part of a [b]DamageEffectResource[/b].
class_name DamageEffectSprite
extends Resource

enum SoundPlayStyle { EACH_TIME, AT_START }

#region BACKING VARIABLES

var sprite_strip : Texture2D = null
var frame_count : int = 1
var animation_speed : float = 12.0
var loops : bool = false
var loop_count : int = 1
var sound_library : SoundLibrary = null
var sound_play_style : SoundPlayStyle = SoundPlayStyle.AT_START

#endregion

#region PROPERTY LIST

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "sprite_strip",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Texture2D",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "frame_count",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1,64,1",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "animation_speed",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1.0,120.0,0.1,suffix:fps",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{"name": "loops", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT},
	] + (
		[{
			"name": "loop_count",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1,100,1",
			"usage": PROPERTY_USAGE_DEFAULT,
		}] if loops else []
	) + [
		{
			"name": "sound_library",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "SoundLibrary",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "sound_play_style",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Each Time,At Start",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]

#endregion

#region SET / GET

func _set(property : StringName, value : Variant) -> bool:
	match property:
		&"sprite_strip":     sprite_strip = value as Texture2D; return true
		&"frame_count":      frame_count = value; return true
		&"animation_speed":  animation_speed = value; return true
		&"loops":            loops = value; notify_property_list_changed(); return true
		&"loop_count":       loop_count = value; return true
		&"sound_library":    sound_library = value as SoundLibrary; return true
		&"sound_play_style": sound_play_style = value; return true
	return false

func _get(property : StringName) -> Variant:
	match property:
		&"sprite_strip":     return sprite_strip
		&"frame_count":      return frame_count
		&"animation_speed":  return animation_speed
		&"loops":            return loops
		&"loop_count":       return loop_count
		&"sound_library":    return sound_library
		&"sound_play_style": return sound_play_style
	return null

#endregion
