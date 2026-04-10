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
const BAT_FORM = "bat_form"
const BAT_FORM_UPGRADED = "bat_form_upgraded"
const ALBEDO_HOOD = "albedo_hood"
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
const PIECE_OF_HEART  = "piece_of_heart"
const MAGIC_MEDALLION = "magic_medallion"
const ENERGY_BOLT     = "energy_bolt"
#endregion UPGRADES

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
	"mobility":   [WAVEWALK_BOOTS, BAT_FORM, BAT_FORM_UPGRADED, ALBEDO_HOOD],
	"concoction": [ARCANE_SALVE, BLOOD_SALVE, ENERGIZING_SALVE, RESTORATIVE_SALVE],
	"dungeon":    [KEY, MAP, NOTEBOOK],
	"upgrade":    [PIECE_OF_HEART, MAGIC_MEDALLION, ENERGY_BOLT],
	"money":      [WHITE_BEAD, BLUE_BEAD, PURPLE_BEAD, ORANGE_BEAD],
}
#endregion CATEGORIES=======#

#region UPGRADES=======#
##Maps an item to its upgraded replacement.[br]
##Used by the debug console's /upgrade command and future upgrade systems.
const UPGRADES : Dictionary = {
	BAT_FORM: BAT_FORM_UPGRADED,
}
#endregion UPGRADES=======#
