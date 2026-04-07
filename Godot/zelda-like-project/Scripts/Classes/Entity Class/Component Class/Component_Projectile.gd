##[b][color=red]ProjectileComponent[/color][/b] handles the movement of a thrown DynamicThing.[br]
##Simulates a visual arc (sprite offset goes up then down) while the body moves along the ground.[br]
##On collision with a wall or object, or when reaching max distance: lands.[br]
##If the object is breakable, it breaks on impact. Otherwise it stops in place.[br]
##[br]
##Attach this as a child of the DynamicThing, or add it dynamically when throwing.
class_name ProjectileComponent
extends Component

#region SIGNALS

##Emitted when the projectile has landed or hit something.[br]
##[b]broke[/b]: Whether the object broke on impact.
signal projectile_landed(broke : bool)

#endregion SIGNALS

#region VARIABLES

##The DynamicThing being thrown.
var _object : DynamicThing
##The CharacterBody2D of the thrown object.
var _body : CharacterBody2D
##The sprite node of the thrown object (for visual arc offset).
var _sprite : Node2D
##The direction of travel.
var _direction : Vector2 = Vector2.ZERO
##Total distance to travel in pixels.
var _max_distance : float = 0.0
##Distance traveled so far.
var _distance_traveled : float = 0.0
##Speed in pixels per second.
var _speed : float = 150.0
##The peak height of the visual arc in pixels.
var _arc_height : float = 8.0
##Whether the projectile is currently active.
var _active : bool = false
##The original local position of the sprite (to restore after arc).
var _sprite_original_offset : Vector2 = Vector2.ZERO

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_physics_process(false)

##Launches the projectile.[br]
##[b]object[/b]: The DynamicThing being thrown.[br]
##[b]direction[/b]: Normalized direction of travel.[br]
##[b]max_distance[/b]: How far the object travels in pixels.[br]
##[b]speed[/b]: Travel speed in pixels per second.[br]
##[b]arc_height[/b]: Peak height of the visual arc.
func launch(object : DynamicThing, direction : Vector2, max_distance : float, speed : float = 150.0, arc_height : float = 8.0) -> void:
	_object = object
	_body = object.body
	_direction = direction.normalized()
	_max_distance = max_distance
	_speed = speed
	_arc_height = arc_height
	_distance_traveled = 0.0
	_active = true
	#Find the sprite for visual arc offset.
	_sprite = object.animated_sprite as Node2D if object.animated_sprite else object.sprite as Node2D
	if _sprite:
		#Capture the hold offset so the arc descends from it to body center.
		_sprite_original_offset = _sprite.position
	#Re-enable collision for the projectile to detect walls.
	if object.body:
		var col = object.body.get_node_or_null("CollisionShape2D")
		if col:
			col.disabled = false
	set_physics_process(true)
	if debug_me:
		print(debug_name, ": Launched ", direction, " dist=", max_distance, " speed=", speed)
		if _sprite:
			print(debug_name, ": Sprite original offset: ", _sprite_original_offset)
			print(debug_name, ": Sprite current position: ", _sprite.position)
			print(debug_name, ": Body global position: ", _body.global_position)

func _physics_process(delta : float):
	if not _active or not _body:
		set_physics_process(false)
		return
	#Calculate movement this frame.
	var move_amount : float = _speed * delta
	var remaining : float = _max_distance - _distance_traveled
	if move_amount > remaining:
		move_amount = remaining
	#Attempt to move the body.
	var collision = _body.move_and_collide(_direction * move_amount)
	if collision:
		#Hit something -- land here.
		_distance_traveled = _max_distance
		_land(true)
		return
	_distance_traveled += move_amount
	#Apply visual arc to sprite.
	if _sprite:
		var progress : float = _distance_traveled / _max_distance
		#Descend from hold offset to body center, with a parabolic upward bump.
		var descent : float = _sprite_original_offset.y * (1.0 - progress)
		var bump : float = -_arc_height * 4.0 * progress * (1.0 - progress)
		_sprite.position = Vector2(_sprite_original_offset.x, descent + bump)
		if debug_me and debug_me_verbose:
			print(debug_name, ": progress=", snapped(progress, 0.01), " arc_offset=", snapped(bump, 0.1), " sprite.pos=", _sprite.position)
	#Check if we've reached max distance.
	if _distance_traveled >= _max_distance:
		_land(false)

##Handles landing. Resets sprite offset, re-enables collision, and optionally breaks the object.
func _land(hit_something : bool):
	_active = false
	set_physics_process(false)
	#Reset sprite to body center (arc has fully descended by landing).
	if _sprite:
		_sprite.position = Vector2.ZERO
	var broke : bool = false
	#Check if the object should break.
	var parent = _body.get_parent() if _body else null
	if parent and "shadow" in parent and parent.shadow:
		parent.shadow.visible = true
	if _object and _object.object_data:
		if _object.object_data.breakable:
			_object.break_me()
			broke = true
		else:
			#Re-enable collision for the landed object.
			_object.enable_collision()
	if debug_me:
		var reason = "collision" if hit_something else "max distance"
		print(debug_name, ": Landed (", reason, "). Broke: ", broke)
	projectile_landed.emit(broke)

#endregion FUNCTIONS
