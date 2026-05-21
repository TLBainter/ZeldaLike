##[b][color=red]SpellcastGrappleState[/color][/b] - NoControl state for the Grapple Spell.[br]
##Spawns a GrappleSpell scene at the directional spawn point on enter, listens for wall hit
##and retract signals, and returns to StateInitialized on completion, cancel, or interrupt.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name SpellcastGrappleState
extends SpellcastState

@export_group("Sprites")
@export var hand_open: Texture2D
@export var hand_closed: Texture2D
@export var chain_wide: Texture2D

@export_group("Settings")
@export var extension_speed: float = 60.0
@export_range(1.1, 5.0) var retraction_multiplier: float = 2.0
@export var max_distance: float = 64.0

const GRAPPLE_SCENE = preload("res://Scenes/Spells/Grapple/GrappleSpell.tscn")
const RETRACT_DELAY: float = 0.25
const LATCH_APPROACH_DIST: float = 12.0
const PLAYER_PULL_SPEED: float = 200.0

var _grapple: Node2D
var _cast_slot: int = -1
var _retract_timer: float = 0.0
var _waiting_to_retract: bool = false
var _entity_latched: Node = null
var _is_pull_player: bool = false
var _player_pull_active: bool = false
var _player_pull_destination: Vector2 = Vector2.ZERO

#region SETUP

##Call before [method enter]. Stores which action button slot triggered the cast.
func prepare(slot: int) -> void:
	_cast_slot = slot

#endregion SETUP

#region STATE LIFECYCLE

func enter() -> void:
	_waiting_to_retract = false
	_retract_timer = 0.0
	_entity_latched = null
	_is_pull_player = false
	_player_pull_active = false
	super.enter()
	if _cast_rejected:
		return
	set_physics_process(true)
	_spawn_grapple()
	if root and root.audio:
		root.audio.play_grapple_init_sound()

func _physics_process(delta: float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_physics_process(false)
		return
	if _waiting_to_retract:
		_retract_timer -= delta
		if _retract_timer <= 0.0:
			_waiting_to_retract = false
			if _grapple and is_instance_valid(_grapple):
				_grapple.start_retract()
	if _player_pull_active:
		var to_dest: Vector2 = _player_pull_destination - root.body.global_position
		if to_dest.length() <= 4.0:
			_apply_grapple_rebound()
			_player_pull_active = false
			_entity_latched = null
			_cleanup_grapple()
			_safe_transition(StateID.INITIALIZED)
		else:
			root.body.global_position += to_dest.normalized() * PLAYER_PULL_SPEED * delta

func exit() -> void:
	set_physics_process(false)
	_cleanup_grapple()
	super.exit()

#endregion STATE LIFECYCLE

#region INTERRUPT / CANCEL

func _on_action_button_pressed(btn: String) -> void:
	if btn == "actionButton4" or (_cast_slot > 0 and btn == "actionButton" + str(_cast_slot)):
		_on_cancelled()

func _on_cancelled() -> void:
	_cleanup_grapple()
	super._on_cancelled()

func _on_interrupted() -> void:
	_cleanup_grapple()
	super._on_interrupted()

#endregion INTERRUPT / CANCEL

#region GRAPPLE MANAGEMENT

func _spawn_grapple() -> void:
	var facing: String = root.anim.facing if root and root.anim else "down"
	var spawn_name: String = "GrappleSpawn" + facing.capitalize()
	var spawn_node = root.body.get_node("GrappleSpawnArea/" + spawn_name) if root and root.body else null
	if not spawn_node:
		_debug_log("Could not find spawn node: " + spawn_name)
		_safe_transition(StateID.INITIALIZED)
		return

	_grapple = GRAPPLE_SCENE.instantiate()
	root.get_parent().add_child(_grapple)
	_grapple.global_position = spawn_node.global_position
	_grapple.initialize(
		facing_to_vector(facing),
		extension_speed,
		retraction_multiplier,
		max_distance,
		hand_open, hand_closed, chain_wide
	)
	_grapple.wall_hit.connect(_on_wall_hit)
	_grapple.retract_complete.connect(_on_retract_complete)
	_grapple.entity_hit.connect(_on_entity_hit)
	_grapple.latch_pull_complete.connect(_on_latch_pull_complete)
	_grapple.chain_extended.connect(_on_chain_extended)
	_grapple.chain_retracted.connect(_on_chain_retracted)
	if root and root.body:
		_grapple.exclude_body(root.body)

func _cleanup_grapple() -> void:
	if _entity_latched and is_instance_valid(_entity_latched):
		if _entity_latched is Character:
			var grappled_state = _entity_latched.state_machine.get_transition(StateID.GRAPPLED)
			if grappled_state and grappled_state.has_method("end_grapple"):
				grappled_state.end_grapple()
			else:
				_entity_latched.freeze_input(false)
	_entity_latched = null
	_player_pull_active = false
	if _grapple and is_instance_valid(_grapple):
		if _grapple.wall_hit.is_connected(_on_wall_hit):
			_grapple.wall_hit.disconnect(_on_wall_hit)
		if _grapple.retract_complete.is_connected(_on_retract_complete):
			_grapple.retract_complete.disconnect(_on_retract_complete)
		if _grapple.entity_hit.is_connected(_on_entity_hit):
			_grapple.entity_hit.disconnect(_on_entity_hit)
		if _grapple.latch_pull_complete.is_connected(_on_latch_pull_complete):
			_grapple.latch_pull_complete.disconnect(_on_latch_pull_complete)
		if _grapple.chain_extended.is_connected(_on_chain_extended):
			_grapple.chain_extended.disconnect(_on_chain_extended)
		if _grapple.chain_retracted.is_connected(_on_chain_retracted):
			_grapple.chain_retracted.disconnect(_on_chain_retracted)
		_grapple.queue_free()
	_grapple = null

func _on_wall_hit() -> void:
	_waiting_to_retract = true
	_retract_timer = RETRACT_DELAY

func _on_retract_complete() -> void:
	if root and root.audio:
		root.audio.play_grapple_exit_sound()
	_cleanup_grapple()
	_safe_transition(StateID.INITIALIZED)

func _on_chain_extended() -> void:
	if root and root.audio:
		root.audio.play_grapple_chain_extend_sound()

func _on_chain_retracted() -> void:
	if root and root.audio:
		root.audio.play_grapple_chain_retract_sound()

func _on_entity_hit(entity: Node) -> void:
	var entity_weight_raw: int = 0
	var entity_weight_class: int = 0

	if entity is Character:
		if not entity.stats or not entity.stats.resource:
			_on_wall_hit()
			return
		entity_weight_raw = entity.stats.resource.weight
		entity_weight_class = entity.get_weight_class()
		if entity_weight_raw >= 100 or not entity.is_in_group("enemies"):
			_on_wall_hit()
			return
	elif entity is DynamicThing:
		if not entity.object_data or not entity.object_data.pullable:
			_on_wall_hit()
			return
		_entity_latched = entity
		_is_pull_player = false
		_grapple.setup_latch_pull_target(entity, true)
		return
	else:
		_on_wall_hit()
		return

	var player_weight_class: int = root.get_weight_class()

	if entity_weight_class == player_weight_class:
		if entity is Character:
			entity.health.damaged(1, root.body.global_position)
		_on_wall_hit()
	elif entity_weight_class < player_weight_class:
		_entity_latched = entity
		_is_pull_player = false
		if entity is Character:
			var grappled_state: State = entity.state_machine.get_transition(StateID.GRAPPLED)
			if grappled_state:
				entity.state_machine.request_no_control_change(grappled_state)
			else:
				entity.freeze_input(true)
		_grapple.setup_latch_pull_target(entity, true)
	else:
		_entity_latched = entity
		_is_pull_player = true
		var dir: Vector2 = facing_to_vector(root.anim.facing if root and root.anim else "down")
		_player_pull_destination = entity.body.global_position - dir * LATCH_APPROACH_DIST
		_grapple.setup_latch_pull_target(entity, false)

func _on_latch_pull_complete() -> void:
	if _is_pull_player:
		_player_pull_active = true
		set_physics_process(true)
	else:
		_apply_grapple_rebound()
		_entity_latched = null
		_cleanup_grapple()
		_safe_transition(StateID.INITIALIZED)

func _apply_grapple_rebound() -> void:
	if not _entity_latched or not is_instance_valid(_entity_latched):
		return
	if not (_entity_latched is Character):
		return
	var player_class: int = root.get_weight_class()
	var entity_class: int = _entity_latched.get_weight_class()
	var grapple_dir: Vector2 = facing_to_vector(root.anim.facing if root and root.anim else "down")
	var entity_dist: float = maxf(4.0, _grapple_kb_dist(entity_class, player_class))
	var player_dist: float = maxf(4.0, _grapple_kb_dist(player_class, entity_class) * 0.25)
	var rebound_state: State = _entity_latched.state_machine.get_transition(StateID.GRAPPLE_REBOUND)
	if rebound_state and rebound_state.has_method("setup"):
		rebound_state.setup(grapple_dir, entity_dist)
		_entity_latched.state_machine.request_no_control_change(rebound_state)
	else:
		var grappled_state = _entity_latched.state_machine.get_transition(StateID.GRAPPLED)
		if grappled_state and grappled_state.has_method("end_grapple"):
			grappled_state.end_grapple()
		else:
			_entity_latched.freeze_input(false)
	if player_dist > 0.0:
		root.call_deferred("receive_knockback", -grapple_dir, player_dist)

static func _grapple_kb_dist(first: int, second: int) -> float:
	match second - first:
		2:  return 24.0
		1:  return 12.0
		0:  return 6.0
		-1: return 3.0
		_:  return 6.0

#endregion GRAPPLE MANAGEMENT
