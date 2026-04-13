##[b][color=red]ContainerRewardResource[/color][/b] defines what item a container gives the player.[br]
##Assign one of these to an [b]InteractableComponent_Container[/b] alongside a [b]ContainerResource[/b].[br]
##Set [b]item_kind[/b] first — the [b]item[/b] dropdown will filter to matching items automatically.
@tool
class_name ContainerRewardResource
extends Resource

#region ENUM

enum ItemKind {
	PROGRESSION,  ## Spells and mobility items
	DUNGEON_ITEM, ## Key, map, notebook
	UPGRADE,      ## Piece of heart, magic medallion, energy bolt
	INGREDIENT,   ## Crafting ingredients
	MONEY,        ## Currency / notes
}

#endregion ENUM

#region CONSTANTS

const _ITEM_ID_SCRIPT : GDScript = preload("res://Scripts/Constants/const_itemIDs.gd")

## Maps each [b]ItemKind[/b] to the [b]ItemID.CATEGORIES[/b] keys it covers.
const _KIND_CATEGORIES : Dictionary = {
	ItemKind.PROGRESSION:  ["spell", "mobility"],
	ItemKind.DUNGEON_ITEM: ["dungeon"],
	ItemKind.UPGRADE:      ["upgrade"],
	ItemKind.INGREDIENT:   ["ingredient"],
	ItemKind.MONEY:        ["money"],
}

#endregion CONSTANTS

#region EXPORTS

@export_category("Reward")
##The category of item this chest contains.[br]
##Changing this filters the [b]item[/b] dropdown to matching items only.
@export var item_kind : ItemKind = ItemKind.DUNGEON_ITEM:
	set(v):
		item_kind = v
		# Clear the selected item if it no longer belongs to the new kind.
		if _item != "" and not _is_item_valid_for_kind(_item, v):
			_item = ""
		notify_property_list_changed()
		emit_changed()

#endregion EXPORTS

#region PROPERTIES

var _item : String = "key"

##The [b]ItemID[/b] string for the selected item.
var item_id : String:
	get: return _item

##The item resource for this reward, resolved automatically from [b]ItemID.ITEM_RESOURCES[/b].[br]
##Returns [code]null[/code] if no resource file has been registered for this item yet.
var item_resource : ItemResource:
	get:
		var resources = _ITEM_ID_SCRIPT.get_script_constant_map().get("ITEM_RESOURCES", {})
		return resources.get(_item, null)

##Always [code]1[/code] — containers grant exactly one of the reward item.
var quantity : int = 1

#endregion PROPERTIES

#region DYNAMIC PROPERTY LIST

func _is_item_valid_for_kind(item_id_str : String, kind : ItemKind) -> bool:
	var categories : Dictionary = _ITEM_ID_SCRIPT.get_script_constant_map().get("CATEGORIES", {})
	for cat_key in _KIND_CATEGORIES.get(kind, []):
		if item_id_str in categories.get(cat_key, []):
			return true
	return false

func _get_property_list() -> Array[Dictionary]:
	var constants := _ITEM_ID_SCRIPT.get_script_constant_map()
	var categories : Dictionary = constants.get("CATEGORIES", {})

	var allowed : Array = []
	for cat_key in _KIND_CATEGORIES.get(item_kind, []):
		allowed.append_array(categories.get(cat_key, []))
	allowed.sort()

	return [{
		"name": "item",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(PackedStringArray(allowed)),
	}]

func _get(property: StringName) -> Variant:
	if property == &"item":
		return _item
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == &"item":
		_item = value
		emit_changed()
		return true
	return false

#endregion DYNAMIC PROPERTY LIST
