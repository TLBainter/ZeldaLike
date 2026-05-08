@tool
##[b][color=red]DamageEffectResource[/color][/b] defines the visual and audio response a character plays when it takes damage.[br]
##Attach one to a damage source to override the receiver's default effect, or assign a [b]default_damage_effect[/b] on any [b]Character[/b].
class_name DamageEffectResource
extends Resource

#region ENUMS

enum FlashSpeed      { SLOW, AVERAGE, FAST }
enum ParticleDuration { SHORT, AVERAGE, LONG }
enum ParticleSpawnPoint { CHARACTER_ROOT, DAMAGE_POINT }
enum SpritePlayStyle  { SEQUENTIAL, ALL_AT_ONCE }

#endregion

#region BACKING VARIABLES

var use_flash : bool = false
var flash_color : Color = Color.BLACK
var flash_count_equals_damage : bool = false
var flash_count : int = 3
var flash_speed : FlashSpeed = FlashSpeed.AVERAGE

var use_particle : bool = false
var particle_resource : PackedScene = null
var particle_duration : ParticleDuration = ParticleDuration.AVERAGE
var particle_color : Color = Color.WHITE
var particle_tracking : bool = false
var particle_spawn_point : ParticleSpawnPoint = ParticleSpawnPoint.CHARACTER_ROOT

var use_sprite : bool = false
var sprite_play_style : SpritePlayStyle = SpritePlayStyle.SEQUENTIAL
var sprite_interval : float = 0.0
var damage_effect_sprites : Array[DamageEffectSprite] = []

var use_sound : bool = false
var sound_library : SoundLibrary = null

#endregion

#region PROPERTY LIST

func _get_property_list() -> Array[Dictionary]:
	var props : Array[Dictionary] = []

	# ── Flash ─────────────────────────────────────────────────────────────────
	props.append({"name": "Flash", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""})
	props.append({"name": "use_flash", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
	if use_flash:
		props.append({"name": "flash_color", "type": TYPE_COLOR, "usage": PROPERTY_USAGE_DEFAULT})
		props.append({"name": "flash_count_equals_damage", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
		if not flash_count_equals_damage:
			props.append({
				"name": "flash_count",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "1,20,1",
				"usage": PROPERTY_USAGE_DEFAULT,
			})
		props.append({
			"name": "flash_speed",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Slow,Average,Fast",
			"usage": PROPERTY_USAGE_DEFAULT,
		})

	# ── Particle ──────────────────────────────────────────────────────────────
	props.append({"name": "Particle", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""})
	props.append({"name": "use_particle", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
	if use_particle:
		props.append({
			"name": "particle_resource",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "PackedScene",
			"usage": PROPERTY_USAGE_DEFAULT,
		})
		props.append({
			"name": "particle_duration",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Short,Average,Long",
			"usage": PROPERTY_USAGE_DEFAULT,
		})
		props.append({"name": "particle_color", "type": TYPE_COLOR, "usage": PROPERTY_USAGE_DEFAULT})
		props.append({"name": "particle_tracking", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
		props.append({
			"name": "particle_spawn_point",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Character Root,Damage Point",
			"usage": PROPERTY_USAGE_DEFAULT,
		})

	# ── Sprite ────────────────────────────────────────────────────────────────
	props.append({"name": "Sprite", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""})
	props.append({"name": "use_sprite", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
	if use_sprite:
		props.append({
			"name": "sprite_play_style",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Sequential,All At Once",
			"usage": PROPERTY_USAGE_DEFAULT,
		})
		if sprite_play_style == SpritePlayStyle.SEQUENTIAL:
			props.append({
				"name": "sprite_interval",
				"type": TYPE_FLOAT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "-1.0,2.0,0.01,suffix:s",
				"usage": PROPERTY_USAGE_DEFAULT,
			})
		props.append({
			"name": "damage_effect_sprites",
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "DamageEffectSprite",
			"usage": PROPERTY_USAGE_DEFAULT,
		})

	# ── Sound ─────────────────────────────────────────────────────────────────
	props.append({"name": "Sound", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""})
	props.append({"name": "use_sound", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
	if use_sound:
		props.append({
			"name": "sound_library",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "SoundLibrary",
			"usage": PROPERTY_USAGE_DEFAULT,
		})

	return props

#endregion

#region SET / GET

func _set(property : StringName, value : Variant) -> bool:
	match property:
		&"use_flash":
			use_flash = value
			notify_property_list_changed()
			return true
		&"flash_color":               flash_color = value; return true
		&"flash_count_equals_damage":
			flash_count_equals_damage = value
			notify_property_list_changed()
			return true
		&"flash_count":               flash_count = value; return true
		&"flash_speed":               flash_speed = value; return true

		&"use_particle":
			use_particle = value
			notify_property_list_changed()
			return true
		&"particle_resource":         particle_resource = value as PackedScene; return true
		&"particle_duration":         particle_duration = value; return true
		&"particle_color":            particle_color = value; return true
		&"particle_tracking":         particle_tracking = value; return true
		&"particle_spawn_point":      particle_spawn_point = value; return true

		&"use_sprite":
			use_sprite = value
			notify_property_list_changed()
			return true
		&"sprite_play_style":
			sprite_play_style = value
			notify_property_list_changed()
			return true
		&"sprite_interval":           sprite_interval = value; return true
		&"damage_effect_sprites":     damage_effect_sprites = value; return true

		&"use_sound":
			use_sound = value
			notify_property_list_changed()
			return true
		&"sound_library":             sound_library = value as SoundLibrary; return true
	return false

func _get(property : StringName) -> Variant:
	match property:
		&"use_flash":                 return use_flash
		&"flash_color":               return flash_color
		&"flash_count_equals_damage": return flash_count_equals_damage
		&"flash_count":               return flash_count
		&"flash_speed":               return flash_speed

		&"use_particle":              return use_particle
		&"particle_resource":         return particle_resource
		&"particle_duration":         return particle_duration
		&"particle_color":            return particle_color
		&"particle_tracking":         return particle_tracking
		&"particle_spawn_point":      return particle_spawn_point

		&"use_sprite":                return use_sprite
		&"sprite_play_style":         return sprite_play_style
		&"sprite_interval":           return sprite_interval
		&"damage_effect_sprites":     return damage_effect_sprites

		&"use_sound":                 return use_sound
		&"sound_library":             return sound_library
	return null

#endregion

#region HELPERS

func get_flash_interval() -> float:
	match flash_speed:
		FlashSpeed.SLOW:    return 0.05
		FlashSpeed.FAST:    return 0.01
	return 0.025

func get_particle_duration_value() -> float:
	match particle_duration:
		ParticleDuration.SHORT: return 0.2
		ParticleDuration.LONG:  return 1.0
	return 0.5

#endregion
