##[b][color=red]DEPRECATED[/color][/b] — Use [b]InteractableComponent[/b] instead.[br]
##This class's body_entered handler causes a runtime type error:[br]
##[code]Body_Player.current_interactable[/code] is typed [code]InteractableComponent[/code],[br]
##but this class assigns [code]self[/code] (an Area2D) to it.[br]
##Will be removed once all scenes have been migrated.
class_name Interact
extends Area2D

#region SIGNALS
##Emitted when this interaction is completed.[br]
##States and other listeners use this to know when to resume ordinary behavior.
@warning_ignore("unused_signal")
signal interaction_finished

#endregion SIGNALS

#region VARIABLES

@export_category("Interaction Settings")
##Tell the context label I am this kind of entity
@export_enum("default", "container", "dodge", "door", "grab", "locked", "npc", "pickup", "secret", "shop", "throw", "usable") var context_key : String = "default"
@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
@export_category("Interaction Components")
@export var root : EntityClass
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

##This occurs if the interactable has no type; overwrite the Interact function in subclasses to use this.
func interact(_user = null):
	print("Base Interactable: Nothing happens.")

#region Triggers

##Trigger enter functionality; this sets this interactable to be the player's current interactable and sets the label.
func _on_body_entered(body : CharacterBody2D):
	if body is PlayerBody:
		if "current_interactable" in body:
			body.current_interactable = self
		if body.root and body.root.state_machine:
			body.root.state_machine.request_context_refresh()

##Trigger exit functionality; this resets the label and character body's current interactable
func _on_body_exited(body : CharacterBody2D):
	if body is PlayerBody:
		if "current_interactable" in body and body.current_interactable == self:
			body.current_interactable = null
		if body.root and body.root.state_machine:
			body.root.state_machine.request_context_refresh()

#endregion Triggers

#endregion FUNCTIONS
