##[b][color=red]ItemFunction[/color][/b] is the base resource defining what an item does when used.[br]
##Contains arrays of [b]ImmediateEffect[/b] and [b]OngoingEffect[/b] resources with a duration.
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

#endregion VARIABLES

#region FUNCTIONS

##Returns whether this item has any ongoing effects.
func has_ongoing_effects() -> bool:
	return not ongoing_effects.is_empty() and ongoing_duration > 0.0

#endregion FUNCTIONS
