##[b][color=red]OngoingEffect[/color][/b] defines a single effect applied repeatedly over time.[br]
##Used within [b]ItemFunction[/b]'s ongoing_effects array.
class_name OngoingEffect
extends Resource

@export var action : EffectEnums.EffectAction = EffectEnums.EffectAction.ADD
@export var amount : int = 0
@export var target : EffectEnums.EffectTarget = EffectEnums.EffectTarget.HEALTH
##How often this effect ticks (in seconds).
@export var interval : float = 1.0
