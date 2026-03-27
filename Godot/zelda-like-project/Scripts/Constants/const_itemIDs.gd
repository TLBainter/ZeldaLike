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
const ALBEDO_HOOD = "albedo_hood"
#endregion MOBILITY ITEMS

#region CONCOCTIONS

#endregion CONCOCTIONS

#region CATEGORIES=======#
const CATEGORIES : Dictionary = {
	"spell": [SPELL_GRAPPLE, SPELL_IGNITE, SPELL_HAMMER, SPELL_SUMMON, SPELL_HASTE],
	"ingredient": [BLOOD_CLOT, RED_GARNET, RITUAL_STEEL, STARDUST, FULGURITE, HEART, KIDNEY, METEORITE],
	"mobility": [WAVEWALK_BOOTS, BAT_FORM, ALBEDO_HOOD]
}
#endregion CATEGORIES=======#
