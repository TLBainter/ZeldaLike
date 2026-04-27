##[b][color=red]StateCoordinator[/color][/b] manages the three parallel state machine layers: Movement, Action, and No Control.[br]
##It routes input events (_unhandled_input) to all layers[br]
##and provides methods for cross-layer communication (freezing, unfreezing, requesting state changes).[br]
class_name StateCoordinator
extends Node

#region SIGNALS
##Emitted when the context label should be updated.[br]
##ContextLabel listens for this to change its display text.
signal context_changed(context_key : String)
signal grabbed_object_changed(obj: DynamicThing)
signal held_object_changed(obj: DynamicThing)
#endregion SIGNALS

#region ENUMS
##Result of [method resolve_interaction_priority].[br]
##Use instead of comparing raw strings to determine grab/lift/interact behaviour.
enum InteractionPriority { GRAB, LIFT, INTERACT }
#endregion ENUMS

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
##Maps logical transition keys to state script resources.[br]
##Assign a custom [StateTransitionTable] resource in the editor to swap state classes at design time.[br]
##States call [method get_transition] instead of caching typed vars in [method State.init_state_refs].
@export var transition_table: StateTransitionTable = StateTransitionTable.new()
@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
##When true, every state transition is logged to Output with the triggering reason.[br]
##Format: [SM] FromState → ToState | reason
@export var debug_transitions : bool = false

##Shared cooldown duration (seconds) after any dodge (dash or backstep).
const DODGE_COOLDOWN : float = 0.25
##Remaining cooldown time before the next dodge is allowed. Ticked down in _process.
var _dodge_cooldown_timer : float = 0.0
##The DynamicThing currently being grabbed by the relevant entity.
##Set via grab_object()/release_grabbed(), read by GrabIdle/Pushing/Pulling States.
var grabbed_object : DynamicThing = null
##The DynamicThing currently being held by the relevant entity.
##Set via lift_object()/release_held(), read by HoldingAction/Throw/Drop States.
var held_object : DynamicThing = null

func grab_object(obj: DynamicThing) -> void:
	grabbed_object = obj
	grabbed_object_changed.emit(obj)

func release_grabbed() -> DynamicThing:
	var obj := grabbed_object
	grabbed_object = null
	grabbed_object_changed.emit(null)
	return obj

func lift_object(obj: DynamicThing) -> void:
	held_object = obj
	held_object_changed.emit(obj)

func release_held() -> DynamicThing:
	var obj := held_object
	held_object = null
	held_object_changed.emit(null)
	return obj
##Whether or not context can currently be updated by a given state.
var context_locked : bool = false
##Registry of all State nodes under this coordinator, keyed by script.[br]
##Populated automatically on _ready() by [b]_discover_states()[/b].[br]
##States use [b]get_state()[/b] to look up transitions without manual export wiring.
var _states : Dictionary = {}
#endregion VARIABLES

#region FUNCTIONS

func _process(delta: float) -> void:
	_dodge_cooldown_timer -= delta
	if _dodge_cooldown_timer <= 0.0:
		_dodge_cooldown_timer = 0.0
		set_process(false)

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
	_discover_states()
	movement_layer.init_refs(root, self)
	action_layer.init_refs(root, self)
	no_control_layer.init_refs(root, self)
	for state in _states.values():
		state.init_state_refs()
	set_process(false)
	if debug_me:
		print_rich(debug_name, " [color=green][i]initialized[/i][/color] with root: [b]", root.debug_name, "[/b]")

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
##Freezes [param layer], preventing it from processing. Null-safe.
func freeze_layer(layer: StateMachineLayer) -> void:
	if layer: layer.freeze()

##Unfreezes [param layer], allowing it to process again. Null-safe.
func unfreeze_layer(layer: StateMachineLayer) -> void:
	if layer: layer.unfreeze()

##Freezes the Movement layer, preventing it from processing.
func freeze_movement() -> void:   freeze_layer(movement_layer)
##Unfreezes the Movement layer, allowing it to process, again.
func unfreeze_movement() -> void:  unfreeze_layer(movement_layer)
##Freezes the No Control layer, preventing it from processing.
func freeze_no_control() -> void:  freeze_layer(no_control_layer)
##Unfreezes the No Control layer, allowing it to process, again.
func unfreeze_no_control() -> void: unfreeze_layer(no_control_layer)
##Freezes the Action layer, preventing it from processing.
func freeze_action() -> void:      freeze_layer(action_layer)
##Unfreezes the Action layer, allowing it to process, again.
func unfreeze_action() -> void:    unfreeze_layer(action_layer)

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
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " [color=green][i]requested Movement →[/i][/color] [i]", new_state.debug_name.trim_prefix("State"), "[/i]")

##Requests a state change on the No Control layer.
func request_no_control_change(new_state : State):
	no_control_layer.change_state(new_state)
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " [color=green][i]requested No Control →[/i][/color] [i]", new_state.debug_name.trim_prefix("State"), "[/i]")
		
##Requests a state change on the Action layer.
func request_action_change(new_state : State):
	action_layer.change_state(new_state)
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " [color=green][i]requested Action →[/i][/color] [i]", new_state.debug_name.trim_prefix("State"), "[/i]")

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
		print_rich(debug_name, ": [color=green][i]discovered[/i][/color] [i]", _states.size(), "[/i] states.")

##Returns the State node for the given class, or null if not present on this entity.[br]
##Usage: [b]coordinator.get_state(StateIdling)[/b]
func get_state(state_class) -> State:
	return _states.get(state_class)

##Returns the State node for the given transition key via the [member transition_table].[br]
##Returns null if the key is missing or the state class is not present on this entity.[br]
##Usage: [b]coordinator.get_transition("idle")[/b]
func get_transition(key: String) -> State:
	if not transition_table or not transition_table.transitions.has(key):
		return null
	return _states.get(transition_table.transitions[key])
	#endregion state registry

##Returns [param to_state] unchanged, logging the transition when [b]debug_transitions[/b] is true.[br]
##States should return the result of this call instead of returning a state directly:[br]
##[code]return coordinator.try_transition(state_machine, idle_state, "attackLight+pressed")[/code]
func try_transition(layer: Node, to_state: State, reason: String = "") -> State:
	if not to_state:
		return null
	if debug_transitions:
		var from_name: String = layer.current_state.debug_name if layer.current_state else "none"
		print_rich("[b][SM][/b] ", from_name, " → [i]", to_state.debug_name, "[/i] | ", reason)
	return to_state

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

##Returns true if the dodge cooldown is still active (dash or backstep used recently).
func is_on_dodge_cooldown() -> bool:
	return _dodge_cooldown_timer > 0.0

##Starts the shared dodge cooldown. Called by StateDash and StateBackstep on successful exit.
func start_dodge_cooldown() -> void:
	set_process(true)
	_dodge_cooldown_timer = DODGE_COOLDOWN

##Returns true if the entity's body velocity exceeds the given threshold (pixels/sec).[br]
##Use instead of raw Input polling so the check works for both player and AI entities.
func is_moving(threshold : float = 10.0) -> bool:
	return root.body != null and root.body.velocity.length() > threshold

##Resolves whether to grab, lift, or interact with a DynamicThing based on its ObjectData.[br]
##Priority rule: if the object is pushable/pullable and the character is moving (or it is not liftable), grab wins.[br]
##If the character is idle and the object is also liftable, lift wins.
func resolve_interaction_priority(data, is_moving_flag : bool) -> InteractionPriority:
	if data.pushable or data.pullable:
		if is_moving_flag or not data.liftable:
			return InteractionPriority.GRAB
		return InteractionPriority.LIFT
	elif data.liftable:
		return InteractionPriority.LIFT
	return InteractionPriority.INTERACT
	#endregion shared entity helpers

#endregion FUNCTIONS
