##[b][color=red]StateGrappled[/color][/b] - NoControl state entered when an enemy is caught by the player's grapple.[br]
##Freezes all layers and locks facing until [method end_grapple] is called by SpellcastGrappleState.
class_name StateGrappled
extends State

func enter() -> void:
	super()
	coordinator.freeze_all()
	lock_facing()

func exit() -> void:
	coordinator.unfreeze_all()
	unlock_facing()
	super()

##Called by SpellcastGrappleState when the grapple retraction finishes. Transitions to Chase.
func end_grapple() -> void:
	if state_machine and state_machine.current_state == self:
		_safe_transition(StateID.CHASE)
