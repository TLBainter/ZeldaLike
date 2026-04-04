##[b][color=red]Object[/color][/b] refers to any object that can be placed in the world,[br]
##regardless of whether the object can be interacted with.[br]
##This includes chests, switches, breakable pots, torches, and more.
class_name Thing
extends EntityClass

#region VARIABLES
#region EXPORT VARIABLES



#endregion
#region INTERNAL VARIABLES
##the subtype of this thing; set by its subclass.
var subtype : String
#endregion
#endregion

#region FUNCTIONS
#region READY
func _ready():
	super._ready()
	#establish variables
	type = "Thing"
	add_to_group("entities")

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0]
	return null

func _find_clear_direction(space_state: PhysicsDirectSpaceState2D, origin: Vector2, preferred_dir: Vector2) -> Vector2:
	var ray_length: float = 24.0
	var attempts: int = 8
	var angle_step: float = TAU / attempts
	for i in range(attempts):
		var test_angle = preferred_dir.angle() + (angle_step * i)
		var test_dir = Vector2(cos(test_angle), sin(test_angle))
		var query = PhysicsRayQueryParameters2D.create(origin, origin + test_dir * ray_length)
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return test_dir
	return preferred_dir

func _create_world_item() -> WorldItem:
	var item = WorldItem.new()
	var item_spr = Sprite2D.new()
	item_spr.name = "ItemSprite"
	item.add_child(item_spr)
	item.item_sprite = item_spr
	var shadow_spr = Sprite2D.new()
	shadow_spr.name = "ShadowSprite"
	shadow_spr.y_sort_enabled = false
	item.add_child(shadow_spr)
	item.shadow_sprite = shadow_spr
	var col_shape = CollisionShape2D.new()
	col_shape.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col_shape.shape = shape
	item.add_child(col_shape)
	item.collision = col_shape
	return item
