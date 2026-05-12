##[b][color=red]EnemyInputComponent[/color][/b] is the AI-driven alternative to [b]PlayerInputComponent[/b].[br]
##Emits [signal InputComponent.on_move] each frame so the enemy uses the same movement pipeline as the player.[br]
##Supports Idle, Roam, and Chase modes. Detection and loss conditions are configurable via exports.[br]
##Chase and Roam use [NavigationAgent2D] (assigned via [member Character.nav_agent]) when available.
class_name EnemyInputComponent
extends InputComponent

#region ENUMS

enum AIMode { IDLE, ROAM, CHASE }
##How the enemy starts tracking the player.
enum DetectTrigger {
	##The enemy activates when the player's body enters [member player_detect_area].
	PLAYER_ENTERS_DETECT_AREA,
	##The enemy activates when notified by the room manager. See [method notify_player_entered_room].
	PLAYER_ENTERS_ROOM,
}
##How the enemy stops tracking the player.
enum LoseTrigger {
	##The enemy gives up when the player moves beyond [member lose_distance] from the enemy.
	PLAYER_IS_X_DISTANCE,
	##The enemy gives up when the player dies (not yet implemented).
	PLAYER_DIES,
}

#endregion ENUMS

#region VARIABLES

@export_group("Detection")
@export var detect_trigger : DetectTrigger = DetectTrigger.PLAYER_ENTERS_DETECT_AREA
@export var player_detect_area : Area2D
@export_group("Losing")
@export var lose_trigger : LoseTrigger = LoseTrigger.PLAYER_IS_X_DISTANCE
##Distance in pixels from the enemy body at which the player is considered lost.
@export_range(0, 2000, 1, "suffix:px") var lose_distance : float = 150.0
@export_group("Default Behavior")
@export var default_mode : AIMode = AIMode.IDLE
##Radius (px) around current position used when picking a random roam destination.
@export_range(32, 512, 8, "suffix:px") var roam_radius : float = 96.0

#region SIGNALS

signal player_detected(player_body : Node2D)
signal player_lost

#endregion SIGNALS

#region INTERNAL

var _current_mode : AIMode = AIMode.IDLE
var _player : Node2D = null
const MIN_COMBAT_RANGE : float = 24.0
const RETREAT_DISTANCE : float = 64.0
##Exit retreat mode only when this far from the player, preventing threshold oscillation.
const RETREAT_HYSTERESIS : float = 16.0

var _roam_target : Vector2 = Vector2.ZERO
var _retreating : bool = false
var _hurt_retreat_timer : float = 0.0
var _hurt_retreat_base_speed : float = 0.0
##Read-only view of retreat state; consumed by StateChase for stuck detection.
var is_retreating : bool:
	get: return _retreating
var _nav_debug_timer : float = 0.0
var _progress_check_pos : Vector2 = Vector2.ZERO
## Last position given to nav.target_position - only update when player moves > threshold.
var _last_nav_target : Vector2 = Vector2.ZERO
const _NAV_TARGET_UPDATE_THRESHOLD : float = 24.0
var _last_facing : String = ""

#endregion INTERNAL

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	if debug_name == "":
		debug_name = name
	if player_detect_area:
		player_detect_area.body_entered.connect(_on_detect_area_body_entered)
		player_detect_area.body_exited.connect(_on_detect_area_body_exited)
	_current_mode = default_mode
	set_process(default_mode != AIMode.IDLE)

func _process(delta : float) -> void:
	if _hurt_retreat_timer > 0.0:
		_hurt_retreat_timer -= delta
		if _hurt_retreat_timer <= 0.0:
			var character := _find_entity_parent() as Character
			if character and _hurt_retreat_base_speed > 0.0:
				character.move_speed = _hurt_retreat_base_speed
			_hurt_retreat_base_speed = 0.0
	_update_detect_area_rotation()
	match _current_mode:
		AIMode.ROAM:
			_process_roam(delta)
		AIMode.CHASE:
			_process_chase(delta)

func _update_detect_area_rotation() -> void:
	if not player_detect_area:
		return
	var entity = _find_entity_parent()
	if not entity or not entity.get("anim"):
		return
	var facing : String = entity.anim.facing if entity.anim else "down"
	if facing == _last_facing:
		return
	_last_facing = facing
	match facing:
		"down":  player_detect_area.rotation = 0.0
		"left":  player_detect_area.rotation = PI / 2.0
		"up":    player_detect_area.rotation = PI
		"right": player_detect_area.rotation = -PI / 2.0

func _process_roam(_delta : float) -> void:
	var character := _find_entity_parent() as Character
	if not character or not character.body:
		return
	var nav := character.nav_agent
	if not nav:
		return
	if nav.is_navigation_finished() or _roam_target == Vector2.ZERO:
		_pick_roam_target(character)
		return
	if nav.get_current_navigation_path().is_empty():
		on_move.emit(Vector2.ZERO, 0.0)
		return
	var next_pos := nav.get_next_path_position()
	var dir := next_pos - character.body.global_position
	if dir.length_squared() < 1.0:
		on_move.emit(Vector2.ZERO, 0.0)
		return
	on_move.emit(dir.normalized(), 1.0)

func _pick_roam_target(character : Character) -> void:
	if randf() < 0.25:
		_roam_target = character.body.global_position
		character.nav_agent.target_position = _roam_target
		on_move.emit(Vector2.ZERO, 0.0)
		_debug_verbose("Roam: pausing at current position.")
		return
	var nav_map : RID = character.body.get_world_2d().get_navigation_map()
	var offset := Vector2(
		randf_range(-roam_radius, roam_radius),
		randf_range(-roam_radius, roam_radius)
	)
	var raw := character.body.global_position + offset
	_roam_target = NavigationServer2D.map_get_closest_point(nav_map, raw)
	character.nav_agent.target_position = _roam_target
	_debug_verbose(str("Roam: new target ", _roam_target))

func _process_chase(delta : float) -> void:
	if not _player or not is_instance_valid(_player):
		_player = null
		_retreating = false
		set_mode(default_mode)
		player_lost.emit()
		return
	var character := _find_entity_parent() as Character
	if not character or not character.body:
		return
	var player_body := _player.get("body") as Node2D
	var player_pos : Vector2 = player_body.global_position if player_body else _player.global_position
	if lose_trigger == LoseTrigger.PLAYER_IS_X_DISTANCE:
		var dist : float = character.body.global_position.distance_to(player_pos)
		if dist > lose_distance:
			_debug_log(str("Player lost - out of range (", snapped(dist, 0.1), "px > ", lose_distance, "px)."))
			_player = null
			set_mode(default_mode)
			player_lost.emit()
			return
	var nav := character.nav_agent
	if not nav:
		var to_player := (player_pos - character.body.global_position).normalized()
		on_move.emit(to_player, 1.0)
		return
	var dist_to_player : float = character.body.global_position.distance_to(player_pos)
	if not _retreating and dist_to_player < MIN_COMBAT_RANGE:
		_retreating = true
	elif _retreating and dist_to_player >= MIN_COMBAT_RANGE + RETREAT_HYSTERESIS:
		_retreating = false
	var desired_nav_target : Vector2
	if _retreating:
		desired_nav_target = _find_retreat_target(character, player_pos)
	else:
		desired_nav_target = player_pos
	if desired_nav_target.distance_to(_last_nav_target) > _NAV_TARGET_UPDATE_THRESHOLD:
		nav.target_position = desired_nav_target
		_last_nav_target = desired_nav_target
	if debug_me:
		nav.debug_enabled = true
		_nav_debug_timer -= delta
		if _nav_debug_timer <= 0.0:
			_nav_debug_timer = 1.0
			var path := nav.get_current_navigation_path()
			var next_dbg : Vector2 = nav.get_next_path_position() if not nav.is_navigation_finished() else Vector2.ZERO
			var mov_frozen : bool = character.state_machine != null \
				and character.state_machine.movement_layer != null \
				and not character.state_machine.movement_layer.is_active
			var moved_px : float = character.body.global_position.distance_to(_progress_check_pos) \
				if _progress_check_pos != Vector2.ZERO else -1.0
			print_rich(
				"[color=orange]", debug_name, " NAV[/color]",
				"  body=", character.body.global_position,
				"  target=", player_pos,
				"  finished=", nav.is_navigation_finished(),
				"  path_pts=", path.size(),
				"  next=", next_dbg,
				"  dist=", snapped(character.body.global_position.distance_to(player_pos), 0.1),
				"  mov_layer_frozen=", mov_frozen,
				"  moved_1s=", (str(snapped(moved_px, 0.1), "px") if moved_px >= 0.0 else "n/a"),
				"\n  path=", path
			)
			if debug_me and moved_px >= 0.0 and moved_px < 4.0 and not mov_frozen:
				print_rich("[color=yellow]", debug_name, " NO-PROGRESS[/color]",
					"  body=", character.body.global_position,
					"  nav_next=", next_dbg,
					"  moved=", snapped(moved_px, 0.1), "px - unfrozen but not advancing")
			_progress_check_pos = character.body.global_position
	if nav.is_navigation_finished():
		if debug_me:
			print_rich("[color=cyan]", debug_name, " NAV-DONE[/color]",
				"  body=", snapped(character.body.global_position, Vector2(0.1, 0.1)),
				"  player=", snapped(player_pos, Vector2(0.1, 0.1)),
				"  dist=", snapped(character.body.global_position.distance_to(player_pos), 0.1),
				"  target_desired=", nav.target_desired_distance)
		on_move.emit(Vector2.ZERO, 0.0)
		return
	if nav.get_current_navigation_path().is_empty():
		on_move.emit(Vector2.ZERO, 0.0)
		return
	var next_pos := nav.get_next_path_position()
	var dir := next_pos - character.body.global_position
	if dir.length_squared() < 1.0:
		on_move.emit(Vector2.ZERO, 0.0)
		return
	on_move.emit(dir.normalized(), 1.0)

##Samples 8 arc positions around [param player_pos] at [constant RETREAT_DISTANCE], fanning from
##directly-away toward sideways, and returns the first navigable point that keeps the enemy
##at least [constant MIN_COMBAT_RANGE] from the player. Falls back to the raw away point if none qualify.
func _find_retreat_target(character : Character, player_pos : Vector2) -> Vector2:
	var nav_map : RID = character.body.get_world_2d().get_navigation_map()
	var body_pos : Vector2 = character.body.global_position
	var away_angle : float = (body_pos - player_pos).angle()
	var angle_offsets : Array[float] = [0.0, PI/4.0, -PI/4.0, PI/2.0, -PI/2.0, 3.0*PI/4.0, -3.0*PI/4.0, PI]
	for offset in angle_offsets:
		var test_angle : float = away_angle + offset
		var candidate : Vector2 = player_pos + Vector2(cos(test_angle), sin(test_angle)) * RETREAT_DISTANCE
		var nav_pt : Vector2 = NavigationServer2D.map_get_closest_point(nav_map, candidate)
		if nav_pt.distance_to(candidate) < 16.0 and nav_pt.distance_to(player_pos) >= MIN_COMBAT_RANGE:
			return nav_pt
	var fallback := player_pos + Vector2(cos(away_angle), sin(away_angle)) * RETREAT_DISTANCE
	return NavigationServer2D.map_get_closest_point(nav_map, fallback)

func _on_detect_area_body_entered(body : Node2D) -> void:
	if detect_trigger != DetectTrigger.PLAYER_ENTERS_DETECT_AREA:
		return
	# Guard against spurious re-fires caused by the detection area rotating
	# with facing direction (which sweeps the player body through the area boundary).
	if _player != null:
		return
	var parent = body.get_parent()
	if parent is Player:
		_player = parent
		player_detected.emit(parent)
		set_mode(AIMode.CHASE)
		_debug_log("Player detected via detection area.")

func _on_detect_area_body_exited(_body : Node2D) -> void:
	pass

##Sets the AI mode. Resets roam target when switching to ROAM so a fresh destination is chosen.
func set_mode(mode : AIMode) -> void:
	_current_mode = mode
	_last_nav_target = Vector2.ZERO
	if mode == AIMode.ROAM:
		_roam_target = Vector2.ZERO
	if mode != AIMode.CHASE:
		_retreating = false
	if mode == AIMode.IDLE:
		on_move.emit(Vector2.ZERO, 0.0)
		_update_detect_area_rotation()
		set_process(false)
	else:
		set_process(true)

##Called by the room manager when the player enters the room.[br]
##Only activates the enemy if [member detect_trigger] is set to [constant DetectTrigger.PLAYER_ENTERS_ROOM].
func notify_player_entered_room(player : Node2D) -> void:
	if detect_trigger != DetectTrigger.PLAYER_ENTERS_ROOM:
		return
	_player = player
	player_detected.emit(player)
	set_mode(AIMode.CHASE)
	_debug_log("Player entered room - chase activated.")

##Temporarily boosts the character's move speed by [param speed_mult] for [param duration] seconds.[br]
##Safe to call while a boost is already active - extends duration without stacking multipliers.
func begin_hurt_retreat(duration : float, speed_mult : float) -> void:
	var character := _find_entity_parent() as Character
	if not character:
		return
	if _hurt_retreat_timer <= 0.0:
		_hurt_retreat_base_speed = character.move_speed
	character.move_speed = _hurt_retreat_base_speed * speed_mult
	_hurt_retreat_timer = duration
	set_process(true)

##Returns the currently tracked player node, or null if not tracking.
func get_player() -> Node2D:
	return _player

#endregion FUNCTIONS
