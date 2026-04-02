##[b][color=red]ImmediateEffect[/color][/b] defines a single effect applied once on item use.[br]
##Used within [b]ItemFunction[/b]'s immediate_effects array.
class_name ImmediateEffect
extends Resource

@export var action : EffectEnums.EffectAction = EffectEnums.EffectAction.ADD
@export var amount : int = 0
@export var target : EffectEnums.EffectTarget = EffectEnums.EffectTarget.HEALTH
