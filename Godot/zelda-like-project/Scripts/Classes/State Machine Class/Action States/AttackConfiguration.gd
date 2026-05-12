class_name AttackConfiguration
extends Resource

##Per-direction hitbox offsets and rotations for attacks.
##Allows attack variants (ranged, magic) without modifying state logic.

@export var offsets: Dictionary = {
	"down":  { "position": Vector2(0, 6),   "rotation": 0.0   },
	"up":    { "position": Vector2(0, -6),  "rotation": 180.0 },
	"left":  { "position": Vector2(-6, 0),  "rotation": 90.0  },
	"right": { "position": Vector2(6, 0),   "rotation": -90.0 },
}
