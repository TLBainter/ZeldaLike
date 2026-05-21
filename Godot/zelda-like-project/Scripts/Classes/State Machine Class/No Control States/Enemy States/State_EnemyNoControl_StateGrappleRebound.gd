##[b][color=red]StateGrappleRebound[/b][/color] - knockback state entered after a grapple pull collision.[br]
##Identical to [b]StateKnockback[/b] except [method _finish] transitions to STUNNED instead of INITIALIZED.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StateGrappleRebound
extends StateKnockback

func _finish() -> void:
	_safe_transition(StateID.STUNNED)
