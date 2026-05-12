##[b][color=red]PlayerCam[/color][/b] is the camera class responsible for the player; it handles room transitions, zoom, etc.[br]
##If you want to have cutscenes that, for example, transfer to other spots on the map, use a different camera class.
class_name PlayerCam
extends CamClass

#region SIGNALS
signal zoom_changed(zoom_changed : bool)
#endregion SIGNALS

#region VARIABLES
@export_group("PlayerCam Components")
##A reference to the main player node.
@export var root : Player
##The player's body.
@onready var player : CharacterBody2D = root.body
##The audio component for the player.
@onready var audio = root.audio
##The players input controller.
@onready var input : InputComponent = root.input
@export_group("PlayerCam Variables")
@export_subgroup("DeadZones")
##Where you want the camera to stop horizontally.
@export var horizontal_dead_zone : float = 30.0
##Where you want the camera to stop vertically.
@export var vertical_dead_zone : float = 30.0
@export_subgroup("Pan and Zoom")
## The base resting zoom of the camera.[br]
## You should set this to match the zoom of the camera in-editor.
@export var init_zoom : Vector2 = zoom
## The maximum number, in pixels, that the camera can pan in any direction.
@export var max_pan_distance : Vector2 = Vector2(100.0, 80.0)
##How quickly the camera smoothly arrives at its destination
@export var smoothness : float = 12.0
## target offset value for pan lerping
var _target_offset : Vector2 = Vector2.ZERO
## target zoom value for zoom out/in lerping
var _target_zoom : Vector2 = Vector2(1.0, 1.0)
## whether the camera was just zooming
var _was_zooming : bool = false
@export_subgroup("Camera Audio")
##the audio file that plays when the camera moves by player input
@export var cam_whoosh : AudioStream
##the audio file to play when the camera resets its position after player input
@export var cam_whoosh_reverse : AudioStream
##reference to the audio player being used by the cam_whoosh sound to avoid overlapping sfx
var _current_whoosh_player : AudioStreamPlayer
##internal value that determines whether the cam_whoosh audio file should be played
var _was_cam_moved : bool = false
@export_subgroup("Detection")
##The ground layer of the level.
var ground : GroundTilemap
#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	top_level = true
	reset_zoom()
	set_ground()
	set_cam_limits()

func _physics_process(delta: float) -> void:
	var player_pos : Vector2 = player.global_position if player else global_position
	var at_target_x : bool = abs(player_pos.x - global_position.x) <= horizontal_dead_zone
	var at_target_y : bool = abs(player_pos.y - global_position.y) <= vertical_dead_zone
	var no_pan_input : bool = Input.get_vector("camLeft", "camRight", "camUp", "camDown").length() < 0.1
	var not_zooming : bool = not Input.is_action_pressed("camZoom")
	var player_still : bool = not player or player.velocity.length() < 1.0
	var offset_settled : bool = offset.distance_to(_target_offset) < 0.5
	var zoom_settled : bool = zoom.distance_to(_target_zoom) < 0.001
	if at_target_x and at_target_y and no_pan_input and not_zooming and player_still and offset_settled and zoom_settled:
		return
	update_cam_pos(delta)
	_handle_pan_zoom(delta)

##Resets the zoom to its default values.
func reset_zoom():
	zoom = init_zoom
	_target_zoom = init_zoom

##Recalibrates the camera for a new scene after the player has been reparented into it.[br]
func snap_to_player() -> void:
	set_ground()
	if ground:
		set_cam_limits()
	else:
		global_position = player.global_position
		limit_left   = -10000000
		limit_right  =  10000000
		limit_top    = -10000000
		limit_bottom =  10000000

##Sets the value of the ground tilemap(s).[br]
##This is used to determine the level's bounds.[br]
##The tilemap must have the GroundTileMap script assigned.
func set_ground() -> void:
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
	var used_rect : Rect2i = ground.get_used_rect()
	##the tile size in pixels for the defined ground tile set
	var cell_size : Vector2i = ground.tile_set.tile_size
	##the total width of the ground layer
	var map_width : int = used_rect.size.x * cell_size.x
	##the total height of the ground layer
	var map_height : int = used_rect.size.y * cell_size.y
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
	
	if abs(player_pos.x - camera_pos.x) > horizontal_dead_zone:
		target_pos.x = player_pos.x
	if abs(player_pos.y - camera_pos.y) > vertical_dead_zone:
		target_pos.y = player_pos.y
	
	
	global_position.x = move_toward(global_position.x, target_pos.x, abs(player.velocity.x) * delta)
	global_position.y = move_toward(global_position.y, target_pos.y, abs(player.velocity.y) * delta)

##Addresses inputs from the player that allow the camera to move
func _handle_pan_zoom(delta):
	var is_zooming = Input.is_action_pressed("camZoom")
	var pan_input = Input.get_vector("camLeft", "camRight", "camUp", "camDown")
	
	if is_zooming and not _was_zooming:
		zoom_changed.emit(true)
	elif not is_zooming and _was_zooming:
		zoom_changed.emit(false)
	_was_zooming = is_zooming
	
	#region Zoom
	if is_zooming:
		_target_offset = Vector2.ZERO
		var viewport_size = get_viewport_rect().size
		var current_view_width = viewport_size.x / init_zoom.x
		var current_view_height = viewport_size.y / init_zoom.y
		var target_view_width = current_view_width + (max_pan_distance.x / 2.0)
		var target_view_height = current_view_height + (max_pan_distance.y / 2.0)
		
		_target_zoom = Vector2((viewport_size.x / target_view_width), (viewport_size.y / target_view_height))
	#endregion Zoom
	else:
		_target_zoom = init_zoom
	#region Pan
		var desired_offset : Vector2 = pan_input * max_pan_distance
		var base_cam_pos = global_position
		var safe_zoom = Vector2(max(0.01, zoom.x), max(0.01, zoom.y))
		var screen_half = (get_viewport_rect().size / safe_zoom) / 2.0
		
		var allowed_left = max(0.0, (base_cam_pos.x - screen_half.x) - limit_left)
		var allowed_right = max(0.0, limit_right - (base_cam_pos.x + screen_half.x))
		var allowed_top = max(0.0, (base_cam_pos.y - screen_half.y) - limit_top)
		var allowed_bottom = max(0.0, limit_bottom - (base_cam_pos.y + screen_half.y))
		
		_target_offset.x = clamp(desired_offset.x, -allowed_left, allowed_right)
		_target_offset.y = clamp(desired_offset.y, -allowed_top, allowed_bottom)
	#endregion Pan

	#region audioHandler
	##determines whether we currently have an input pertaining to zoom/pan
	var has_input = is_zooming or pan_input.length() > 0.1
	##checks if we are about to move from our current destination
	var will_move = offset.distance_to(_target_offset) > 2.0 or zoom.distance_to(_target_zoom) > 0.01
	
	var is_new_press = Input.is_action_just_pressed("camZoom") or Input.is_action_just_pressed("camRight") or Input.is_action_just_pressed("camLeft") or Input.is_action_just_pressed("camDown") or Input.is_action_just_pressed("camUp")
	
	if not has_input:
		if _was_cam_moved:
			_play_cam_audio(cam_whoosh_reverse)
			_was_cam_moved = false
			if debug_me_verbose:
				print(debug_name, " is now playing ", cam_whoosh_reverse)
	else:
		if will_move and (not _was_cam_moved or is_new_press):
			var is_audio_playing = is_instance_valid(_current_whoosh_player) and _current_whoosh_player.playing
			if not is_audio_playing:
				_play_cam_audio(cam_whoosh)
				_was_cam_moved = true
				if debug_me_verbose:
					print(debug_name, " is now playing ", cam_whoosh)
	#endregion audioHandler

	
	#region Apply Zoom/Pan
	offset = offset.lerp(_target_offset, smoothness * delta)
	zoom = zoom.lerp(_target_zoom, smoothness * delta)
	#endregion Apply Zoom/Pan

##Handler for audio playing from the camera
func _play_cam_audio(stream : AudioStream):
	if not stream:
		return
	
	#region Whoosh SFX
	if is_instance_valid(_current_whoosh_player):
		_current_whoosh_player.stop()
		_current_whoosh_player.queue_free()
		if debug_me:
			print("Cleared _current_whoosh_player")
	_current_whoosh_player = AudioStreamPlayer.new()
	_current_whoosh_player.stream = stream
	_current_whoosh_player.bus = "UI"
	add_child(_current_whoosh_player)
	_current_whoosh_player.finished.connect(_on_sound_finished.bind(_current_whoosh_player))
	_current_whoosh_player.play()
	if debug_me:
		print("Now playing sound ", stream, " from streamer ", _current_whoosh_player)
	#endregion Whoosh SFX

func _on_sound_finished(streamer : AudioStreamPlayer):
	if is_instance_valid(streamer):
		streamer.queue_free()
	if debug_me:
		print("Cleared ", streamer, " from AudioStreamPlayer")
#endregion
