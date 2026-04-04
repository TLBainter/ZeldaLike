##[b][color=red]StateCoordinator[/color][/b] manages the three parallel state machine layers: Movement, Action, and No Control.[br]
##It routes input events (_unhandled_input) to all layers[br]
##and provides methods for cross-layer communication (freezing, unfreezing, requesting state changes).[br]
class_name StateCoordinator
extends Node

#region SIGNALS
##Emitted when the context label should be updated.[br]
##ContextLabel listens for this to change its display text.
signal context_changed(context_key : String)
#endregion SIGNALS

#region VARIABLES

@export_category("Coordinator Components")
##The root Character entity this coordinator controls.
@export var root : EntityClass
##The State Machine Layer handling movement states (running, rolling, etc.).
@export var movement_layer : Node
##The State Machine Layer handling Action states (attacking, lifting, etc.).
@export var action_layer : Node
##The State Machine Layer handling No Control states (death, paused, etc.)
@export var no_control_layer : Node
#==========#
@export_category("Debug")
##Whether or not you want htis coordinator to print output into the debugger.
@export var debug_me : bool = false
##Whether you want more robust debugging outputs. This can fill up the output quickly, but is more informative.
@export var debug_me_verbose : bool = false
##The name used to identify this coordinator in the debug output.
@export var debug_name : String = "StateCoordinator"
#============#
#Internal Variables
##The DynamicThing currently being grabbed by the relevant entity.
##Set by StateGrab, read by GrabIdle/Pushing/Pulling States. Null when not grabbing.
var grabbed_object : DynamicThing = null
##The DynamicThing currently being held by the relevant entity.
##Set by StateLift, read by HoldingAction/Throw/Drop States. Null when not holding.
var held_object : DynamicThing = null
##Whether or not context can currently be updated by a given state.
var context_locked : bool = false
##Registry of all State nodes under this coordinator, keyed by script.[br]
##Populated automatically on _ready() by [b]_discover_states()[/b].[br]
##States use [b]get_state()[/b] to look up transitions without manual export wiring.
var _states : Dictionary = {}
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#region component debugger prints
	if not root:
		printerr(debug_name, ": root Character is not assigned!")
		return
	if not movement_layer:
		printerr(debug_name, ": movement layer not assigned!")
		return
	if not action_layer:
		printerr(debug_name, ": action layer is not assigned!")
		return
	if not no_control_layer:
		printerr(debug_name, ": no control layer is not assigned!")
		return
	#endregion component debugger prints
	#INITIALIZE
	_discover_states()
	movement_layer.init_refs(root, self)
	action_layer.init_refs(root, self)
	no_control_layer.init_refs(root, self)
	if debug_me:
		print(debug_name, " initialized with root: ", root.debug_name)

	#region input calls
##Routes unhandled input through to all layers.[br]
##No Control always processes first![br]
##Once one state layer processes an input, that input is NOT passed to the other layers.
func _unhandled_input(event : InputEvent):
	if no_control_layer.process_input(event):
		return
	if movement_layer.process_input(event):
		return
	action_layer.process_input(event)
	#endregion input calls

	#region cross layer controls
##Freezes the Movement layer, preventing it from processing.
func freeze_movement():
	movement_layer.freeze()

##Unfreezes the Movement layer, allowing it to process, again.
func unfreeze_movement():
	movement_layer.unfreeze()

##Freezes the No Control layer, preventing it from processing.
func freeze_no_control():
	no_control_layer.freeze()

##Unfreezes the No Control layer, allowing it to process, again.
func unfreeze_no_control():
	no_control_layer.unfreeze()

##Freezes the Action layer, preventing it from processing.
func freeze_action():
	action_layer.freeze()

##Unfreezes the Action layer, allowing it to process, again.
func unfreeze_action():
	action_layer.unfreeze()

##Freezes both Movement and Action layers.[br]
##Typically called by No Control states to override character input.
func freeze_all():
	freeze_movement()
	freeze_action()

##Unfreezes both Movement and Action layers.[br]
##Typically called by No Control states to permit use of character input, again.
func unfreeze_all():
	unfreeze_action()
	unfreeze_movement()

##Requests a state change on the Movement layer.
func request_movement_change(new_state : State):
	movement_layer.change_state(new_state)
	if debug_me and debug_me_verbose:
		print(root.debug_name, " ", debug_name, " requested Movement -> ", new_state.debug_name.trim_prefix("State"))

##Requests a state change on the No Control layer.
func request_no_control_change(new_state : State):
	no_control_layer.change_state(new_state)
	if debug_me and debug_me_verbose:
		print(root.debug_name, " ", debug_name, " requested No Control -> ", new_state.debug_name.trim_prefix("State"))
		
##Requests a state change on the Action layer.
func request_action_change(new_state : State):
	action_layer.change_state(new_state)
	if debug_me and debug_me_verbose:
		print(root.debug_name, " ", debug_name, " requested Action -> ", new_state.debug_name.trim_prefix("State"))

##Prevents movement states from updating the context label.
func lock_context():
	context_locked = true

##Allows movement states to update the context label again.
func unlock_context():
	context_locked = false

##Emits the context_changed signal with the given key.
func update_context(context_key : String, force : bool = false):
	if context_locked and not force:
		return
	context_changed.emit(context_key)

##Asks the current state to reevaluate and emit its context.[br]
##Call this when external conditions change, such as entering or exiting an interact area.
func request_context_refresh():
	if context_locked:
		return
	if movement_layer and not movement_layer.is_active:
		return
	if movement_layer and movement_layer.current_state:
		var key = movement_layer.current_state.get_context_key()
		context_changed.emit(key)

##Sends an attack hit message to target(s) of attacks
func attack_hit() -> void:
	if action_layer and action_layer.current_state is StateAttack:
		action_layer.current_state.execute_hit()

	#region state registry
##Walks all three layers and registers every State child by its script.[br]
##Called once on _ready(). States call [b]get_state()[/b] to look up transitions by class.
func _discover_states() -> void:
	_states.clear()
	for layer in [movement_layer, action_layer, no_control_layer]:
		if not layer:
			continue
		for child in layer.get_children():
			if child is State:
				_states[child.get_script()] = child
	if debug_me:
		print(debug_name, " discovered ", _states.size(), " states.")

##Returns the State node for the given class, or null if not present on this entity.[br]
##Usage: [b]coordinator.get_state(StateIdling)[/b]
func get_state(state_class) -> State:
	return _states.get(state_class)
	#endregion state registry

	#region shared entity helpers
##Returns true if the root character is in an exhausted state.[br]
##Returns false if the entity has no energy component.
func is_exhausted() -> bool:
	var character = root as Character
	return character != null and character.energy != null and character.energy.is_exhausted_state

##Attempts to consume energy from the root character.[br]
##Returns true on success. Returns true (no restriction) if the entity has no energy component.
func consume_energy(cost : int) -> bool:
	var character = root as Character
	if character and character.energy:
		return character.energy.consume(cost)
	return true

##Returns true if the entity's body velocity exceeds the given threshold (pixels/sec).[br]
##Use instead of raw Input polling so the check works for both player and AI entities.
func is_moving(threshold : float = 10.0) -> bool:
	return root.body != null and root.body.velocity.length() > threshold
	#endregion shared entity helpers

#endregion FUNCTIONS
