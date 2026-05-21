##[b][color=red]StateStunned[/b][/color] - NoControl state entered after an enemy is hit by a grapple rebound.[br]
##Freezes all layers and displays stun particles for a weight-based duration.[br]
##Ends early if the enemy takes damage; transitions to CHASE on normal timeout.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StateStunned
extends State

const STUN_PARTICLES_SCENE = preload("res://Scenes/VFX/Particle Systems/vfx_enemyState_Stunned.tscn")

var _timer: float = 0.0
var _stun_particles: GPUParticles2D = null

#region STATE LIFECYCLE

func _ready() -> void:
	set_process(false)
	super()

func enter() -> void:
	super()
	coordinator.freeze_all()
	lock_facing()
	_timer = _stun_duration()
	_spawn_particles()
	set_process(true)
	var character: Character = root as Character
	if character and character.health:
		_safe_connect(character.health.damage_taken, _on_damage_taken)

func _process(delta: float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	_timer -= delta
	if _timer <= 0.0:
		set_process(false)
		_safe_transition(StateID.CHASE)

func exit() -> void:
	set_process(false)
	var character: Character = root as Character
	if character and character.health:
		_safe_disconnect(character.health.damage_taken, _on_damage_taken)
	_release_particles()
	coordinator.unfreeze_all()
	unlock_facing()
	super()

#endregion STATE LIFECYCLE

#region HANDLERS

func _on_damage_taken(_effect: DamageEffectResource, _position: Vector2, _amount: int) -> void:
	if not state_machine or state_machine.current_state != self:
		return
	set_process(false)
	_safe_transition(StateID.DAMAGED)

#endregion HANDLERS

#region HELPERS

func _stun_duration() -> float:
	if not root or not root.has_method("get_weight_class"):
		return 0.25
	match root.get_weight_class():
		1: return 1.0
		2: return 0.5
		_: return 0.3

func _spawn_particles() -> void:
	_stun_particles = STUN_PARTICLES_SCENE.instantiate()
	if root and root.body:
		root.body.add_child(_stun_particles)

func _release_particles() -> void:
	if not is_instance_valid(_stun_particles):
		_stun_particles = null
		return
	_stun_particles.emitting = false
	var lifetime: float = _stun_particles.lifetime
	get_tree().create_timer(lifetime).timeout.connect(func():
		if is_instance_valid(_stun_particles):
			_stun_particles.queue_free()
	)
	_stun_particles = null

#endregion HELPERS
