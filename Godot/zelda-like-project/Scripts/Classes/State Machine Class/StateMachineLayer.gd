##[b][color=red]StateMachineLayer[/color][/b] manages a single layer of multiple states.[br]
##A State Machine Layer can be Movement, Action, or No Control.[br]
##Within this layer are multiple [b]State[/b] nodes to which it may delegate inputs to the active state.[br]
##This state machine layer can bused for cross functional control and is frozen/unfrozen by the [b]StateCoordinator[/b] for its entity.
class_name StateMachineLayer
extends Node

#region VARIABLES

@export_group("State Layer Settings")
##The state this layerw ill enter on initialization.
@export var starting_state : Node
##The currently-active state for this layer. Only one may be active at a time.[br]
##If you ever need an additional state active for a single layer, you may need to determine whether a separate layer is needed.
var current_state : Node
##Whether this layer is currently processing states.[br]
##This is controlled by the [b]StateCoordinator[/b].
var is_active : bool = true
##The root of this entity; usually a Character.
var root : EntityClass
##The coordinator for this entity.
var coordinator : StateCoordinator

#=================#

@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

#==================#

#endregion VARIABLES

#region FUNCTIONS

##Intializes all child states with references to the root and coordinator.[br]
##Afterward, enter the starting state (assigned by the export variable starting_state.[br]
##[b]ROOT[/b]: The Character entity node this state machine controls.[br]
##[b]COORDINATOR[/b]: The State Coordinator managing this layer and its siblings.
func init_refs(p_root : EntityClass, p_coordinator : StateCoordinator):
	self.root = p_root
	self.coordinator = p_coordinator
	for child in get_children():
		if child is State:
			child.root = p_root
			child.coordinator = p_coordinator
			child.state_machine = self
	if self.root and self.coordinator:
		init()
	elif debug_me:
		printerr(debug_name, ": No assigned root and/or coordinator!")

func init():
	if starting_state:
		change_state(starting_state)
	elif debug_me:
		printerr(root.debug_name, " ", debug_name, ": No assigned starting state!")

##Transitions from the current state of this layer to a new state.[br]
##Calls [b]exit()[/b] on the outgoing state and [b]enter()[/b] on the incoming state.[br]
##States disconnect their signals in exit() and connect new ones in enter().
func change_state(new_state : State):
	if new_state == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
	if debug_me:
		print(root.debug_name, " ", debug_name, " -> ", new_state.debug_name.trim_prefix("State"))

##Delegates input events to the active state.
func process_input(event : InputEvent) -> bool:
	if not is_active or not current_state:
		return false
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)
		return true
	return current_state.input_consumed

##Freezes this layer. The active state's signal connections will remain intact,[br]
##but process_input calls will be skipped.[br]
##States that need to fully disconnect on freeze should listen for the coordinator's freeze/unfreeze calls, instead.
func freeze():
	is_active = false
	if current_state:
		current_state.pause()
	if debug_me:
		print_rich(root.debug_name, " ", debug_name, " is [color=#12D7FF]frozen.[/color]")

##Removes a freeze from this layer, allowing process_input calls to reach states, again.
func unfreeze():
	is_active = true
	if current_state:
		current_state.resume()
	if debug_me:
		print_rich(root.debug_name, " ", debug_name, " is [color=#FFA319]unfrozen.[/color]")
	
#endregion FUNCTIONS
