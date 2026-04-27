@icon("res://Editor Tools/Icons/icon_state.svg")
##[b][color=red]State[/color][/b] is the overarching handler of all substates for a character.[br]
##It is the base class from which all substates in the state machine system are derived.[br]
##States are child nodes of a [b]StateMachineLayer[/b] and control behavior for one layer (Movement, Action, No Control).[br]
##Return a [b]State[/b] from a process function to trigger a transition; return [b][color=pink]null[/color][/b] to stay in the current state.
class_name State
extends Node

#region VARIABLES

@export_group("State Settings")
##The animation to play on the parent's animation player when this state is entered.[br]
##Leave empty if the state should not change the current animation.
@export var animation_name : String = ""
##The reference to the parent Entity this state controls.[br]
##Set automatically by [b]StateMachineLayer.init()[/b]
var root : EntityClass
##The reference to the State Coordinator that manages all state layers.[br]
##Used for cross-layer communication, such as freezing other state layers and preventing input.
##Set automatically by [b]StateMachineLayer.init()[/b]
var coordinator : StateCoordinator
##A reference to the State Machine Layer this state belongs to.[br]
##Set automatically by [b]StateMachineLayer.init()[/b]
var state_machine : StateMachineLayer

@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v


##Whether or not process_input's variable provided was used by the given state.
var input_consumed : bool = false
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	if debug_name == "":
		debug_name = name

##Called after all state layers are initialized and coordinator is set.[br]
##[b]Deprecated:[/b] State transition lookups have moved to [method StateCoordinator.get_transition].[br]
##Use [code]coordinator.get_transition("key")[/code] at the call site instead of storing typed state vars.[br]
##Do NOT call super() -- base implementation is intentionally empty.
func init_state_refs() -> void:
	pass

##Function that is called when this state is first entered.[br]
##Override to add enter logic to a state beyond animation switching.[br]
##Call [b]super()[/b] to keep the default animation changing behavior.
func enter():
	if animation_name != "" and root.anim:
		root.anim.play(animation_name)
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " State [color=green][i]entered[/i][/color].")

##Called when this state's layer is frozen while this state is active.[br]
##Override to disconnect signals that should not fire while frozen.[br]
##[br]
##[b]Contract:[/b] If this state connects any signals in [method enter], it MUST disconnect them
##here and reconnect them in [method resume]. Do not rely on [method exit] alone -- the state
##machine may freeze without exiting the active state.
func pause():
	if debug_me:
		print_rich(debug_name, " [color=yellow][i]paused[/i][/color].")

##Called when this state's layer is unfrozen while this state is active.[br]
##Override to reconnect signals disconnected in [method pause].[br]
##[br]
##[b]Contract:[/b] Mirror every connection made in [method enter] and disconnected in [method pause].
func resume():
	if debug_me:
		print_rich(debug_name, " [color=green][i]resumed[/i][/color].")

##Called when this state is replaced by another.[br]
##Override to add logic for cleaning up this state.
func exit():
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " State [color=red][i]exited[/i][/color].")

##Called on unhandled input events. Return a [b]State[/b] to transition to or [b]null[/b] to remain.[br]
##Use this for movement, collision checks, etc.[br]
##Asks for an event (InputEvent) to determine which state should be entered.
func process_input(_event : InputEvent) -> State:
	return null

##Called to pull character information.
func get_character():
	if root.type == "Character":
		return root
	return null

##Returns the context key for the interactable currently in the character's interact area.[br]
##Delegates to [b]StateCoordinator.resolve_interaction_priority()[/b] for consistent resolution.[br]
##[b]is_moving[/b]: pass true when the character is in motion (affects grab vs lift priority).
func _get_interactable_context_key(character, is_moving: bool = false) -> String:
	if not character or not character.body.current_interactable:
		return ""
	var interact_node = character.body.current_interactable
	var interactable_owner = interact_node.owner_entity if "owner_entity" in interact_node else null
	if interactable_owner and "object_data" in interactable_owner and interactable_owner.object_data:
		var priority = coordinator.resolve_interaction_priority(interactable_owner.object_data, is_moving)
		match priority:
			StateCoordinator.InteractionPriority.GRAB: return "grab"
			StateCoordinator.InteractionPriority.LIFT: return "lift"
			_: return "interact"
	return interact_node.context_key

##Returns the context key this state wants shown on the context label.[br]
##Override in various states to provide state-specific contexts.[br]
##Returns empty string by default (blank label, no text shown).
func get_context_key() -> String:
	return ""

##Converts a facing string ("up","down","left","right") to a Vector2 direction.
func facing_to_vector(face_str: String) -> Vector2:
	match face_str:
		"up":    return Vector2.UP
		"down":  return Vector2.DOWN
		"left":  return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN

##Locks the character's facing direction by disabling can_update_facing.
func lock_facing() -> void:
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = false

##Restores the character's facing direction updates.
func unlock_facing() -> void:
	var character = get_character()
	if character and character.anim and character.anim is CharacterAnimator:
		character.anim.can_update_facing = true

##Prints [b]msg[/b] prefixed with [b]debug_name[/b] when [b]debug_me[/b] is enabled.
func _debug_log(msg: String) -> void:
	if debug_me:
		print_rich(debug_name, ": ", msg)

##Prints [b]msg[/b] prefixed with [b]debug_name[/b] when [b]debug_me_verbose[/b] is enabled.
func _debug_verbose(msg: String) -> void:
	if debug_me_verbose:
		print_rich(debug_name, ": ", msg)

##Connects [b]cb[/b] to [b]sig[/b] if not already connected.
func _safe_connect(sig: Signal, cb: Callable) -> void:
	if not sig.is_connected(cb):
		sig.connect(cb)

##Disconnects [b]cb[/b] from [b]sig[/b] if currently connected.
func _safe_disconnect(sig: Signal, cb: Callable) -> void:
	if sig.is_connected(cb):
		sig.disconnect(cb)

##Transitions to the state registered under [param key] in the coordinator.[br]
##Logs a debug message if the key resolves to nothing.
func _safe_transition(key: String) -> void:
	var next := coordinator.get_transition(key)
	if not next:
		_debug_log("No transition found for key: " + key)
		return
	state_machine.change_state(coordinator.try_transition(state_machine, next, key))

#endregion FUNCTIONS
