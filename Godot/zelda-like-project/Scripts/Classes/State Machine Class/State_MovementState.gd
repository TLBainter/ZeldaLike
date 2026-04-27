##[b][color=red]MovementState[/color][/b] is the base class for all movement layer states that respond to [b]on_move[/b] signals.[br]
##It owns the connect/disconnect lifecycle for [b]InputComponent.on_move[/b], eliminating boilerplate from every movement state.[br]
##Override [b]_on_move()[/b] to react to input. Override [b]enter()[/b]/[b]exit()[/b] with [b]super()[/b] to add extra logic.
class_name MovementState
extends State

#region FUNCTIONS

func enter():
	super()
	_connect_move()

func exit():
	_disconnect_move()
	super()

##Disconnects on_move and zeroes velocity on pause.[br]
##Override if your state should NOT zero velocity on pause (e.g. states that already zero in enter).
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

##Called when the input component emits on_move.[br]
##Override in subclasses to handle movement transitions.
func _on_move(_move_input : Vector2, _move_strength : float):
	pass

#endregion FUNCTIONS
