##[b][color=red]EffectEnums[/color][/b] contains shared enums for the item effect system.[br]
##Referenced by [b]ImmediateEffect[/b], [b]OngoingEffect[/b], [b]PermanentEffect[/b], and [b]ItemFunction[/b].
class_name EffectEnums

##What operation to perform.
enum EffectAction {
	ADD,
	SUBTRACT,
}

##Which player resource to affect (current value).
enum EffectTarget {
	HEALTH,
	ENERGY,
	MAGIC,
}

##Which player stat maximum to raise permanently.
enum PermanentEffectTarget {
	MAX_HEALTH,
	MAX_MAGIC,
	MAX_ENERGY,
}

##When a permanent effect is applied.[br]
##[b]ON_GET[/b]: applied as soon as the item is obtained (e.g. an arcane shard that raises max magic immediately).[br]
##[b]ON_COMPLETE[/b]: applied only when a full part-set is formed (e.g. bone shards → skull grants max health).
enum PermanentEffectTiming {
	ON_GET,
	ON_COMPLETE,
}
