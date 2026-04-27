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
		StateKeys.IDLE:           preload("res://Scripts/Classes/State Machine Class/Movement States/State_MovementState_StateIdling.gd"),
		StateKeys.MOVE:           preload("res://Scripts/Classes/State Machine Class/Movement States/State_MovementState_StateMove.gd"),
		StateKeys.RUN:            preload("res://Scripts/Classes/State Machine Class/Movement States/State_MovementState_StateRun.gd"),
		StateKeys.DASH:           preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateDash.gd"),
		StateKeys.BACKSTEP:       preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateBackstep.gd"),
		StateKeys.DASH_REBOUND:   preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateDashRebound.gd"),
		StateKeys.GRAB_IDLE:      preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateGrabIdle.gd"),
		StateKeys.PUSHING:        preload("res://Scripts/Classes/State Machine Class/Movement States/State_StatePushing.gd"),
		StateKeys.PULLING:        preload("res://Scripts/Classes/State Machine Class/Movement States/State_StatePulling.gd"),
		StateKeys.BAT_TRAVEL:     preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateBatTravel.gd"),
		StateKeys.ATTACK:         preload("res://Scripts/Classes/State Machine Class/Action States/State_StateAttack.gd"),
		StateKeys.NO_ACTION:      preload("res://Scripts/Classes/State Machine Class/Action States/State_StateNoAction.gd"),
		StateKeys.INTERACT:       preload("res://Scripts/Classes/State Machine Class/Action States/State_StateInteract.gd"),
		StateKeys.GRAB:           preload("res://Scripts/Classes/State Machine Class/Action States/State_StateGrab.gd"),
		StateKeys.LIFT:           preload("res://Scripts/Classes/State Machine Class/Action States/State_StateLift.gd"),
		StateKeys.HOLDING_ACTION: preload("res://Scripts/Classes/State Machine Class/Action States/State_StateHoldingAction.gd"),
		StateKeys.THROW:          preload("res://Scripts/Classes/State Machine Class/Action States/State_StateThrow.gd"),
		StateKeys.DROP:           preload("res://Scripts/Classes/State Machine Class/Action States/State_StateDrop.gd"),
	}
