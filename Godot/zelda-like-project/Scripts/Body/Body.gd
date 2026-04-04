##[b][color=red]Body[/color][/b] is used for Character Body 2D nodes and handles things like detection of area 2Ds and other colliders.
class_name Body
extends CharacterBody2D

#region VARIABLES

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

#endregion VARIABLEs
