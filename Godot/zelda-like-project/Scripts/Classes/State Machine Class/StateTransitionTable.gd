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
		StateID.IDLE:           preload("res://Scripts/Classes/State Machine Class/Movement States/State_MovementState_StateIdling.gd"),
		StateID.MOVE:           preload("res://Scripts/Classes/State Machine Class/Movement States/State_MovementState_StateMove.gd"),
		StateID.RUN:            preload("res://Scripts/Classes/State Machine Class/Movement States/State_MovementState_StateRun.gd"),
		StateID.DASH:           preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateDash.gd"),
		StateID.BACKSTEP:       preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateBackstep.gd"),
		StateID.DASH_REBOUND:   preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateDashRebound.gd"),
		StateID.GRAB_IDLE:      preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateGrabIdle.gd"),
		StateID.PUSHING:        preload("res://Scripts/Classes/State Machine Class/Movement States/State_StatePushing.gd"),
		StateID.PULLING:        preload("res://Scripts/Classes/State Machine Class/Movement States/State_StatePulling.gd"),
		StateID.BAT_TRAVEL:     preload("res://Scripts/Classes/State Machine Class/Movement States/State_StateBatTravel.gd"),
		StateID.ATTACK:         preload("res://Scripts/Classes/State Machine Class/Action States/State_StateAttack.gd"),
		StateID.NO_ACTION:      preload("res://Scripts/Classes/State Machine Class/Action States/State_StateNoAction.gd"),
		StateID.INTERACT:       preload("res://Scripts/Classes/State Machine Class/Action States/State_StateInteract.gd"),
		StateID.GRAB:           preload("res://Scripts/Classes/State Machine Class/Action States/State_StateGrab.gd"),
		StateID.LIFT:           preload("res://Scripts/Classes/State Machine Class/Action States/State_StateLift.gd"),
		StateID.HOLDING_ACTION: preload("res://Scripts/Classes/State Machine Class/Action States/State_StateHoldingAction.gd"),
		StateID.THROW:          preload("res://Scripts/Classes/State Machine Class/Action States/State_StateThrow.gd"),
		StateID.DROP:           preload("res://Scripts/Classes/State Machine Class/Action States/State_StateDrop.gd"),
		StateID.KNOCKBACK:      preload("res://Scripts/Classes/State Machine Class/No Control States/State_NoControl_StateKnockback.gd"),
		StateID.INITIALIZED:    preload("res://Scripts/Classes/State Machine Class/No Control States/State_StateInitialized.gd"),
		# Enemy states — player coordinator ignores these (no matching state nodes)
		StateID.ROAM:           preload("res://Scripts/Classes/State Machine Class/No Control States/Enemy States/State_EnemyNoControl_StateRoam.gd"),
		StateID.CHASE:          preload("res://Scripts/Classes/State Machine Class/No Control States/Enemy States/State_EnemyNoControl_StateChase.gd"),
		StateID.COMBAT:         preload("res://Scripts/Classes/State Machine Class/No Control States/Enemy States/State_EnemyNoControl_StateCombat.gd"),
		StateID.DAMAGED:         preload("res://Scripts/Classes/State Machine Class/No Control States/Enemy States/State_EnemyNoControl_StateDamaged.gd"),
		StateID.DYING:          preload("res://Scripts/Classes/State Machine Class/No Control States/Enemy States/State_EnemyNoControl_StateDying.gd"),
		StateID.DEAD:           preload("res://Scripts/Classes/State Machine Class/No Control States/Enemy States/State_EnemyNoControl_StateDead.gd"),
		StateID.BLOCK:          preload("res://Scripts/Classes/State Machine Class/Action States/State_StateBlock_Player.gd"),
		StateID.ENEMY_ATTACK:   preload("res://Scripts/Classes/State Machine Class/Action States/State_EnemyAction_StateEnemyAttack.gd"),
	}
