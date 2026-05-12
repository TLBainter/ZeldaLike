##[b][color=red]StateDead[/color][/b] - resolves the enemy's drop table, spawns pickups, then removes the enemy from the scene.
class_name StateDead
extends State

func enter() -> void:
	super()
	coordinator.freeze_all()
	var enemy := root as Enemy
	if not enemy:
		return
	var enemy_id := enemy.get_enemy_id()
	var drop_table := _get_drop_table(enemy, enemy_id)
	enemyManager.mark_killed(enemy_id, enemy.get_effective_respawn())
	_resolve_drops(enemy, drop_table)
	await get_tree().process_frame
	enemy.queue_free()

##Returns [member Enemy.alt_drop_table] if the enemy has been killed before and alt drop is configured;
##otherwise returns the standard [member Enemy.drop_table].
func _get_drop_table(enemy: Enemy, enemy_id: String) -> DropTable:
	if enemy.use_alt_drop_table and enemy.alt_drop_table != null \
			and enemyManager.has_been_killed_once(enemy_id):
		return enemy.alt_drop_table
	return enemy.drop_table

func _resolve_drops(enemy: Enemy, drop_table: DropTable) -> void:
	if not drop_table:
		return
	var player_node = get_tree().get_first_node_in_group("player")
	var drops : Array[PickupResource] = drop_table.resolve(player_node)
	if drops.is_empty():
		return
	var spawn_pos : Vector2 = enemy.body.global_position if enemy.body else enemy.global_position
	var space_state := enemy.body.get_world_2d().direct_space_state
	for i in range(drops.size()):
		var pickup_res := drops[i]
		if not pickup_res:
			continue
		var world_item := _create_world_item(pickup_res)
		get_tree().current_scene.add_child(world_item)
		var scatter_angle : float = (TAU / max(drops.size(), 1)) * i + randf_range(-0.3, 0.3)
		var scatter_dir := Vector2(cos(scatter_angle), sin(scatter_angle))
		scatter_dir = _find_clear_direction(space_state, spawn_pos, scatter_dir)
		var item_spawn_pos := spawn_pos + scatter_dir * 12.0 + Vector2(0, -8)
		world_item.spawn(item_spawn_pos, spawn_pos.y, scatter_dir, 60.0)

func _create_world_item(pickup_res : PickupResource) -> WorldItem:
	var item := WorldItem.new()
	var item_spr := Sprite2D.new()
	item_spr.name = "ItemSprite"
	item.add_child(item_spr)
	item.item_sprite = item_spr
	var shadow_spr := Sprite2D.new()
	shadow_spr.name = "ShadowSprite"
	shadow_spr.y_sort_enabled = false
	item.add_child(shadow_spr)
	item.shadow_sprite = shadow_spr
	var col_shape := CollisionShape2D.new()
	col_shape.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col_shape.shape = shape
	item.add_child(col_shape)
	item.collision = col_shape
	item.pickup_data = pickup_res
	return item

func _find_clear_direction(space_state : PhysicsDirectSpaceState2D, origin : Vector2, preferred_dir : Vector2) -> Vector2:
	var ray_length : float = 24.0
	var angle_step : float = TAU / 8.0
	for i in range(8):
		var test_angle : float = preferred_dir.angle() + angle_step * i
		var test_dir := Vector2(cos(test_angle), sin(test_angle))
		var query := PhysicsRayQueryParameters2D.create(origin, origin + test_dir * ray_length)
		query.collision_mask = (1 << 3) | (1 << 4) | (1 << 5)
		if space_state.intersect_ray(query).is_empty():
			return test_dir
	return preferred_dir
