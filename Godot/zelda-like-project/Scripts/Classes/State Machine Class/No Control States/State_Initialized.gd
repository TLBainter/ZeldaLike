##[b][color=red]StateIntialized[/color][/b] is the default No Control States.[br]
##While in this state, the character has full control over Movement and Action layers.[br]
##This is the starting state for the No Control layer after the character is intialized (set up).[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StateInitialized
extends State

#region FUNCTIONS

func enter():
	super()
	coordinator.unfreeze_all()

#endregion FUNCTIONS
