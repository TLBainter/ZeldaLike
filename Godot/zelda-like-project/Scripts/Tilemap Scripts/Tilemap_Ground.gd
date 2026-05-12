##[b][color=red]GroundTilemap[/color][/red] is a tilemap reference for the ground layer of a level.[br]
##This must be applied to ALL ground layers to ensure functionality of features like the player cam.[br]
##On ready, bakes per-tile navigation regions onto the default World2D navigation map so that
##[NavigationAgent2D] nodes (enemies) can path through walkable cells automatically.[br]
##Adjacent regions are stitched by the navigation server via [constant NavigationServer2D.region_set_use_edge_connections].[br]
##[method NavigationServer2D.map_force_update] is called after registration so the map is fully
##processed before any [NavigationAgent2D] path query occurs on the first frame.
class_name GroundTilemap
extends TileMapLayer

var _nav_region_rids : Array[RID] = []

func _ready() -> void:
	_build_navigation()

func _exit_tree() -> void:
	for rid in _nav_region_rids:
		NavigationServer2D.free_rid(rid)
	_nav_region_rids.clear()

func _build_navigation() -> void:
	var used := get_used_cells()
	if used.is_empty() or not tile_set:
		return
	# Exclude cells that overlap with sibling WallLayer TileMapLayers so the
	# navmesh doesn't cover physically blocked tiles (ground is painted under walls).
	var blocked_cells : Dictionary = {}
	var parent_node := get_parent()
	if parent_node:
		for sibling in parent_node.get_children():
			if sibling == self:
				continue
			if sibling is TileMapLayer and "Wall" in sibling.name:
				for wall_cell in (sibling as TileMapLayer).get_used_cells():
					blocked_cells[wall_cell] = true
	var nav_map : RID = get_world_2d().get_navigation_map()
	var ts : Vector2i = tile_set.tile_size
	var hx : float = ts.x / 2.0
	var hy : float = ts.y / 2.0
	var registered : int = 0
	for cell in used:
		if cell in blocked_cells:
			continue
		var center : Vector2 = map_to_local(cell)
		var poly := NavigationPolygon.new()
		poly.vertices = PackedVector2Array([
			center + Vector2(-hx, -hy),
			center + Vector2( hx, -hy),
			center + Vector2( hx,  hy),
			center + Vector2(-hx,  hy),
		])
		poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
		var region : RID = NavigationServer2D.region_create()
		NavigationServer2D.region_set_map(region, nav_map)
		NavigationServer2D.region_set_transform(region, global_transform)
		NavigationServer2D.region_set_navigation_polygon(region, poly)
		NavigationServer2D.region_set_use_edge_connections(region, true)
		NavigationServer2D.region_set_enabled(region, true)
		_nav_region_rids.append(region)
		registered += 1
	# Force synchronous map processing so the first frame's NavigationAgent2D
	# queries (including map_get_closest_point in roam) see a populated map.
	NavigationServer2D.map_force_update(nav_map)
	print_rich("[color=cyan]GroundTilemap[/color]: nav built - ", registered,
		" tile regions (skipped ", used.size() - registered, " wall cells) on map ", nav_map)
