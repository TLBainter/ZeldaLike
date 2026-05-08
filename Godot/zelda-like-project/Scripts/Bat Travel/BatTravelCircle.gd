##[b][color=red]BatTravelCircle[/color][/b] is the 32×32 interact zone at each end of a [BatTravelRoute].[br]
@tool
class_name BatTravelCircle
extends InteractableComponent

#region CONSTANTS

##Radius (pixels) at which the player is considered "nearby" for animation purposes.
const NEARBY_RADIUS: float = 96.0
##Baseline opacity when off-screen or out of nearby range (upgraded bat form).
const BASE_ALPHA_UPGRADED: float = 0.15
##Baseline opacity when off-screen or out of nearby range (plain bat form).
const BASE_ALPHA_PLAIN: float = 0.08
##Frames per second for the slow tier.
const FPS_SLOW: float = 4.0
##Frames per second for the quick (in-area) tier.
const FPS_QUICK: float = 20.0
##Frames per second while the player is actively soaring on this route.
const FPS_EXTRA_QUICK: float = 36.0
##Lerp rate (per second) applied to both FPS and opacity transitions.
const LERP_RATE: float = 6.0

#endregion CONSTANTS

#region VARIABLES

##Set automatically by [BatTravelRoute._ready].[br]
##true = this is Circle A; false = Circle B
var _is_start: bool = true

var _sprite: Sprite2D
var _total_frames: int = 1
var _current_frame: int = 0
var _frame_accum: float = 0.0

var _vis_notifier: VisibleOnScreenNotifier2D

var _player_dist: float = INF
var _player_nearby: bool = false
var _player_in_area: bool = false

var _current_fps: float = FPS_SLOW
var _current_alpha: float = BASE_ALPHA_PLAIN

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	interact_type = InteractType.CUSTOM
	context_key = "Bat Soar"
	shape_type = 0       # Circle
	shape_radius = 16.0  # 32×32 diameter
	super()

	if Engine.is_editor_hint():
		return

	for child in get_children():
		if child is Sprite2D:
			_sprite = child
			break
	if _sprite:
		_total_frames = maxi(_sprite.hframes, 1)
		_current_frame = _sprite.frame  # Preserve the start frame set in the editor.

	_vis_notifier = VisibleOnScreenNotifier2D.new()
	_vis_notifier.rect = Rect2(-16.0, -16.0, 32.0, 32.0)
	add_child(_vis_notifier)
	_vis_notifier.screen_entered.connect(_on_screen_entered)
	_vis_notifier.screen_exited.connect(_on_screen_exited)
	set_process(false)
	if _vis_notifier.is_on_screen():
		_on_screen_entered()

func _on_screen_entered() -> void:
	set_process(true)

func _on_screen_exited() -> void:
	set_process(false)

#region PROCESS

func _process(delta: float) -> void:
	_refresh_player_state()
	_update_sprite(delta)
	_update_context_key()

##Reads player position and updates proximity flags.
func _refresh_player_state() -> void:
	_player_dist = INF
	_player_nearby = false
	_player_in_area = false
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	if not "body" in player or not player.body:
		return
	_player_dist = global_position.distance_to(player.body.global_position)
	_player_nearby  = _player_dist <= NEARBY_RADIUS
	_player_in_area = _player_dist <= shape_radius

##Drives sigil animation speed and opacity based on upgrade status and player proximity.
func _update_sprite(delta: float) -> void:
	if not _sprite:
		return

	var has_upgrade := _has_upgrade()
	var traveling   := _is_traveling()

	var target_fps: float
	if has_upgrade:
		if traveling:
			target_fps = FPS_EXTRA_QUICK
		elif _player_in_area:
			target_fps = FPS_QUICK
		elif _player_nearby:
			var t: float = 1.0 - clamp((_player_dist - shape_radius) / (NEARBY_RADIUS - shape_radius), 0.0, 1.0)
			target_fps = lerp(FPS_SLOW, FPS_QUICK, t)
		else:
			target_fps = FPS_SLOW
	else:
		target_fps = FPS_SLOW

	var target_alpha: float
	if has_upgrade:
		if traveling:
			target_alpha = 1.0
		elif _player_in_area:
			target_alpha = 0.9
		elif _player_nearby:
			target_alpha = 0.75
		else:
			target_alpha = BASE_ALPHA_UPGRADED
	else:
		if _player_in_area:
			target_alpha = 0.5
		elif _player_nearby:
			target_alpha = 0.25
		else:
			target_alpha = BASE_ALPHA_PLAIN

	_current_fps   = lerp(_current_fps,   target_fps,   delta * LERP_RATE)
	_current_alpha = lerp(_current_alpha, target_alpha, delta * LERP_RATE)
	_sprite.modulate.a = _current_alpha

	_frame_accum += delta * _current_fps
	while _frame_accum >= 1.0:
		_frame_accum -= 1.0
		_current_frame = (_current_frame + 1) % _total_frames
	_sprite.frame = _current_frame

##Updates the context label to "?" when the player is in range without the upgrade.
func _update_context_key() -> void:
	if _player_in_area:
		context_key = "Bat Soar" if _has_upgrade() else "?"

#endregion PROCESS

#region INTERACTION

##Override: refresh context key as the player enters the area so the label is correct immediately.
func _on_body_entered(body: Node2D) -> void:
	if body is PlayerBody:
		context_key = "Bat Soar" if _has_upgrade() else "?"
	super._on_body_entered(body)

##Called by [StateInteract] when the player presses Interact inside this zone.[br]
func interact(user: EntityClass = null) -> void:
	var character: EntityClass = user as EntityClass
	var route := get_parent() as BatTravelRoute
	if not character or not route:
		interaction_finished.emit()
		return
	if not (character.inventory and character.inventory.has_item(ItemID.BAT_FORM_UPGRADED)):
		interaction_finished.emit()
		return
	var bat_state := character.state_machine.get_transition(StateID.BAT_TRAVEL) as StateBatTravel
	if not bat_state:
		push_error("BatTravelCircle: 'bat_travel' state not found on player. Add StateBatTravel to the Movement Layer.")
		interaction_finished.emit()
		return
	bat_state.setup(route, _is_start)
	interaction_finished.emit()
	character.state_machine.request_movement_change(bat_state)

#endregion INTERACTION

#region HELPERS

func _has_upgrade() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var player = players[0]
	return "inventory" in player and player.inventory and player.inventory.has_item(ItemID.BAT_FORM_UPGRADED)

func _is_traveling() -> bool:
	var route := get_parent() as BatTravelRoute
	if not route:
		return false
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var player = players[0]
	if not "state_machine" in player:
		return false
	var bat_state = player.state_machine.get_transition(StateID.BAT_TRAVEL) as StateBatTravel
	return bat_state != null and bat_state.is_traveling_on(route)

#endregion HELPERS

#endregion FUNCTIONS
