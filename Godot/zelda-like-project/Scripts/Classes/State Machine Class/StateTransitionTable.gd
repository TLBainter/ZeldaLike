##[b][color=red]StateTransitionTable[/color][/b] maps logical transition keys to GDScript resources.[br]
##Assign this to a [b]StateCoordinator[/b] to configure which concrete state class handles each role.[br]
##[br]
##[b]Default behavior:[/b] [method _init] pre-populates all 17 standard state mappings.[br]
##To override a mapping (e.g., swap "idle" for an exhausted idle variant), create a new[br]
##StateTransitionTable resource in the editor and change only the target entry.[br]
##[br]
##Keys match the strings passed to [method StateCoordinator.get_transition].
class_name StateTransitionTable
extends Resource

##Maps string keys → GDScript Script resources.[br]
##[method StateCoordinator.get_transition] looks up the script here, then resolves it[br]
##against the coordinator's discovered state registry.
@export var transitions: Dictionary = {}

func _init() -> void:
	transitions = {
		# Movement Layer
		"idle":           preload("res://Scripts/Classes/State Machine Class/Movement States/State_Idling.gd"),
		"move":           preload("res://Scripts/Classes/State Machine Class/Movement States/State_Move.gd"),
		"run":            preload("res://Scripts/Classes/State Machine Class/Movement States/State_Run.gd"),
		"dash":           preload("res://Scripts/Classes/State Machine Class/Movement States/State_Dash.gd"),
		"backstep":       preload("res://Scripts/Classes/State Machine Class/Movement States/State_Backstep.gd"),
		"dash_rebound":   preload("res://Scripts/Classes/State Machine Class/Movement States/State_DashRebound.gd"),
		"grab_idle":      preload("res://Scripts/Classes/State Machine Class/Movement States/State_GrabIdle.gd"),
		"pushing":        preload("res://Scripts/Classes/State Machine Class/Movement States/State_Pushing.gd"),
		"pulling":        preload("res://Scripts/Classes/State Machine Class/Movement States/State_Pulling.gd"),
		"bat_travel":     preload("res://Scripts/Classes/State Machine Class/Movement States/State_BatTravel.gd"),
		# Action Layer
		"attack":         preload("res://Scripts/Classes/State Machine Class/Action States/State_Attack.gd"),
		"no_action":      preload("res://Scripts/Classes/State Machine Class/Action States/State_NoAction.gd"),
		"interact":       preload("res://Scripts/Classes/State Machine Class/Action States/State_Interact.gd"),
		"grab":           preload("res://Scripts/Classes/State Machine Class/Action States/State_Grab.gd"),
		"lift":           preload("res://Scripts/Classes/State Machine Class/Action States/State_Lift.gd"),
		"holding_action": preload("res://Scripts/Classes/State Machine Class/Action States/State_HoldingAction.gd"),
		"throw":          preload("res://Scripts/Classes/State Machine Class/Action States/State_Throw.gd"),
		"drop":           preload("res://Scripts/Classes/State Machine Class/Action States/State_Drop.gd"),
	}
