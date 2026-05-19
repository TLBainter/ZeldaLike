@tool
##[b][color=red]AttackResource[/color][/b] defines the data for a single enemy attack.[br]
##Assign one or more to an [b]EnemyAttackComponent[/b] to configure the enemy's available attacks.
class_name AttackResource
extends Resource

# TODO: define AttackType and DamageLevel globally once multiple enemies share them
enum AttackType { MELEE_DIRECTIONAL, PROJECTILE_DIRECTIONAL, MELEE_AREA, PROJECTILE_AREA }
enum DamageLevel { LOW = 2, AVERAGE = 4, HIGH = 6 }

#region BACKING VARIABLES
# All properties are virtual (via _get_property_list) so their order in the inspector
# is fully controlled. @export is not used - exported node types are illegal on Resources.

var attack_type : AttackType = AttackType.MELEE_DIRECTIONAL

var damage : DamageLevel = DamageLevel.AVERAGE
var blockable : bool = true
var parryable : bool = false
var interruptable : bool = true

var _vis_anims_cache : Array[CharacterAnimationResource] = []  # editor-only, not serialized
var animation_name : String = ""
var attack_trigger_frame : int = 0

var parry_window_start : float = 0.1
var parry_window_end : float = 0.3

var _area_cache : Area2D = null  # backs "attack_area" virtual property
var collision_shape_suffix : String = ""

var projectile_data : ProjectileAttackResource = null

#endregion

#region PROPERTY LIST

func _get_property_list() -> Array[Dictionary]:
	return [
		# -- Attack Type ------------------------------------------------------
		{"name": "Attack Type", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""},
		{
			"name": "attack_type",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Melee Directional,Projectile Directional,Melee Area,Projectile Area",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		# -- Damage -----------------------------------------------------------
		{"name": "Damage", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""},
		{
			"name": "damage",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Low:2,Average:4,High:6",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{"name": "blockable",     "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "parryable",     "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "interruptable", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT},
		# -- Animation --------------------------------------------------------
		{"name": "Animation", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""},
		{"name": "animation_name",       "type": TYPE_STRING, "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "attack_trigger_frame", "type": TYPE_INT,    "usage": PROPERTY_USAGE_DEFAULT},
		# -- Parry Window -----------------------------------------------------
		{"name": "Parry Window", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""},
		# TODO: parry system not implemented
		{
			"name": "parry_window_start",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.0,10.0,0.01,suffix:s",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		{
			"name": "parry_window_end",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.0,10.0,0.01,suffix:s",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
		# -- Area Data --------------------------------------------------------
		{"name": "Area Data", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""},
		{
			"name": "attack_area",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_NODE_TYPE,
			"hint_string": "Area2D",
			"usage": PROPERTY_USAGE_DEFAULT,  # saved - wired to scene Area2D node
		},
		{"name": "collision_shape_suffix", "type": TYPE_STRING, "usage": PROPERTY_USAGE_DEFAULT},
		# -- Projectile Data --------------------------------------------------
		{"name": "Projectile Data", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP, "hint_string": ""},
		{
			"name": "projectile_data",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "ProjectileAttackResource",
			"usage": PROPERTY_USAGE_DEFAULT,
		},
	]

#endregion

#region SET / GET

func _set(property : StringName, value : Variant) -> bool:
	match property:
		&"attack_type":          attack_type = value;           return true
		&"damage":               damage = value;                return true
		&"blockable":            blockable = value;             return true
		&"parryable":            parryable = value;             return true
		&"interruptable":        interruptable = value;         return true
		&"animation_name":       animation_name = value;        return true
		&"attack_trigger_frame": attack_trigger_frame = value;  return true
		&"parry_window_start":   parry_window_start = value;    return true
		&"parry_window_end":     parry_window_end = value;      return true
		&"attack_area":          _area_cache = value as Area2D; return true
		&"collision_shape_suffix": collision_shape_suffix = value; return true
		&"projectile_data":      projectile_data = value as ProjectileAttackResource; return true
	return false

func _get(property : StringName) -> Variant:
	match property:
		&"attack_type":              return attack_type
		&"damage":                   return damage
		&"blockable":                return blockable
		&"parryable":                return parryable
		&"interruptable":            return interruptable
		&"animation_name":           return animation_name
		&"attack_trigger_frame":     return attack_trigger_frame
		&"parry_window_start":       return parry_window_start
		&"parry_window_end":         return parry_window_end
		&"attack_area":              return _area_cache
		&"collision_shape_suffix":   return collision_shape_suffix
		&"projectile_data":          return projectile_data
	return null

#endregion

#region TOOL - dynamic inspector hints

func _validate_property(property : Dictionary) -> void:
	if property.name == "animation_name":
		if not _vis_anims_cache.is_empty():
			var names : PackedStringArray = []
			for r : CharacterAnimationResource in _vis_anims_cache:
				if r and r.animation_name != "":
					names.append(r.animation_name)
			if names.size() > 0:
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(names)

#endregion

#region FUNCTIONS

func get_damage_amount() -> int:
	return int(damage)

#endregion
