##[b][color=red]StateBlock[/color][/b] is the base class for all block states.[br]
##Owns the directional BlockArea collision shape exports and [method _activate_shape] logic[br]
##shared by both player and enemy block variants.[br]
##[br]
##Subclass this for character-specific block behavior.
class_name StateBlock
extends State

#region VARIABLES

@export_group("Block Areas")
@export var block_area        : Area2D
@export var block_shape_up    : CollisionShape2D
@export var block_shape_down  : CollisionShape2D
@export var block_shape_left  : CollisionShape2D
@export var block_shape_right : CollisionShape2D

var _active_shape : CollisionShape2D = null

#endregion VARIABLES

#region FUNCTIONS

##Disables all four directional block shapes, then enables the one matching [param new_facing].[br]
##Pass an empty string to disable all shapes (used on exit).
func _activate_shape(new_facing: String) -> void:
	if block_shape_up:    block_shape_up.set_deferred("disabled", true)
	if block_shape_down:  block_shape_down.set_deferred("disabled", true)
	if block_shape_left:  block_shape_left.set_deferred("disabled", true)
	if block_shape_right: block_shape_right.set_deferred("disabled", true)
	_active_shape = null
	match new_facing:
		"up":    _active_shape = block_shape_up
		"down":  _active_shape = block_shape_down
		"left":  _active_shape = block_shape_left
		"right": _active_shape = block_shape_right
	if _active_shape:
		_active_shape.set_deferred("disabled", false)

#endregion FUNCTIONS
