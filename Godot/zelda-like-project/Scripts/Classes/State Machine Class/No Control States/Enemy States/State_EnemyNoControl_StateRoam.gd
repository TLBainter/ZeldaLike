##[b][color=red]StateRoam[/color][/b] - the enemy wanders in random cardinal directions.[br]
##Transitions to Chase when the player is detected via [b]EnemyInputComponent[/b].
class_name StateRoam
extends State

# TODO: NavigationAgent2D-based roaming in the future

func enter() -> void:
	super()
	var input := _get_input()
	if not input:
		return
	input.set_mode(EnemyInputComponent.AIMode.ROAM)
	_safe_connect(input.player_detected, _on_player_detected)
	if input.get_player() != null:
		_safe_transition.call_deferred(StateID.CHASE)

func exit() -> void:
	var input := _get_input()
	if input:
		_safe_disconnect(input.player_detected, _on_player_detected)
		input.set_mode(input.default_mode)
	super()

func pause() -> void:
	var input := _get_input()
	if input:
		_safe_disconnect(input.player_detected, _on_player_detected)
	super()

func resume() -> void:
	var input := _get_input()
	if input:
		_safe_connect(input.player_detected, _on_player_detected)
		if input.get_player() != null:
			_safe_transition.call_deferred(StateID.CHASE)
	super()

func _on_player_detected(_player_body : Node2D) -> void:
	_safe_transition(StateID.CHASE)

func _get_input() -> EnemyInputComponent:
	var enemy := root as Enemy
	if enemy and enemy.input is EnemyInputComponent:
		return enemy.input as EnemyInputComponent
	return null
