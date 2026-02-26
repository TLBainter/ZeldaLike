##[b][color=red]PlayerCam[/color][/b] is the camera class responsible for the player; it handles room transitions, zoom, etc.[br]
##If you want to have cutscenes that, for example, transfer to other spots on the map, use a different camera class.
class_name PlayerCam
extends CamClass

#region VARIABLES
@export_group("PlayerCam Components")
##A reference to the main player node.
@export var root : Player
##The player's body.
@onready var player : CharacterBody2D = root.body
##The players input controller.
@onready var input : InputComponent = root.input
@export_group("PlayerCam Variables")
##Where you want the camera to stop horizontally.
@export var horizontal_dead_zone : float = 30.0
##Where you want the camera to stop vertically.
@export var vertical_dead_zone : float = 30.0
#TODO: Make the ground variable an array, someday—or something to that effect. Could be a dictionary?[br]
#This will be necessary if I am going to have more than one ground tilemap layer in a single scene!
##The ground layer of the level.
var ground : GroundTilemap

#Initialize position
func _ready() -> void:
	#Get a reference to the GroundTilemap of a level on ready.
	set_ground()
	set_cam_limits()
	#TODO: Use the input signal to call the camera movement.
	#BUG: This does not currently work; using physics process temporarily.
	#input.onMove.connect(update_cam_pos)

#TODO: instead of _physics_process, need to make it so the camera only moves when it needs to.
#This will limit resource drain. Calling this every frame is dicey.
func _physics_process(delta: float) -> void:
	update_cam_pos(delta)

##Sets the value of the ground tilemap(s)
func set_ground() -> void:
	#sets the value of ground to be the FIRST ground tilemap in the scene; if there is more than one, this will not work.
	#TODO: Revisit this if there is ever going to be more than a single ground tilemap in a scene.[br]
	#May need to make this an array.
	ground = get_tree().current_scene.find_children("*", "GroundTilemap").front() as GroundTilemap
	if debug_me:
		if ground != null:
			print("ground found!")
			print("ground is: ", ground)
		else:
			print("ground not found...")

##Defines the camera bounds for a scene/level.
func set_cam_limits():
	global_position = player.global_position
	#region cam limits variables
	##the utilized rectangular enclosure of a scene
	var used_rect = ground.get_used_rect()
	##the tile size in pixels for the defined ground tile set
	var cell_size = ground.tile_set.tile_size
	##the total width of the ground layer
	var map_width = used_rect.size.x * cell_size.x
	##the total height of the ground layer
	var map_height = used_rect.size.y * cell_size.y
	#endregion
	#region cam limits
	limit_left = used_rect.position.x * cell_size.x
	limit_right = limit_left + map_width
	limit_top = used_rect.position.y * cell_size.y
	limit_bottom = limit_top + map_height
	#endregion
	#region debug cam limits
	if debug_me:
		if debug_me_verbose:
			print(debug_name, " cam limit values established with values of:")
			print("\tused_rect: ", used_rect)
			print("\tcell_size: ", cell_size)
			print("\tmap_width: ", map_width)
			print("\tmap_height: ", map_height)
			print("\tlimit_left: ", limit_left)
			print("\tlimit_right: ", limit_right)
			print("\tlimit_top: ", limit_top)
			print("\tlimit_bottom: ", limit_bottom)
		else:
			print(debug_name, " tilemap size determined with values of: ", map_width, "(x)", " and ", map_height, "(y)")
			print(debug_name, " has established its cam limits.")
	#endregion

##Update's the camera position.
func update_cam_pos(delta):
	#Do not proceed if player is not established
	if not player:
		return
	#region update_cam_pos variables
	##The player's current position when this fucntion is called.
	var player_pos = player.global_position
	##The camera's current position when this function is called.
	var camera_pos = global_position
	##The target position for this update.
	var target_pos = camera_pos
	#endregion update_cam_pos variables
	
	#Horizontal Movement Control
	if abs(player_pos.x - camera_pos.x) > horizontal_dead_zone:
		target_pos.x = player_pos.x
	#Vertical Movement Control
	if player_pos.y < camera_pos.y - vertical_dead_zone:
		target_pos.y = player_pos.y
	elif player_pos.y > camera_pos.y + vertical_dead_zone:
		target_pos.y = player_pos.y
	
	#Clamp target position
	#BUG: These variables are not currently used. You can ignore errors stemming from these, for now.
	#region set clamp variables
	##The viewport size with zoom taken into account.
	#var viewport_size = get_viewport_rect().size / zoom
	##The minimum position on the x axis
	#var min_x = limit_left + viewport_size.x / 2
	##the maximum position on the x axis
	#var max_x = limit_right - viewport_size.x / 2
	##The minimum position on the x axis
	#var min_y = limit_top + viewport_size.y / 2
	##the maximum position on the x axis
	#var max_y = limit_bottom - viewport_size.y / 2
	#endregion clamp variables
	
	# smooth movement control; uses delta to move the camera at the player's speed
	position.x = move_toward(position.x, target_pos.x, abs(player.velocity.x) * delta)
	position.y = move_toward(position.y, target_pos.y, abs(player.velocity.y) * delta)
