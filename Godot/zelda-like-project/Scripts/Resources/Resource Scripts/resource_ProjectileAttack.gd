##[b][color=red]ProjectileAttackResource[/color][/b] holds the data for a projectile-type attack.[br]
##Assign to [b]AttackResource.projectile_data[/b] when using PROJECTILE_DIRECTIONAL or PROJECTILE_AREA attack types.
class_name ProjectileAttackResource
extends Resource

#region PROJECTILE SPRITE
@export_group("Projectile Sprite")
@export var projectile_sprite_strip : Texture2D
@export var sprite_strip_frames : int = 4
@export var animation_speed : float = 10.0
#endregion

#region COLLISION SPRITE
@export_group("Collision Sprite")
##Sprite shown when the projectile hits something.
@export var collision_sprite_strip : Texture2D
@export var collision_sprite_frames : int = 1
@export var collision_animation_speed : float = 10.0
#endregion

#region BEHAVIOR
@export_group("Behavior")
enum ProjectileSpeed { SLOW, AVERAGE, FAST }
##SLOW = 50 px/s (original minimum). AVERAGE = 100 px/s. FAST = 150 px/s.
@export var speed_tier : ProjectileSpeed = ProjectileSpeed.AVERAGE
##0 = fires in fixed direction. 100 = perfect tracking toward player.
@export_range(0, 100) var accuracy : float = 0.0
##Number of projectiles fired per attack.
@export var projectile_count : int = 1
##Delay in seconds between projectiles when projectile_count > 1.
@export var projectile_delay : float = 0.1
##Maximum travel distance in pixels before the projectile is destroyed.
@export_range(0, 2000, 1, "suffix:px") var max_distance : float = 200.0
#endregion

var travel_speed : float:
	get:
		match speed_tier:
			ProjectileSpeed.SLOW:    return 50.0
			ProjectileSpeed.AVERAGE: return 100.0
			ProjectileSpeed.FAST:    return 150.0
		return 100.0
