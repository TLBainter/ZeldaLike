##[b][color=red]StatsComponent[/color][/b] holds the [b]StatsResource[/b] for an entity.[br]
##Other components read their initial values from this component via root.stats.resource.
class_name StatsComponent
extends Component

#region VARIABLES

@export_category("Stats")
## The stats resource defining this entity's base stats.
@export var resource : StatsResource

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	if not resource:
		printerr(debug_name, ": No StatsResource assigned!")

#endregion FUNCTIONS
