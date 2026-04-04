##[b][color=red]StateGrabIdle[/color][/b] is the [b]Movement layer[/b] state for the character's grabbing of an object while not moving.[br]
##Listens for directional input along the locked axis to transition to [i]Pushing[/i] or [i]Pulling[/i].[br]
##The character cannot turn (change facing) or move freely in this state.[br]
##[br]
##[b]Layer[/b]: Movement
class_name StateGrabIdle
extends State

#region VARIABLES

@export_group("Internal Transitions")
##The state to enter when pushing the object (input matches facing direction).
@export var pushing_state : State
##The state to enter when pulling the object (input opposes facing direction).
@export var pulling_state : State
@export_group("Cross-Layer Transitions")
##The no action state on the action layer
@export var no_action_state : State
#====#
var _snap_cooldown : bool = false

#endregion VARIABLES

#region FUNCTION

func enter():
	#Call super
	super()
	root.body.velocity = Vector2.ZERO
	#Connect signal for directional input
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	#Grab
	coordinator.update_context("grab")
	#Release Grab if button is no longer pressed.
	if not Input.is_action_pressed("actionButton4") and no_action_state:
		coordinator.request_action_change(no_action_state)
		return
	_snap_cooldown = true
	var grabbed = coordinator.grabbed_object
	var delay : float = 0.15
	#TODO: Make this delay pull the _snap_delay_value from the push/pull state, so it is consistent with their delays.
	#Push/Pull have different modifiers.
	var obj_weight : int = 30
	if grabbed and grabbed.stats and grabbed.stats.resource:
		obj_weight = grabbed.stats.resource.weight
	delay = 0.05 + (float(obj_weight) * 0.01)
	get_tree().create_timer(delay).timeout.connect(_on_cooldown_finished)

func exit():
	#Disconnect Signals
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	#Call super
	super()

func pause():
	#disconnect input move to _on_move
	if root.input and root.input.on_move.is_connected(_on_move):
		root.input.on_move.disconnect(_on_move)
	#call super
	super()

func resume():
	#connect input move to _on_move
	if root.input and not root.input.on_move.is_connected(_on_move):
		root.input.on_move.connect(_on_move)
	#call super
	super()

func _on_move(move_input : Vector2, move_strength : float):
	#return if not moving enough
	if move_strength < 0.15:
		return
	#return if snap cooldown is still coolding down
	if _snap_cooldown:
		return
	#set character and animation
	var character = get_character()
	if not character or not character.anim:
		return
	#set facing direction
	var facing_dir : Vector2 = _get_facing_vector(character.anim.facing)
	if facing_dir == Vector2.ZERO:
		return
	#project input and facing axis to determine push/pull
	var dot : float = move_input.normalized().dot(facing_dir)
	var grabbed = coordinator.grabbed_object
	if not grabbed or not grabbed.object_data:
		return
	#PUSHING (input is equal to facing)
	if dot > 0.5 and grabbed.object_data.pushable and pushing_state:
		state_machine.change_state(coordinator.try_transition(state_machine, pushing_state, "on_move+dot>0.5+pushable"))
	#PULLING (input is opposite facing)
	if dot < -0.5 and grabbed.object_data.pullable and pulling_state:
		state_machine.change_state(coordinator.try_transition(state_machine, pulling_state, "on_move+dot<-0.5+pullable"))
	pass

func _get_facing_vector(facing : String) -> Vector2:
	#match facing
	match facing:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.ZERO

func _on_cooldown_finished():
	_snap_cooldown = false

func get_context_key() -> String:
	return "grab"

#endregion FUNCTIONS
