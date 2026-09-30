@tool
##Draws four gold pixel dots at the corners of its parent panel or modal. Full rect, ignores the mouse.
class_name SogardCornerDots
extends Control

#region VARIABLES
@export_category("Settings")
##Dot color. Brass gold by default; stays gold on danger frames.
@export var dot_color : Color = Color("#c9a24a"):
	set(v):
		dot_color = v
		queue_redraw()
##Dot edge length in pixels.
@export var dot_size : int = 1:
	set(v):
		dot_size = maxi(v, 1)
		queue_redraw()
##Distance in pixels from each edge to the dot.
@export var inset : int = 2:
	set(v):
		inset = maxi(v, 0)
		queue_redraw()
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var s : Vector2 = Vector2(dot_size, dot_size)
	var right : float = floorf(size.x) - inset - dot_size
	var bottom : float = floorf(size.y) - inset - dot_size
	for p in [Vector2(inset, inset), Vector2(right, inset), Vector2(inset, bottom), Vector2(right, bottom)]:
		draw_rect(Rect2(p, s), dot_color)
#endregion FUNCTIONS
