##[b][color=red]State[/color][/b] is the overarching handler of all substates for a character.[br]
##It is the base class from which all substates in the state machine system are derived.[br]
##States are child nodes of a [b]StateMachineLayer[/b] and control behavior for one layer (Movement, Action, No Control).[br]
##Return a [b]State[/b] from a process function to trigger a transition; return [b][color=pink]null[/color][/b] to stay in the current state.
class_name State
extends Node

#region VARIABLES

@export_group("State Settings")
#TODO: Create enum for the animation player to make life easier!
##The animation to play on the parent's animation player when this state is entered.[br]
##Leave empty if the state should not change the current animation.
@export var animation_name : String = ""
##The reference to the parent Entity this state controls.[br]
##Set automatically by [b]StateMachineLayer.init()[/b]
var root : EntityClass
##The reference to the State Coordinator that manages all state layers.[br]
##Used for cross-layer communication, such as freezing other state layers and preventing input.
##Set automatically by [b]StateMachineLayer.init()[/b]
var coordinator
##A reference to the State Machine Layer this state belongs to.[br]
##Set automatically by [b]StateMachineLayer.init()[/b]
var state_machine
#=====================#
@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

#=====================#
##Whether or not process_input's variable provided was used by the given state.
var input_consumed : bool = false
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#Set the debug name if it is not set.
	if debug_name == "":
		debug_name = name

##Called after all state layers are initialized and coordinator is set.[br]
##Override to assign transition state references using coordinator.get_state().[br]
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
		print_rich(root.debug_name, " ", debug_name, " State [color=#57FF84]entered[/color].")

##Called when this state's layer is frozen while this state is active.[br]
##Override to disconnect signals that should not fire while frozen.[br]
##[br]
##[b]Contract:[/b] If this state connects any signals in [method enter], it MUST disconnect them
##here and reconnect them in [method resume]. Do not rely on [method exit] alone -- the state
##machine may freeze without exiting the active state.
func pause():
	if debug_me:
		print_rich(debug_name, " [color=#E5FF3D]paused[/color].")

##Called when this state's layer is unfrozen while this state is active.[br]
##Override to reconnect signals disconnected in [method pause].[br]
##[br]
##[b]Contract:[/b] Mirror every connection made in [method enter] and disconnected in [method pause].
func resume():
	if debug_me:
		print_rich(debug_name, " [color=#29FFBF]resumed[/color].")

##Called when this state is replaced by another.[br]
##Override to add logic for cleaning up this state.
func exit():
	if debug_me_verbose:
		print_rich(root.debug_name, " ", debug_name, " State [color=#FF2B48]exited[/color].")

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
##Shared helper used by Idling, Move, and any state needing interactable context resolution.
func _get_interactable_context_key(character) -> String:
	if not character or not character.body.current_interactable:
		return ""
	var interact_node = character.body.current_interactable
	var interactable_owner = interact_node.root if "root" in interact_node else null
	if interactable_owner and "object_data" in interactable_owner and interactable_owner.object_data:
		var data = interactable_owner.object_data
		if data.pushable or data.pullable:
			return "grab"
		elif data.liftable:
			return "lift"
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

#endregion FUNCTIONS
