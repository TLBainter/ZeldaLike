##[b][color=red]CamClass[/color][/b] encompasses ALL cameras, including the player cam.
class_name CamClass
extends Camera2D

@export_group("Debug")
##Whether you want to debug the PlayerCam
@export var debug_me : bool = false
##Whether you want the debug output to be verbose.[br]
##[b]NOTE[/b]: Debug Me Verbose requires Debug Me to also be enabled!
@export var debug_me_verbose : bool = false
##How you want this entity to appear in the debug output.
@export var debug_name : String = "Cam"
