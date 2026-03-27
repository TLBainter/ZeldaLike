##[b][color=red]Interact[/color][/b] is the handler for all interactions; lifting pots, talking to NPCs, etc.[br]
##Extends an Area2D associated with an entity.
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
@export var debug_me : bool = false
@export var debug_name : String = "Interactable"
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
