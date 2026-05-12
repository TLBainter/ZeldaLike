class_name DungeonRegistry
extends Resource

@export var dungeon_item_prefix: Dictionary = {}
# Keys: dungeon name string, Values: item ID prefix string

func get_prefix(dungeon_name: String) -> String:
	if dungeon_item_prefix.has(dungeon_name):
		return dungeon_item_prefix[dungeon_name]
	push_warning("DungeonRegistry: no prefix for dungeon '%s'" % dungeon_name)
	return dungeon_name
