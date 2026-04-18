##[b][color=red]ItemFunction[/color][/b] is the base resource defining what an item does when used.[br]
##Contains arrays of [b]ImmediateEffect[/b], [b]OngoingEffect[/b], and [b]PermanentEffect[/b] resources.
class_name ItemFunction
extends Resource

#region VARIABLES

@export_category("Immediate Effects")
##Effects applied once when the item is used.
@export var immediate_effects : Array[ImmediateEffect] = []

@export_category("Ongoing Effects")
##Effects applied repeatedly over time.
@export var ongoing_effects : Array[OngoingEffect] = []

@export_category("Duration")
##How long ongoing effects last (in seconds). 0 = no ongoing effects.
@export var ongoing_duration : float = 0.0

@export_category("Permanent Effects")
##Permanent stat-maximum increases granted by this item.
@export var permanent_effects : Array[PermanentEffect] = []
##Controls when permanent effects are applied.[br]
##[b]ON_GET[/b]: immediately on pickup (e.g. arcane shard → +1 max magic).[br]
##[b]ON_COMPLETE[/b]: only when a full part-set is formed (e.g. bone shards → +4 max health on skull completion).
@export var permanent_effect_timing : EffectEnums.PermanentEffectTiming = EffectEnums.PermanentEffectTiming.ON_GET

#endregion VARIABLES

#region FUNCTIONS

##Returns whether this item has any ongoing effects.
func has_ongoing_effects() -> bool:
	return not ongoing_effects.is_empty() and ongoing_duration > 0.0

##Returns whether this item has any permanent effects.
func has_permanent_effects() -> bool:
	return not permanent_effects.is_empty()

#endregion FUNCTIONS
