##[b][color=red]SpellResource[/color][/b] extends [b]MenuItemResource[/b] with spell-specific casting data.[br]
##Used by [b]EquippedSpellsComponent[/b] slots and read by [b]StateCastSpell[/b] during casting.
class_name SpellResource
extends MenuItemResource

@export_group("Spell Settings")
##Magic shards consumed when this spell is cast.[br]
##Checked and consumed in [b]StateCastSpell.enter()[/b].
@export var magic_cost: int = 0
##Prefix for the directional cast animation.[br]
##Direction suffix is appended automatically (e.g. "SpellCastHammer" → "SpellCastHammerDown").[br]
##Defaults to "SpellCast" if not set.
@export var cast_animation_prefix: String = "SpellCast"
