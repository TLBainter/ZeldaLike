##[b][color=red]StateMove[/color][/b] is the initial movement state.[br]
##In this state, a character is moving at a moderate pace rather than running or idling.[br]
##Transitions to idle when joystick input is within the deadzone, or to running when joystick input is high.
##[br]
##[b]LAYER[/b]: Movement
class_name StateMove
extends State

#region VARIABLES

##The state to enter when no longer moving.
@export var idle_state : State

##The state to enter when moving at a faster pace due to joystick input increase.
@export var run_state : State

##The state to enter when rolling due to action button press.
@export var roll_state : State

#endregion VARIABLES

#region FUNCTIONS

func enter():
	super()
	#Set walk speed from stats.
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.walk_speed
	if root.input and not root.input.onMove.is_connected(_on_move):
		root.input.onMove.connect(_on_move)
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		if character.energy and character.energy.is_exhausted_state:
			character.anim.idle_prefix = "ExhaustedIdle"
			character.anim.walk_prefix = "ExhaustedWalk"
		else:
			character.anim.idle_prefix = "Idle"
			character.anim.walk_prefix = "Walk"
	
func exit():
	if root.input and root.input.onMove.is_connected(_on_move):
		root.input.onMove.disconnect(_on_move)
	super()

func pause():
	if root.input and root.input.onMove.is_connected(_on_move):
		root.input.onMove.disconnect(_on_move)
	root.body.velocity = Vector2.ZERO
	super()

func resume():
	if root.input and not root.input.onMove.is_connected(_on_move):
		root.input.onMove.connect(_on_move)

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < 0.15 and idle_state:
		state_machine.change_state(idle_state)
	elif move_strength > 0.49 and run_state:
		var character = get_character()
		if coordinator.context_locked:
			return
		if character and character.energy and character.energy.is_exhausted_state:
			return
		state_machine.change_state(run_state)

func get_context_key() -> String:
	if coordinator.held_object:
		return "drop"
	var character = get_character()
	if character and character.body.current_interactable:
		var interact_node = character.body.current_interactable
		var interactable_owner = interact_node.root if "root" in interact_node else null
		if interactable_owner and interactable_owner is DynamicInteractable and interactable_owner.object_data:
			var data = interactable_owner.object_data
			#While moving, grabbable objects show "grab" (even if also liftable)
			if data.pushable or data.pullable:
				return "grab"
			#Liftable-only while moving still shows "pickup"
			elif data.liftable:
				return "pickup"
		return interact_node.context_key
	return ""
#endregion FUNCTIONS
