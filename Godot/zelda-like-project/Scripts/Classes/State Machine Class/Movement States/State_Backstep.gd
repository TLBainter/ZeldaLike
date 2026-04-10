##[b][color=red]StateBackstep[/color][/b] is the backstep movement state.[br]
##Available from Idle or Walk via actionButton4 when no interactable is present.[br]
##The player steps backward (opposite to facing) at dodge_speed.[br]
##Backstep distance = 0.5 * dodge_speed (pixels). No energy cost, but blocked when exhausted.[br]
##Invulnerable while backstepping. Interrupted early by wall/surface collision.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateBackstep
extends State

#region VARIABLES

const SMOKE_VFX_SCENE = preload("res://Scenes/VFX/Particle Systems/vfx_bat_smoke.tscn")

var _dodge_executed : bool = false
var _smoke_vfx : GPUParticles2D = null
var _backstep_dir : Vector2 = Vector2.ZERO
var _distance_traveled : float = 0.0
var _dodge_speed : float = 100.0
var _original_mask : int = -1
var _max_dist : float = 0.0

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_physics_process(false)
	super()

func enter():
	super()
	var character = get_character()
	if coordinator.is_exhausted():
		_debug_log("backstep blocked; exhausted.")
		var _next : State = coordinator.get_transition("idle")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "backstep+exhausted"))
		return
	if character and character.anim:
		_backstep_dir = -facing_to_vector(character.anim.facing)
	else:
		_backstep_dir = Vector2.UP
	if root and "stats" in root and root.stats and root.stats.resource:
		_dodge_speed = root.stats.resource.dodge_speed
	_distance_traveled = 0.0
	_max_dist = _clearance_adjusted_dist(_backstep_dir, 0.1 * _dodge_speed)
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	coordinator.freeze_action()
	coordinator.update_context("", true)
	root.body.velocity = _backstep_dir * _dodge_speed
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 1
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	if character and character.audio is CharacterAudioControl:
		character.audio.play_enter_backstep_sound()
	_smoke_vfx = SMOKE_VFX_SCENE.instantiate() as GPUParticles2D
	_smoke_vfx.local_coords = false
	root.body.add_child(_smoke_vfx)
	_dodge_executed = true
	set_physics_process(true)

func _physics_process(_delta : float):
	root.body.velocity = _backstep_dir * _dodge_speed
	root.body.move_and_slide()
	_distance_traveled += _delta * _dodge_speed
	if _distance_traveled >= _max_dist or root.body.get_slide_collision_count() > 0:
		var _next : State = coordinator.get_transition("idle")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "backstep+complete"))

##Returns the safe backstep distance in pixels.[br]
##Checks the full player shape at the endpoint (not just the center point), so it handles
##multiple objects in sequence and objects wider than the gap between them.[br]
##If the shape at the endpoint overlaps any interactable, searches for the front face
##of the first blocking object and returns that distance instead.[br]
##If the path is clear or the player fully clears all objects, returns proposed_max unchanged.
func _clearance_adjusted_dist(direction: Vector2, proposed_max: float) -> float:
	var saved_mask : int = root.body.collision_mask
	root.body.collision_mask = 2  # Interactable Layer only.
	if not root.body.test_move(root.body.global_transform, direction * proposed_max):
		root.body.collision_mask = saved_mask
		return proposed_max
	var endpoint_xform : Transform2D = root.body.global_transform.translated(direction * proposed_max)
	if not root.body.test_move(endpoint_xform, Vector2.ZERO, null, 0.08, true):
		root.body.collision_mask = saved_mask
		return proposed_max
	var lo : float = 0.0
	var hi : float = proposed_max
	for _i in range(12):
		var mid : float = (lo + hi) / 2.0
		if root.body.test_move(root.body.global_transform, direction * mid):
			hi = mid
		else:
			lo = mid
	root.body.collision_mask = saved_mask
	return lo

func exit():
	set_physics_process(false)
	if root.sprite:
		root.sprite.modulate = Color.WHITE
	if _original_mask != -1:
		root.body.collision_mask = _original_mask
		_original_mask = -1
	root.is_dashing = false
	root.is_invulnerable = false
	unlock_facing()
	coordinator.unfreeze_action()
	if _dodge_executed:
		coordinator.start_dodge_cooldown()
		var character = get_character()
		if character and character.audio is CharacterAudioControl:
			character.audio.play_exit_backstep_sound()
	_dodge_executed = false
	_detach_smoke()
	super()

func _detach_smoke() -> void:
	if not is_instance_valid(_smoke_vfx):
		_smoke_vfx = null
		return
	var vfx := _smoke_vfx
	_smoke_vfx = null
	vfx.reparent(root.get_tree().current_scene)
	vfx.emitting = false
	root.get_tree().create_timer(vfx.lifetime + 0.5).timeout.connect(vfx.queue_free)

#endregion FUNCTIONS
