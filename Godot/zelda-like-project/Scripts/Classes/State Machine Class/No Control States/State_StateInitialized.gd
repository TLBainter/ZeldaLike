##[b][color=red]StateIntialized[/color][/b] is the default No Control States.[br]
##While in this state, the character has full control over Movement and Action layers.[br]
##This is the starting state for the No Control layer after the character is intialized (set up).[br]
##For enemies, immediately dispatches to the default AI state configured on the enemy's input component.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StateInitialized
extends State

#region FUNCTIONS

func enter():
	super()
	coordinator.unfreeze_all()
	var enemy := root as Enemy
	if not enemy:
		return
	var input : EnemyInputComponent = enemy.get("input") as EnemyInputComponent
	if not input:
		return
	match input.default_mode:
		EnemyInputComponent.AIMode.ROAM:
			_safe_transition.call_deferred(StateID.ROAM)
		EnemyInputComponent.AIMode.IDLE:
			_safe_transition.call_deferred(StateID.IDLE)

#endregion FUNCTIONS
