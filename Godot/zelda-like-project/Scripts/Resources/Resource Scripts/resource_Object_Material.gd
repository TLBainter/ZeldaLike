##[b][color=red]ObjectMaterial[/color][/b] is a reusable resource that defines the sounds associated with a material type.[br]
##Assign this to an [b]InteractableObject[/b] so all objects of the same material share the same libraries without duplicating data unnecessarily.
class_name ObjectMaterial
extends Resource

#region VARIABLES

@export_category("Material Settings")
##This is a display name for the material.[br]
##Primarily used for debugging.
@export var material_name : String = "Material"

@export_category("Sound Libraries")
##A sound to play when an object with this material breaks.
@export var break_sounds : SoundLibrary
##A sound to play when an object with this material is opened (such as a door or chest).
@export var open_sounds : SoundLibrary
##A sound to play when an object with this material is closed (such as a door or chest).
@export var close_sounds : SoundLibrary
##A sound to play when something impacts but does not break an object with this material.[br]
##E.g., the player rolls into a tree with the wood material and it makes a thud sound.
@export var impact_sounds : SoundLibrary
##A sound to play when this object's material is lifted (such as a heavy jar scraping on the floor as it is picked up).
@export var lift_sounds : SoundLibrary
##A sound to play when this object's material is pushed or pulled across a surface.
@export var move_sounds : SoundLibrary
##A sound to play when this object's material is dropped without breaking.
@export var drop_sounds : SoundLibrary
##A sound to play when this object's material is thrown, but before it impacts.
@export var throw_sounds : SoundLibrary
##A sound to play when someone is walking on this object's material.
@export var footstep_sounds : SoundLibrary

#endregion VARIABLES

#region FUNCTIONS

#endregion FUNCTIONS
