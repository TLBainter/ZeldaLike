##[b][color=red]Noninteractable[/color][/b] refers to any object that cannot be interacted with,[br]
##and is simply used to decorate the world.[br]
class_name Noninteractable
extends Thing

#region VARIABLES
#region EXPORT VARIABLES
##the purpose of this noninteractable; affects what it is able to do in the world.[br]
##[b]Decor[/b]: Does nothing.
##[b]Light Source[/b]: Illuminates the scene.
##[b]Receiver[/b]: Receives a signal and reacts to it.
@export_enum("Decor", "Light Source", "Receiver") var purpose : String
#endregion
#endregion

#region FUNCTIONS
#region READY
func _ready():
	super._ready()
	#establish variables
	subtype = "Noninteractable"
