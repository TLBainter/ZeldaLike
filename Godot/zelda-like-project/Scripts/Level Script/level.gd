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
