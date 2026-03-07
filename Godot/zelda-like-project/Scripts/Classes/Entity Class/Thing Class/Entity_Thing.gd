##[b][color=red]Object[/color][/b] refers to any object that can be placed in the world,[br]
##regardless of whether the object can be interacted with.[br]
##This includes chests, switches, breakable pots, torches, and more.
class_name Thing
extends EntityClass

#region VARIABLES
#region EXPORT VARIABLES



#endregion
#region INTERNAL VARIABLES
##the subtype of this thing; set by its subclass.
var subtype : String
#endregion
#endregion

#region FUNCTIONS
#region READY
func _ready():
	super._ready()
	#establish variables
	type = "Thing"
	add_to_group("entities")
