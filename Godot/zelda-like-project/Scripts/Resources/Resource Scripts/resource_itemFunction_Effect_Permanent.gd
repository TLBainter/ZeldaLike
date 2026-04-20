##[b][color=red]PermanentEffect[/color][/b] defines a single permanent stat-maximum increase applied on item collection.[br]
##Used within [b]ItemFunction[/b]'s permanent_effects array.[br]
##Each effect carries its own timing, allowing mixed ON_GET / ON_COMPLETE effects on the same item.
class_name PermanentEffect
extends Resource

##How much to add to the chosen maximum.
@export var amount: int = 0
##Which stat maximum to raise.
@export var target: EffectEnums.PermanentEffectTarget = EffectEnums.PermanentEffectTarget.MAX_HEALTH
##When this effect fires.[br]
##[b]ON_GET[/b]: immediately on pickup.[br]
##[b]ON_COMPLETE[/b]: only when a full part-set is formed.
@export var timing: EffectEnums.PermanentEffectTiming = EffectEnums.PermanentEffectTiming.ON_GET
