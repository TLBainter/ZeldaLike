##[b][color=red]EffectEnums[/color][/b] contains shared enums for the item effect system.[br]
##Referenced by [b]ImmediateEffect[/b], [b]OngoingEffect[/b], and [b]ItemFunction[/b].
class_name EffectEnums

##What operation to perform.
enum EffectAction {
	ADD,
	SUBTRACT,
}

##Which player resource to affect.
enum EffectTarget {
	HEALTH,
	ENERGY,
	MAGIC,
}
