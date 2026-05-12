##[b][color=red]UXDisplayElement[/color][/b] extends [b]UXElement[/b] for player UI displays[br]
##that position themselves relative to the player and manage a container of child GUI elements.[br]
##Provides common positioning, diagonal stacking, active element tracking,[br]
##darkening of inactive elements, and z-index management.[br]
##[br]
##Subclasses override [b]_on_display_initialized()[/b], [b]_update_gui_elements()[/b],[br]
##[b]_get_active_index()[/b], and [b]update_position()[/b].
class_name UXDisplayElement
extends UXElement

#region VARIABLES

@export_category("Display Components")
##The PackedScene for individual GUI elements (bolts, medallions, etc).
@export var gui_scene : PackedScene
##A reference to the main UI control node.
@export var root : PlayerUX
##The container node that holds the GUI element instances.
@export var gui_container : Control

@export_category("Display Settings")
@export_group("Positioning")
##The pixel offset from the player's screen position to this display.
@export var offset_distance : float = 40.0
##The diagonal spacing between stacked GUI elements.
@export var stack_spacing : float = 8.0


##The player's body reference for screen-space positioning.
var _player_body : CharacterBody2D
##The player's camera reference for coordinate conversion.
var _player_cam : CamClass
##The index of the currently active GUI element.
var _active_index : int = -1

##The four corner offset directions, in priority order.
const CORNER_OFFSETS : Array[Vector2] = [
	Vector2(1, -1),   # top-right
	Vector2(-1, -1),  # top-left
	Vector2(-1, 1),   # bottom-left
	Vector2(1, 1),    # bottom-right
]

#endregion VARIABLES

#region FUNCTIONS

##Initializes the display with player references.[br]
##Subclasses should call this via super or use [b]_on_display_initialized()[/b].
func initialize_display(player_body : CharacterBody2D, player_cam : CamClass) -> void:
	_player_body = player_body
	_player_cam = player_cam
	_on_display_initialized()

##Virtual. Called after initialize_display(). Override to connect signals, build GUI, etc.
func _on_display_initialized() -> void:
	pass

##Called each frame. Updates position while visible.
func _on_element_process(_delta : float) -> void:
	if modulate.a > 0.0:
		update_position()

##Virtual. Updates the screen-space position of the display. Override per subclass.
func update_position() -> void:
	pass

#region GUI ELEMENT MANAGEMENT

##Builds GUI element instances in the container with diagonal stacking.[br]
##First child (index 0) gets the largest offset (drawn first, behind).[br]
##Last child gets position (0,0) (drawn last, in front/on top).
func _build_gui_elements(count : int) -> void:
	if not gui_container:
		return
	for child in gui_container.get_children():
		gui_container.remove_child(child)
		child.queue_free()
	for i in range(count):
		var gui = gui_scene.instantiate()
		gui_container.add_child(gui)
		var reverse_i = count - 1 - i
		gui.position = Vector2(reverse_i * stack_spacing, reverse_i * stack_spacing)

##Applies darkening and z-index to GUI elements based on which is active.[br]
##Active element: full brightness, z_index=1.[br]
##Inactive elements: darkened to 50% brightness, z_index=0.
func _apply_active_styling(active_idx : int) -> void:
	var children = gui_container.get_children()
	_active_index = active_idx
	for i in range(children.size()):
		var gui = children[i]
		if gui and i == active_idx:
			gui.modulate = Color(1, 1, 1, 1)
			gui.z_index = 1
		else:
			gui.modulate = Color(0.5, 0.5, 0.5, 1)
			gui.z_index = 0

##Calculates the player's screen-space position from their body transform.
func _get_player_screen_pos() -> Vector2:
	if _player_body:
		return _player_body.get_global_transform_with_canvas().origin
	return Vector2.ZERO

#endregion GUI ELEMENT MANAGEMENT

#endregion FUNCTIONS
