##[b][color=red]ItemID[/color][/b] is a class of global constants containing Item IDs.[br]
##Use these constants everywhere item IDs are needed to reference the items consistently.
##Example: [code]ItemID.BLOOD_CLOT[/code]
class_name ItemID
extends Node

#region INGREDIENTS

const BLOOD_CLOT = "blood_clot"
const RED_GARNET = "red_garnet"
const RITUAL_STEEL = "ritual_steel"
const STARDUST = "stardust"
const FULGURITE = "fulgurite"
const HEART = "heart"
const KIDNEY = "kidney"
const METEORITE = "meteorite"

#endregion INGREDIENTS

#region SPELLS
const SPELL_GRAPPLE = "spell_grapple"
const SPELL_IGNITE = "spell_ignite"
const SPELL_HAMMER = "spell_hammer"
const SPELL_SUMMON = "spell_summon"
const SPELL_HASTE = "spell_haste"
#endregion SPELLS

#region MOBILITY ITEMS
const WAVEWALK_BOOTS = "wavewalk_boots"
const WAVEWALK_BOOTS_UPGRADED = "wavewalk_boots_upgraded"
const BAT_FORM = "bat_form"
const BAT_FORM_UPGRADED = "bat_form_upgraded"
const ALBEDO_HOOD = "albedo_hood"
const ALBEDO_HOOD_UPGRADED = "albedo_hood_upgraded"
#endregion MOBILITY ITEMS

#region CONCOCTIONS
const ARCANE_SALVE = "arcane_salve"
const BLOOD_SALVE = "blood_salve"
const ENERGIZING_SALVE = "energizing_salve"
const RESTORATIVE_SALVE = "restorative_salve"
#endregion CONCOCTIONS

#region DUNGEON ITEMS
const KEY      = "key"
const MAP      = "map"
const NOTEBOOK = "notebook"
#endregion DUNGEON ITEMS

#region UPGRADES
const BONE_SHARD  = "bone_shard"
const ARCANE_SHARD = "arcane_shard"
const GLAND     = "gland"
#endregion UPGRADES

#region RECOVERY
const ENERGY_ORB = "energy_orb"
const TOOTH = "tooth"
const CRYSTAL_SHARD = "crystal"
#endregion RECOVERY

#region MONEY
const WHITE_BEAD = "white_bead"
const BLUE_BEAD = "blue_bead"
const PURPLE_BEAD = "purple_bead"
const ORANGE_BEAD = "orange_bead"
#endregion MONEY

#region CATEGORIES=======#
const CATEGORIES : Dictionary = {
	"spell":      [SPELL_GRAPPLE, SPELL_IGNITE, SPELL_HAMMER, SPELL_SUMMON, SPELL_HASTE],
	"ingredient": [BLOOD_CLOT, RED_GARNET, RITUAL_STEEL, STARDUST, FULGURITE, HEART, KIDNEY, METEORITE],
	"mobility":   [WAVEWALK_BOOTS, BAT_FORM, BAT_FORM_UPGRADED, ALBEDO_HOOD, ALBEDO_HOOD_UPGRADED, WAVEWALK_BOOTS_UPGRADED],
	"concoction": [ARCANE_SALVE, BLOOD_SALVE, ENERGIZING_SALVE, RESTORATIVE_SALVE],
	"dungeon":    [KEY, MAP, NOTEBOOK],
	"upgrade":    [BONE_SHARD, ARCANE_SHARD, GLAND],
	"recovery":   [ENERGY_ORB, TOOTH, CRYSTAL_SHARD],
	"money":      [WHITE_BEAD, BLUE_BEAD, PURPLE_BEAD, ORANGE_BEAD],
}
#endregion CATEGORIES=======#

#region UPGRADES=======#
##Maps an item to its upgraded replacement.[br]
##Used by the debug console's /upgrade command and future upgrade systems.
const MOBILITY_UPGRADES : Dictionary = {
	BAT_FORM: BAT_FORM_UPGRADED,
	ALBEDO_HOOD: ALBEDO_HOOD_UPGRADED,
	WAVEWALK_BOOTS: WAVEWALK_BOOTS_UPGRADED
}
#endregion UPGRADES=======#

#region ITEM RESOURCES=======#
##Maps each item ID to its [b]ItemResource[/b] .tres file.[br]
##Add an entry here whenever a new ItemResource asset is created.
const ITEM_RESOURCES : Dictionary = {
	TOOTH:           preload("res://Scripts/Resources/Resource Files/Resources_Items/item_small_heart.tres"),
	WHITE_BEAD:      preload("res://Scripts/Resources/Resource Files/Resources_Items/item_bead_1.tres"),
	BLUE_BEAD:       preload("res://Scripts/Resources/Resource Files/Resources_Items/item_bead_5.tres"),
	PURPLE_BEAD:     preload("res://Scripts/Resources/Resource Files/Resources_Items/item_bead_10.tres"),
	ORANGE_BEAD:     preload("res://Scripts/Resources/Resource Files/Resources_Items/item_bead_25.tres"),
	ENERGY_ORB:     preload("res://Scripts/Resources/Resource Files/Resources_Items/item_energy_orb.tres"),
	CRYSTAL_SHARD: preload("res://Scripts/Resources/Resource Files/Resources_Items/item_magic_shard.tres"),
}
#endregion ITEM RESOURCES=======#

#region MENU ITEM RESOURCES=======#
##Maps each item ID to its [b]MenuItemResource[/b] .tres file.[br]
##Used by ContainerRewardResource for non-Money chest rewards.
const MENU_ITEM_RESOURCES : Dictionary = {
	# Spells
	SPELL_GRAPPLE:          preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_spellGrapple.tres"),
	SPELL_IGNITE:           preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_spellIgnite.tres"),
	SPELL_HAMMER:           preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_spellHammer.tres"),
	SPELL_SUMMON:           preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_spellSummon.tres"),
	SPELL_HASTE:            preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_spellHaste.tres"),
	# Mobility
	WAVEWALK_BOOTS:         preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_boots.tres"),
	WAVEWALK_BOOTS_UPGRADED:preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_bootsUpgraded.tres"),
	BAT_FORM:               preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_bat.tres"),
	BAT_FORM_UPGRADED:      preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_batUpgraded.tres"),
	ALBEDO_HOOD:            preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_hood.tres"),
	ALBEDO_HOOD_UPGRADED:   preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_hoodUpgraded.tres"),
	# Ingredients
	BLOOD_CLOT:             preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_bloodClot.tres"),
	RED_GARNET:             preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_redGarnet.tres"),
	RITUAL_STEEL:           preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_ritualSteel.tres"),
	STARDUST:               preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_stardust.tres"),
	FULGURITE:              preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_fulgurite.tres"),
	HEART:                  preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_heart.tres"),
	KIDNEY:                 preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_kidney.tres"),
	METEORITE:              preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_meteorite.tres"),
	# Concoctions
	ARCANE_SALVE:           preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_arcaneSalve.tres"),
	BLOOD_SALVE:            preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_bloodSalve.tres"),
	ENERGIZING_SALVE:       preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_energizingSalve.tres"),
	RESTORATIVE_SALVE:      preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/resource_menuItem_restorativeSalve.tres"),
	# Upgrades
	BONE_SHARD:             preload("res://Scripts/Resources/Resource Files/Resources_MenuItems/Resources_MenuItems_Upgrades/resource_menuItem_boneShard.tres"),
	# Dungeon items — add entries here once MenuItemResources are created for KEY, MAP, NOTEBOOK
}
#endregion MENU_ITEM RESOURCES=======#
