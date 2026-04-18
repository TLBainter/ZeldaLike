##[b][color=red]PermanentEffect[/color][/b] defines a single permanent stat-maximum increase applied on item collection.[br]
##Used within [b]ItemFunction[/b]'s permanent_effects array.[br]
##When and how it fires is controlled by [b]ItemFunction[/b].permanent_effect_timing.
class_name PermanentEffect
extends Resource

##How much to add to the chosen maximum.
@export var amount: int = 0
##Which stat maximum to raise.
@export var target: EffectEnums.PermanentEffectTarget = EffectEnums.PermanentEffectTarget.MAX_HEALTH
