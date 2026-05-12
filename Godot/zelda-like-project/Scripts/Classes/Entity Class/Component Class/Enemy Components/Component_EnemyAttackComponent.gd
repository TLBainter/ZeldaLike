##[b][color=red]EnemyAttackComponent[/color][/b] holds the enemy's attack data and resolves per-attack Area2Ds.[br]
##[br]
##Each [b]AttackResource[/b] in [member attacks] stores an [b]attack_area[/b] node reference -[br]
##wired directly in the inspector to the Area2D for that attack.[br]
##[br]
##Each Area2D should contain one [b]CollisionShape2D[/b] per direction, named with a direction suffix:[br]
##e.g., "ShapeDown", "HitboxLeft", "CollisionUp". The suffix is matched against the end of the name.[br]
##[br]
##Each [b]AttackResource[/b] optionally specifies [member AttackResource.collision_shape_suffix] to[br]
##select a specific shape. When the suffix is empty, the current facing direction is used as the suffix.
class_name EnemyAttackComponent
extends Component

#region VARIABLES

@export_group("Attacks")
@export var attacks : Array[AttackResource] = []

@export_group("Melee Detection")
##Distance in pixels within which the enemy considers the player to be in melee range.
@export_range(0, 200, 1, "suffix:px") var melee_range : float = 32.0
##Distance from the attack area shape's world position within which melee triggers.
@export_range(0, 64, 1, "suffix:px") var melee_trigger_range : float = 8.0

#endregion VARIABLES

#region FUNCTIONS

##Returns the Area2D stored directly on [param res] via its [b]attack_area[/b] virtual property.
func get_area_for_attack(res : AttackResource) -> Area2D:
	if not res:
		return null
	return res.get(&"attack_area") as Area2D

##Returns the [CollisionShape2D] child of [param res]'s area whose name ends with the resolved suffix.[br]
##Resolves suffix from [param res.collision_shape_suffix], falling back to capitalized [param facing].
func get_collision_shape(res : AttackResource, facing : String) -> CollisionShape2D:
	var area := get_area_for_attack(res)
	if not area:
		return null
	var suffix : String = res.collision_shape_suffix if res and res.collision_shape_suffix != "" else facing.capitalize()
	for child in area.get_children():
		if child is CollisionShape2D and (child.name as String).ends_with(suffix):
			return child as CollisionShape2D
	return null

##Disables all CollisionShape2D children in [param res]'s area, then enables the one matching [param facing].
func set_active_shape(res : AttackResource, facing : String) -> void:
	var area := get_area_for_attack(res)
	if not area:
		return
	var suffix : String = res.collision_shape_suffix if res and res.collision_shape_suffix != "" else facing.capitalize()
	for child in area.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = not (child.name as String).ends_with(suffix)

##Returns [b]true[/b] if the player body is within [member melee_range] of the enemy body.
func is_player_in_melee_range(enemy_body : CharacterBody2D, player_pos : Vector2) -> bool:
	if not enemy_body:
		return false
	return enemy_body.global_position.distance_to(player_pos) <= melee_range

##Returns [b]true[/b] if [param player_pos] is within [member melee_trigger_range] of the attack shape's world position.
func is_player_near_attack_area(res : AttackResource, facing : String, player_pos : Vector2) -> bool:
	var shape := get_collision_shape(res, facing)
	if not shape:
		return false
	return shape.global_position.distance_to(player_pos) <= melee_trigger_range

##Returns the first MELEE_DIRECTIONAL or MELEE_AREA attack, or null.
func find_melee_attack() -> AttackResource:
	for att in attacks:
		if att.attack_type == AttackResource.AttackType.MELEE_DIRECTIONAL \
		or att.attack_type == AttackResource.AttackType.MELEE_AREA:
			return att
	return null

##Returns the first PROJECTILE_DIRECTIONAL or PROJECTILE_AREA attack, or null.
func find_projectile_attack() -> AttackResource:
	for att in attacks:
		if att.attack_type == AttackResource.AttackType.PROJECTILE_DIRECTIONAL \
		or att.attack_type == AttackResource.AttackType.PROJECTILE_AREA:
			return att
	return null

##Returns the best [AttackResource] for the current situation.[br]
##[b]in_melee[/b]: true -> returns first melee attack.[br]
##[b]aligned_for_projectile[/b]: true -> returns first projectile attack.[br]
##Returns null if no matching attack exists.
func get_best_attack(_facing : String, in_melee : bool, aligned_for_projectile : bool) -> AttackResource:
	if in_melee:
		return find_melee_attack()
	if aligned_for_projectile:
		return find_projectile_attack()
	return null

##Spawns a projectile from [param from_pos] traveling in [param dir].[br]
##[b]res[/b]: Projectile behavior data. [b]damage[/b]: Damage dealt on contact.
func spawn_projectile(res : ProjectileAttackResource, from_pos : Vector2, dir : Vector2, damage : int) -> void:
	if not res:
		return
	var entity := _find_entity_parent()
	if not entity:
		return
	var scene : PackedScene = load("res://Scenes/Projectiles/EnemyProjectile.tscn")
	if not scene:
		push_error("EnemyAttackComponent: could not load EnemyProjectile.tscn")
		return
	var proj := scene.instantiate() as EnemyProjectile
	if not proj:
		return
	proj.global_position = from_pos
	proj.setup(res, dir, damage)
	entity.get_parent().add_child(proj)
	_debug_log(str("Spawned projectile toward ", dir))

#endregion FUNCTIONS
