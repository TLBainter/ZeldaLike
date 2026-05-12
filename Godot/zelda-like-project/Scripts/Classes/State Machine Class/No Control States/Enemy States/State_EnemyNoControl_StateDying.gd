##[b][color=red]StateDying[/color][/b] - placeholder stub for enemy death animation.[br]
##When implemented, this state will play the dying animation and then transition to [b]StateDead[/b].
class_name StateDying
extends State

# TODO: play dying animation, await completion, then transition to StateDead

func enter() -> void:
	super()
	coordinator.freeze_all()
	var input := _get_input()
	if input:
		input.set_mode(EnemyInputComponent.AIMode.IDLE)
	# TODO: play dying animation/effects here, then call _finish_dying() on completion.
	_finish_dying.call_deferred()

func _finish_dying() -> void:
	_safe_transition(StateID.DEAD)

func _get_input() -> EnemyInputComponent:
	var enemy := root as Enemy
	if enemy and enemy.input is EnemyInputComponent:
		return enemy.input as EnemyInputComponent
	return null
