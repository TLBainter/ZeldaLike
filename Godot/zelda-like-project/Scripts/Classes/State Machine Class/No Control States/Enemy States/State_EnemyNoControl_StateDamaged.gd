##[b][color=red]StateDamaged[/color][/b] — brief stagger after the enemy takes a non-lethal hit.[br]
##After the stagger, the enemy either counter-attacks ([constant ATTACK_CHANCE]) or retreats
##at boosted speed ([constant HURT_RETREAT_SPEED_MULT] × normal) for [constant HURT_RETREAT_DURATION] seconds.
class_name StateDamaged
extends State

##Seconds the enemy is frozen in a stagger before acting.
const STAGGER_DURATION : float = 0.25
##Probability (0–1) the enemy immediately counter-attacks instead of retreating.
const ATTACK_CHANCE : float = 0.45
##How much faster the enemy moves during the post-damage retreat burst.
const HURT_RETREAT_SPEED_MULT : float = 1.6
##How long (seconds) the speed boost lasts.
const HURT_RETREAT_DURATION : float = 1.5

var _timer : float = 0.0

func enter() -> void:
	super()
	coordinator.freeze_all()
	_timer = STAGGER_DURATION
	set_process(true)

func _process(delta : float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	_timer -= delta
	if _timer > 0.0:
		return
	set_process(false)
	_decide()

func _decide() -> void:
	var input := _get_input()
	if not input or not input.get_player():
		_safe_transition(StateID.CHASE)
		return
	if randf() < ATTACK_CHANCE:
		_debug_log("Damaged decision: counter-attack.")
		_safe_transition(StateID.COMBAT)
	else:
		_debug_log("Damaged decision: hurt retreat.")
		input.begin_hurt_retreat(HURT_RETREAT_DURATION, HURT_RETREAT_SPEED_MULT)
		_safe_transition(StateID.CHASE)

func exit() -> void:
	set_process(false)
	coordinator.unfreeze_all()
	super()

func _get_input() -> EnemyInputComponent:
	var enemy := root as Enemy
	if enemy and enemy.input is EnemyInputComponent:
		return enemy.input as EnemyInputComponent
	return null
