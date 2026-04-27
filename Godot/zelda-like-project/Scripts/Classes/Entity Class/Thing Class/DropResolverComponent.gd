##[b][color=red]DropResolverComponent[/color][/b] handles drop scatter physics, world item creation, and scene insertion.[br]
##Add as a child node of a [b]DynamicThing[/b] and assign [member drop_table] in the inspector.[br]
##Call [method resolve_and_spawn] from the entity's break logic.
class_name DropResolverComponent
extends Node2D

##The drop table resource that determines what items are dropped.
@export var drop_table : DropTable

##Resolves drops from [member drop_table] and spawns world items with scatter physics.[br]
##[b]origin[/b]: The Node2D whose [code]global_position[/code] is used as the spawn origin (typically the entity body).[br]
##[b]source_pos[/b]: The position of the damage source; used to compute directional scatter.[br]
##[b]damaged_by_attack[/b]: Whether the entity was destroyed by an attack (affects scatter direction and impulse).
func resolve_and_spawn(origin: Node2D, source_pos: Vector2, damaged_by_attack: bool) -> void:
	if not drop_table:
		return
	var player = _find_player()
	var drops : Array[PickupResource] = drop_table.resolve(player)
	if drops.is_empty():
		return
	var spawn_pos : Vector2 = origin.global_position if origin else Vector2.ZERO
	var space_state = get_world_2d().direct_space_state
	var base_scatter_dir : Vector2 = Vector2.ZERO
	if damaged_by_attack and source_pos != Vector2.ZERO:
		base_scatter_dir = (spawn_pos - source_pos).normalized()
	for i in range(drops.size()):
		var pickup = drops[i]
		if not pickup:
			continue
		var world_item = _create_world_item()
		world_item.pickup_data = pickup
		get_tree().current_scene.add_child(world_item)
		var scatter_dir : Vector2
		if base_scatter_dir != Vector2.ZERO:
			var spread_angle = randf_range(-0.6, 0.6)
			scatter_dir = base_scatter_dir.rotated(spread_angle)
		else:
			var scatter_angle = (TAU / max(drops.size(), 1)) * i + randf_range(-0.3, 0.3)
			scatter_dir = Vector2(cos(scatter_angle), sin(scatter_angle))
		scatter_dir = _find_clear_direction(space_state, spawn_pos, scatter_dir)
		var spawn_offset = scatter_dir * 12.0
		var item_spawn_pos = spawn_pos + spawn_offset + Vector2(0, -8)
		var impulse = 60.0 if damaged_by_attack else 0.0
		world_item.spawn(item_spawn_pos, spawn_pos.y + spawn_offset.y, scatter_dir, impulse)

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
		query.collision_mask = (1 << 3) | (1 << 4) | (1 << 5)
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
