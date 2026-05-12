@tool
@icon("res://Editor Tools/Icons/icon_level.svg")
class_name Level
extends Node2D

enum LevelType { NONE, OVERWORLD, INTERIOR, CAVE, DUNGEON }

@export var level_type: LevelType = LevelType.NONE
@export var level_name: String = ""
@export var container_level: PackedScene:
	set(v):
		container_level = v
		if v and Engine.is_editor_hint():
			var inst := v.instantiate()
			if not _find_level_node(inst):
				push_warning("Level '%s': container_level scene has no Level node." % name)
			inst.free()

@export_group("Audio")
@export var default_song: SongResource

@export_group("Dungeon")
@export var door_resource: DoorResource
@export var boss_door_resource: DoorResource

##Controls the default respawn behaviour for enemies placed in this level.
##[constant EnemyRespawnMode.DEFAULT] cascades to the [member container_level]'s setting.
enum EnemyRespawnMode { DEFAULT, ON_RETURN, ON_RE_ENTER, ON_RELOAD, NEVER }

@export_group("Enemies")
@export var enemy_respawn: EnemyRespawnMode = EnemyRespawnMode.DEFAULT

@export_group("Parent Entrance")
## Doors in this list count as designated entrances. Entering through any of them records this level as the reload destination.
@export var level_entrances: Array[NodePath] = []
## The door used as the spawn point when no entrance has been recorded yet.
@export_node_path("Door") var default_entrance: NodePath

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	enemyManager.notify_area_changed(get_area_path())

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	musicManager.request_song(default_song)

func _validate_property(property: Dictionary) -> void:
	if property.name in ["door_resource", "boss_door_resource"] and level_type != LevelType.DUNGEON:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func get_effective_type() -> LevelType:
	if level_type != LevelType.NONE:
		return level_type
	if not container_level:
		return LevelType.NONE
	var inst := container_level.instantiate()
	var lvl := _find_level_node(inst)
	var result := lvl.get_effective_type() if lvl else LevelType.NONE
	inst.free()
	return result

func get_effective_door_resource() -> DoorResource:
	if door_resource:
		return door_resource
	if not container_level:
		return null
	var inst := container_level.instantiate()
	var lvl := _find_level_node(inst)
	var result := lvl.get_effective_door_resource() if lvl else null
	inst.free()
	return result

func get_effective_boss_door_resource() -> DoorResource:
	if boss_door_resource:
		return boss_door_resource
	if not container_level:
		return null
	var inst := container_level.instantiate()
	var lvl := _find_level_node(inst)
	var result := lvl.get_effective_boss_door_resource() if lvl else null
	inst.free()
	return result

func get_effective_name() -> String:
	if not level_name.is_empty():
		return level_name
	if not container_level:
		return ""
	var inst := container_level.instantiate()
	var lvl := _find_level_node(inst)
	var result := lvl.get_effective_name() if lvl else ""
	inst.free()
	return result

##Returns the area identifier used by [b]enemyManager[/b] to track the current dungeon/region.[br]
##Rooms that share a [member container_level] are part of the same area.
func get_area_path() -> String:
	if container_level:
		return container_level.resource_path
	return scene_file_path

##Returns the resolved [enum Enemy.Respawn] mode for enemies in this level.[br]
##Cascades to [member container_level] when [member enemy_respawn] is [constant EnemyRespawnMode.DEFAULT].
func get_effective_enemy_respawn() -> Enemy.Respawn:
	if enemy_respawn != EnemyRespawnMode.DEFAULT:
		match enemy_respawn:
			EnemyRespawnMode.ON_RETURN:   return Enemy.Respawn.ON_RETURN
			EnemyRespawnMode.ON_RE_ENTER: return Enemy.Respawn.ON_RE_ENTER
			EnemyRespawnMode.ON_RELOAD:   return Enemy.Respawn.ON_RELOAD
			EnemyRespawnMode.NEVER:       return Enemy.Respawn.NEVER
	if container_level:
		var inst := container_level.instantiate()
		var lvl := _find_level_node(inst)
		var result: Enemy.Respawn = lvl.get_effective_enemy_respawn() if lvl else Enemy.Respawn.ON_RETURN
		inst.free()
		return result
	return Enemy.Respawn.ON_RETURN

func _find_level_node(node: Node) -> Level:
	if node is Level:
		return node
	for child in node.get_children():
		var found := _find_level_node(child)
		if found:
			return found
	return null

static func get_level_ancestor(node: Node) -> Level:
	var current := node.get_parent()
	while current:
		if current is Level:
			return current
		current = current.get_parent()
	return null
