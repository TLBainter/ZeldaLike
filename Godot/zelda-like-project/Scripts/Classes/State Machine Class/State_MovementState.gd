##Base class for movement states responding to on_move signals.
##Owns connect/disconnect lifecycle for InputComponent.on_move.
##Override _on_move() to react to input; override enter()/exit() with super() for extra logic.
class_name MovementState
extends State

#region FUNCTIONS

func enter():
	super()
	_connect_move()

func exit():
	_disconnect_move()
	super()

##Disconnects on_move and zeroes velocity on pause.
##Override if state should not zero velocity on pause.
func pause():
	_disconnect_move()
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	_connect_move()
	super()

func _connect_move():
	if root.input: _safe_connect(root.input.on_move, _on_move)

func _disconnect_move():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)

##Override in subclasses to handle movement transitions.
func _on_move(_move_input : Vector2, _move_strength : float):
	pass

#endregion FUNCTIONS
