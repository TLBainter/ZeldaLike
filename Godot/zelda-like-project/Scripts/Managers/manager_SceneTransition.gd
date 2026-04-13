##[b][color=cyan]SceneTransitionManager[/color][/b] is an autoload that handles all scene transitions.[br]
##Transition doors forward their data here; this script owns the full transition sequence:
##fading the screen, walking the player, changing the scene, and restoring control on arrival.[br]
extends Node

#region SIGNALS
##Emitted after the player arrives in the new scene and control is fully restored.
signal transition_complete
#endregion SIGNALS

#region CONSTANTS
const FADE_DURATION          : float = 0.5
const WALK_DURATION          : float = 0.35
const WALK_DISTANCE          : float = 18.0
const ARRIVAL_WALK_DURATION  : float = WALK_DURATION * 1.5
const OVERLAY_CANVAS_LAYER   : int   = 128  # Renders above all game content
#endregion CONSTANTS

#region VARIABLES
var _overlay_layer    : CanvasLayer
var _overlay          : ColorRect
var _is_transitioning : bool = false

## Data stored across the scene change
var _pending_scene     : PackedScene = null
var _pending_door_name : String = ""
var _exit_walk_dir     : Vector2 = Vector2.DOWN

## Player carried across the scene change
var _carried_player   : Node = null
#endregion VARIABLES

#region READY
func _ready() -> void:
	_build_overlay()
#endregion READY

#region OVERLAY
func _build_overlay() -> void:
	_overlay_layer               = CanvasLayer.new()
	_overlay_layer.layer         = OVERLAY_CANVAS_LAYER
	_overlay_layer.name          = "TransitionOverlay"
	add_child(_overlay_layer)

	_overlay                     = ColorRect.new()
	_overlay.color               = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.anchor_right        = 1.0
	_overlay.anchor_bottom       = 1.0
	_overlay.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_overlay)
#endregion OVERLAY

#region PUBLIC API
##Called by a [TransitionDoor] when the player enters its trigger.[br]
##[param player] — the Player node (parent of CharacterBody2D).[br]
##[param target_scene] — the packed scene to load.[br]
##[param target_door_name] — the name of the door node in [param target_scene] to arrive at.[br]
##[param exit_walk_dir] — normalised direction the player should walk when exiting (away from transition target).
func request_transition(player        : Node,
						target_scene  : PackedScene,
						target_door_name : String,
						exit_walk_dir : Vector2) -> void:
	if _is_transitioning:
		return
	_is_transitioning  = true
	_pending_scene     = target_scene
	_pending_door_name = target_door_name
	_exit_walk_dir     = exit_walk_dir
	_execute_exit(player)
#endregion PUBLIC API

#region EXIT SEQUENCE
func _execute_exit(player : Node) -> void:
	player.freeze_input(true)
	_play_walk_anim(player, _exit_walk_dir)

	var elapsed   : float   = 0.0
	var total     : float   = maxf(WALK_DURATION, FADE_DURATION)
	var start_pos : Vector2 = player.body.global_position
	var end_pos   : Vector2 = start_pos + _exit_walk_dir * WALK_DISTANCE
	while elapsed < total:
		await get_tree().process_frame
		elapsed = minf(elapsed + get_process_delta_time(), total)
		player.body.global_position = start_pos.lerp(end_pos, minf(elapsed / WALK_DURATION, 1.0))
		_overlay.color.a            = lerpf(0.0, 1.0,         minf(elapsed / FADE_DURATION, 1.0))

	player.get_parent().remove_child(player)
	add_child(player)
	_carried_player = player

	get_tree().change_scene_to_packed(_pending_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	_execute_arrival()
#endregion EXIT SEQUENCE

#region ARRIVAL SEQUENCE
func _execute_arrival() -> void:
	var player    : Node = _carried_player
	_carried_player = null

	var target_door : Node = _find_door(_pending_door_name)

	if not player or not target_door:
		push_error("SceneTransitionManager: could not find player or target door '%s'." % _pending_door_name)
		_finish_transition(player)
		return

	if player.get("player_cam") != null:
		player.player_cam.set_physics_process(false)

	remove_child(player)
	get_tree().current_scene.add_child(player)
	player.body.global_position = target_door.get_spawn_position()

	if player.get("player_cam") != null:
		player.player_cam.snap_to_player()

	player.freeze_input(true)

	var toward_target : Vector2 = target_door.get_target_direction_from_spawn()
	_play_walk_anim(player, toward_target)

	var target_pos : Vector2 = target_door.get_target_global_position()
	var elapsed    : float   = 0.0
	var total      : float   = maxf(ARRIVAL_WALK_DURATION, FADE_DURATION)
	var start_pos  : Vector2 = player.body.global_position
	while elapsed < total:
		await get_tree().process_frame
		elapsed = minf(elapsed + get_process_delta_time(), total)
		player.body.global_position = start_pos.lerp(target_pos, minf(elapsed / ARRIVAL_WALK_DURATION, 1.0))
		_overlay.color.a            = lerpf(1.0, 0.0,            minf(elapsed / FADE_DURATION,         1.0))

	_finish_transition(player)
#endregion ARRIVAL SEQUENCE

#region FINISH
func _finish_transition(player : Node) -> void:
	if player:
		player.freeze_input(false)
		if player.get("player_cam") != null:
			player.player_cam.set_physics_process(true)
	
	_reset_all_door_triggers()
	_is_transitioning = false
	transition_complete.emit()
#endregion FINISH

#region HELPERS
func _play_walk_anim(player : Node, direction : Vector2) -> void:
	if not (player.anim and player.anim is CharacterAnimator):
		return
	var anim : CharacterAnimator = player.anim
	anim.set_facing(direction)
	anim.play_directional_anim(anim.walk_prefix)

func _reset_all_door_triggers() -> void:
	var root := get_tree().current_scene
	if not root:
		return
	for door in root.find_children("*", "TransitionDoor", true, false):
		door.reset_trigger()

func _find_door(door_name : String) -> Node:
	var root := get_tree().current_scene
	if not root:
		return null
	if root.name == door_name:
		return root
	return root.find_child(door_name, true, false)
#endregion HELPERS
