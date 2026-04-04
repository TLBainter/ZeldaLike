##[b][color=red]DebugSettings[/color][/b] is a shared resource that holds the three standard debug toggles.[br]
##Assign one instance per node in the inspector, or share a pre-configured resource across multiple nodes.
class_name DebugSettings
extends Resource

##Whether or not you want this object to print debug output.
@export var debug_me : bool = false
##Whether you want verbose debug output (requires [b]debug_me[/b] to be useful).
@export var debug_me_verbose : bool = false
##The name used to identify this object in debug output.
@export var debug_name : String = ""
