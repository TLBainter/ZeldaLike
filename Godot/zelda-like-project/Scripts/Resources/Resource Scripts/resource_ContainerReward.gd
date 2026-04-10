##[b][color=red]ContainerRewardResource[/color][/b] defines what item a container gives the player.[br]
##Assign one of these to an [b]InteractableComponent_Container[/b] alongside a [b]ContainerResource[/b].[br]
##[b]NOTE[/b]: Enum key names must exactly match the constant names in [b]ItemID[/b]; the lookup is automatic.
class_name ContainerRewardResource
extends Resource

#region ENUM

enum ItemIDEnum {
	BLOOD_CLOT = 0,
	RED_GARNET = 1,
	RITUAL_STEEL = 2,
	STARDUST = 3,
	FULGURITE = 4,
	HEART = 5,
	KIDNEY = 6,
	METEORITE = 7,
	SPELL_GRAPPLE = 8,
	SPELL_IGNITE = 9,
	SPELL_HAMMER = 10,
	SPELL_SUMMON = 11,
	SPELL_HASTE = 12,
	WAVEWALK_BOOTS = 13,
	BAT_FORM = 14,
	BAT_FORM_UPGRADED = 15,
	ALBEDO_HOOD = 16,
	ARCANE_SALVE = 17,
	BLOOD_SALVE = 18,
	ENERGIZING_SALVE = 19,
	RESTORATIVE_SALVE = 20,
	KEY = 21,
	MAP = 22,
	NOTEBOOK = 23,
	PIECE_OF_HEART = 24,
	MAGIC_MEDALLION = 25,
	ENERGY_BOLT = 26,
	WHITE_BEAD = 27,
	BLUE_BEAD = 28,
	PURPLE_BEAD = 29,
	ORANGE_BEAD = 30
}

##Resolves [b]ItemIDEnum[/b] integer values to [b]ItemID[/b] strings via reflection.[br]
##Enum key names must match [b]ItemID[/b] constant names exactly to avoid manual mapping.
const _ITEM_ID_SCRIPT : GDScript = preload("res://Scripts/Constants/const_itemIDs.gd")

#endregion ENUM

#region EXPORTS

@export_category("Reward")
##Select the item this chest rewards. The matching [b]ItemID[/b] string is resolved automatically.
@export var item : ItemIDEnum = ItemIDEnum.KEY
##How many of this item the player receives.
@export var quantity : int = 1
##The item resource for this reward. Used to look up [b]first_get_dialogue_ref[/b] and item visuals.
@export var item_resource : ItemResource

#endregion EXPORTS

#region COMPUTED

##Returns the [b]ItemID[/b] string for the selected [b]item[/b] enum value.
var item_id : String:
	get: return _ITEM_ID_SCRIPT.get_script_constant_map()[ItemIDEnum.find_key(item)]

#endregion COMPUTED
