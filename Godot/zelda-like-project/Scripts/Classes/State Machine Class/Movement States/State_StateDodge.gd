##[b][color=red]StateDodge[/color][/b] is the shared base for invulnerable, action-frozen movement states.[br]
##Extend this class for any state that grants invulnerability and freezes the action layer[br]
##(dash, backstep, future roll/teleport, etc.).[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateDodge
extends State

#region VARIABLES

const SMOKE_VFX_SCENE    = preload("res://Scenes/VFX/Particle Systems/vfx_bat_smoke.tscn")
const CLEARANCE_MARGIN      : float = 0.08
const CLEARANCE_BISECT_ITERS : int  = 12

var _dodge_executed    : bool           = false
var _smoke_vfx         : GPUParticles2D = null
var _dodge_speed       : float          = 100.0
var _original_mask     : int            = -1
var _original_layer    : int            = -1

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_physics_process(false)
	super()

##Executes the shared invulnerability + freeze-action setup.[br]
##Call after resolving [param direction] and setting [member _dodge_speed] and [member _max_dist].
func _start_dodge(direction: Vector2) -> void:
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	coordinator.freeze_action()
	coordinator.update_context("", true)
	root.body.velocity = direction * _dodge_speed
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 32  # Wall Layer only - walls always rebound; enemies/interactables handled by clearance check
	_original_layer = root.body.collision_layer
	root.body.collision_layer = 0  # invisible to enemy physics during dash; player is invulnerable anyway
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	_smoke_vfx = SMOKE_VFX_SCENE.instantiate() as GPUParticles2D
	_smoke_vfx.local_coords = false
	root.body.add_child(_smoke_vfx)
	_dodge_executed = true
	set_physics_process(true)

func exit():
	set_physics_process(false)
	if root.sprite:
		root.sprite.modulate = Color.WHITE
	if _original_mask != -1:
		root.body.collision_mask  = _original_mask
		root.body.collision_layer = _original_layer
		_original_mask  = -1
		_original_layer = -1
	root.is_dashing = false
	root.is_invulnerable = false
	unlock_facing()
	coordinator.unfreeze_action()
	if _dodge_executed:
		coordinator.start_dodge_cooldown()
		_on_dodge_complete()
	_dodge_executed = false
	_detach_smoke()
	super()

##Override to play exit audio or run other per-subclass teardown after a completed dodge.
func _on_dodge_complete() -> void:
	pass

##Returns the safe dodge distance in pixels.[br]
##Binary-searches on Character + Interactable layers to find the farthest clear position.
func _clearance_adjusted_dist(direction: Vector2, proposed_max: float) -> float:
	var saved_mask : int = root.body.collision_mask
	root.body.collision_mask = 1 | 2  # Character Layer + Interactable Layer - enemies and objects both affect clearance
	if not root.body.test_move(root.body.global_transform, direction * proposed_max):
		root.body.collision_mask = saved_mask
		return proposed_max
	var endpoint_xform : Transform2D = root.body.global_transform.translated(direction * proposed_max)
	if not root.body.test_move(endpoint_xform, Vector2.ZERO, null, CLEARANCE_MARGIN, true):
		root.body.collision_mask = saved_mask
		return proposed_max
	var lo : float = 0.0
	var hi : float = proposed_max
	for _i in range(CLEARANCE_BISECT_ITERS):
		var mid : float = (lo + hi) / 2.0
		if root.body.test_move(root.body.global_transform, direction * mid):
			hi = mid
		else:
			lo = mid
	root.body.collision_mask = saved_mask
	return lo

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
