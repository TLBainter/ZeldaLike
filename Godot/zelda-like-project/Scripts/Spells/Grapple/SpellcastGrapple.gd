##[b][color=red]SpellcastGrapple[/color][/b] - visual and physics controller for the Grapple Spell scene.[br]
##Attached to [b]GrappleSpell.tscn[/b]. Managed by [b]SpellcastGrappleState[/b], which calls
##[method initialize] after adding this node to the tree, then listens for [signal wall_hit]
##and [signal retract_complete].[br]
##[br]
##The GrappleHand CharacterBody2D moves outward from the spawn point. Chain extension nodes
##spawn at the hand's current position as it travels, filling the trail from origin to hand.
##Each chain link shows both a tall and wide sprite together. All sprites animate at ANIM_FPS starting from a random frame.
class_name SpellcastGrapple
extends Node2D

signal wall_hit
signal retract_complete
signal entity_hit(entity: Node)
signal latch_pull_complete
signal pickup_grabbed(item: WorldItem)
signal pickup_hit(item: WorldItem)
signal chain_extended
signal chain_retracted

enum Phase { EXTENDING, RETRACTING, LATCHING }

const CHAIN_EXTENSION_SCENE = preload("res://Scenes/Spells/Grapple/GrappleSpell_chainExtension.tscn")
const CLIP_SHADER = preload("res://Shaders/Spells/clip_forward.gdshader")
const HAND_PARTICLES_SCENE = preload("res://Scenes/VFX/Particle Systems/vfx_grappleHand_particles.tscn")
const CHAIN_PARTICLES_SCENE = preload("res://Scenes/VFX/Particle Systems/vfx_chain_particles.tscn")
const CHAIN_STEP: float = 10.0
const PARTICLE_FADE_IN: float = 0.15
const PARTICLE_FADE_OUT: float = 0.05
const ORIGIN_THRESHOLD: float = 4.0
const ENTITY_PULL_STOP_DIST: float = 16.0
const ANIM_FPS: float = 10.0

@export var debug_me: bool = false
@export var debug_me_verbose: bool = false

@onready var _hand: CharacterBody2D = $GrappleHand
@onready var _hand_sprite: Sprite2D = $GrappleHand/HandSprite
@onready var _hand_collision: CollisionShape2D = $GrappleHand/HandCollisionCircle
@onready var _chain_latch: Sprite2D = $GrappleHand/ChainSpawner/ChainLatch

var _dir: Vector2 = Vector2.DOWN
var _speed: float = 60.0
var _retract_speed: float = 120.0
var _max_dist: float = 64.0
var _phase: Phase = Phase.EXTENDING
var _dist_traveled: float = 0.0
var _dist_retracted: float = 0.0
var _next_chain_dist: float = 0.0
var _initial_chain_dist: float = 0.0
var _chains: Array[Node2D] = []
var _hand_particles: GPUParticles2D = null
var _hand_closed_tex: Texture2D
var _clip_material: ShaderMaterial
var _anim_timer: float = 0.0
var _entity_target: Node = null
var _pull_target_entity: bool = false
var _is_pickup: bool = false
var _retract_to_active: bool = false
var _retract_to_start: Vector2
var _retract_to_target: Vector2
var _retract_to_duration: float = 0.0
var _retract_to_elapsed: float = 0.0

#region SETUP

##Called by SpellcastGrappleState immediately after adding this node to the scene tree.
func initialize(
	dir: Vector2,
	speed: float,
	retract_mult: float,
	max_dist: float,
	open_tex: Texture2D,
	closed_tex: Texture2D,
	wide_tex: Texture2D
) -> void:
	_dir = dir.normalized()
	_speed = speed
	_retract_speed = speed * retract_mult
	_max_dist = max_dist
	_hand_closed_tex = closed_tex

	_clip_material = ShaderMaterial.new()
	_clip_material.shader = CLIP_SHADER
	_clip_material.set_shader_parameter("clip_origin", global_position)
	_clip_material.set_shader_parameter("clip_dir", _dir)

	var hand_rot: float = _dir.angle() + PI / 2.0
	_hand.rotation = hand_rot
	_hand_sprite.position = Vector2(0.0, 8.0)
	_hand_sprite.texture = open_tex
	_hand_sprite.frame = randi() % _hand_sprite.hframes

	_hand_collision.position = Vector2(0.0, 8.0)

	var hand_half_h: float = _hand_sprite.get_rect().size.y * 0.5
	var chain_spawner: Node2D = _chain_latch.get_parent() as Node2D
	chain_spawner.position = Vector2(0.0, _hand_sprite.position.y + hand_half_h)
	_chain_latch.position = Vector2.ZERO

	_chain_latch.hframes = 8
	_chain_latch.texture = wide_tex
	_chain_latch.frame = 8 + randi() % 8

	_hand_sprite.material = _clip_material
	_chain_latch.material = _clip_material

	_initial_chain_dist = (-to_local(_chain_latch.global_position)).dot(_dir) + 3.0
	_next_chain_dist = _initial_chain_dist
	set_physics_process(true)
	set_process(true)

	_hand_particles = HAND_PARTICLES_SCENE.instantiate()
	_hand.add_child(_hand_particles)
	_hand_particles.modulate.a = 0.0
	create_tween().tween_property(_hand_particles, "modulate:a", 1.0, PARTICLE_FADE_IN)

#endregion SETUP

#region ANIMATION

func _advance_animations() -> void:
	_hand_sprite.frame = (_hand_sprite.frame + 1) % _hand_sprite.hframes
	_chain_latch.frame = 8 + (_chain_latch.frame - 8 + 1) % _chain_latch.hframes
	for chain in _chains:
		if not is_instance_valid(chain):
			continue
		var tall: Sprite2D = chain.get_node_or_null("TallChainSprite")
		var wide: Sprite2D = chain.get_node_or_null("WideChainSprite")
		if tall:
			tall.frame = (tall.frame + 1) % tall.hframes
		if wide:
			wide.frame = (wide.frame + 1) % wide.hframes

#endregion ANIMATION

#region PHYSICS

func _ready() -> void:
	set_physics_process(false)
	set_process(false)

func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		_advance_animations()
	if _retract_to_active:
		_tick_retract_to(delta)

func _physics_process(delta: float) -> void:
	if _phase == Phase.EXTENDING:
		_tick_extend(delta)
	elif _phase == Phase.RETRACTING:
		_tick_retract(delta)
	else:
		_tick_latch(delta)

func _tick_extend(delta: float) -> void:
	var motion: Vector2 = _dir * _speed * delta
	var collision = _hand.move_and_collide(motion)
	_dist_traveled += motion.length()

	if debug_me_verbose:
		print("[GrappleHand] extending — dist=%.1f  mask=%d  layer=%d" % [_dist_traveled, _hand.collision_mask, _hand.collision_layer])

	_try_spawn_chains()

	if collision != null:
		var forward_dot: float = collision.get_normal().dot(-_dir)
		if forward_dot < 0.5:
			if debug_me_verbose:
				print("[GrappleHand] side collision ignored (forward_dot=%.2f)" % forward_dot)
			var remaining: float = maxf(0.0, motion.length() - collision.get_travel().length())
			_hand.global_position += _dir * remaining
			return

		var collider: Node = collision.get_collider()
		var parent: Node = collider.get_parent() if collider else null
		if debug_me:
			print("[GrappleHand] collision! collider='%s' (%s)  parent='%s' (%s)" % [
				String(collider.name) if collider else "null",
				collider.get_class() if collider else "?",
				String(parent.name) if parent else "null",
				parent.get_class() if parent else "?"
			])
		_hand_sprite.texture = _hand_closed_tex
		set_physics_process(false)
		if parent is Character or parent is DynamicThing:
			if debug_me:
				print("[GrappleHand] -> entity_hit emitted (%s)" % parent.name)
			entity_hit.emit(parent)
		elif parent is InteractableComponent and (parent as InteractableComponent).grapple_effect != InteractableComponent.GrappleEffect.NO_EFFECT:
			if debug_me:
				print("[GrappleHand] -> entity_hit emitted (interactable) (%s)" % parent.name)
			entity_hit.emit(parent)
		else:
			if debug_me:
				print("[GrappleHand] -> wall_hit emitted")
			wall_hit.emit()
		return

	var pickup := _check_pickup_overlap()
	if pickup != null:
		_grab_pickup(pickup)
		return

	if _dist_traveled >= _max_dist:
		if debug_me:
			print("[GrappleHand] max_dist reached (%.1f) — wall_hit emitted" % _dist_traveled)
		set_physics_process(false)
		wall_hit.emit()

func _tick_latch(delta: float) -> void:
	var step: float = _retract_speed * delta
	_hand.global_position -= _dir * step
	_dist_retracted += step
	if is_instance_valid(_entity_target):
		if _is_pickup:
			_entity_target.global_position = _hand.global_position
		else:
			var entity_body = _entity_target.get("body")
			if entity_body:
				entity_body.global_position = _hand.global_position
	_trim_chains()
	if _dist_retracted >= _dist_traveled - ENTITY_PULL_STOP_DIST:
		set_physics_process(false)
		var was_pickup: bool = _is_pickup
		var grabbed_item: Node = _entity_target
		_entity_target = null
		_is_pickup = false
		if was_pickup and is_instance_valid(grabbed_item):
			pickup_hit.emit(grabbed_item as WorldItem)
		else:
			latch_pull_complete.emit()

func _tick_retract(delta: float) -> void:
	var motion: Vector2 = -_dir * _retract_speed * delta
	_hand.move_and_collide(motion)
	_dist_retracted += motion.length()

	_trim_chains()

	if _dist_retracted >= _dist_traveled - ORIGIN_THRESHOLD:
		set_physics_process(false)
		set_process(false)
		retract_complete.emit()

func _check_pickup_overlap() -> WorldItem:
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	params.shape = shape
	params.transform = _hand.global_transform
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1
	for r in space.intersect_shape(params):
		var c = r.get("collider")
		if c is WorldItem and (c as WorldItem)._can_pickup:
			return c as WorldItem
	return null

func _grab_pickup(item: WorldItem) -> void:
	if debug_me:
		print("[GrappleHand] -> pickup grabbed (%s)" % item.name)
	item.set_process(false)
	_hand_sprite.texture = _hand_closed_tex
	set_physics_process(false)
	_entity_target = item
	_is_pickup = true
	_pull_target_entity = true
	pickup_grabbed.emit(item)
	_begin_latch()

#endregion PHYSICS

#region CHAINS

func _try_spawn_chains() -> void:
	while _dist_traveled >= _next_chain_dist:
		_spawn_chain()
		_next_chain_dist += CHAIN_STEP

func _spawn_chain() -> void:
	var chain: Node2D = CHAIN_EXTENSION_SCENE.instantiate()
	add_child(chain)

	chain.position = to_local(_chain_latch.global_position) + _dir * 6.0
	chain.rotation = _dir.angle() + PI / 2.0

	var tall_sprite: Sprite2D = chain.get_node("TallChainSprite")
	var wide_sprite: Sprite2D = chain.get_node("WideChainSprite")

	tall_sprite.frame = randi() % tall_sprite.hframes
	wide_sprite.frame = randi() % wide_sprite.hframes

	tall_sprite.material = _clip_material
	wide_sprite.material = _clip_material

	_chains.append(chain)
	if _chains.size() % 2 == 0:
		var particles: GPUParticles2D = CHAIN_PARTICLES_SCENE.instantiate()
		chain.add_child(particles)
		particles.modulate.a = 0.0
		create_tween().tween_property(particles, "modulate:a", 1.0, PARTICLE_FADE_IN)
	chain_extended.emit()

func _trim_chains() -> void:
	var expected_count: int = maxi(0, floori((_dist_traveled - _dist_retracted - _initial_chain_dist) / CHAIN_STEP) + 1)
	while _chains.size() > expected_count:
		var last: Node2D = _chains.pop_back()
		if is_instance_valid(last):
			_fade_and_free(last)
		chain_retracted.emit()

func _fade_and_free(node: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, PARTICLE_FADE_OUT)
	tween.tween_callback(func(): if is_instance_valid(node): node.queue_free())

#endregion CHAINS

#region PUBLIC API

##Excludes a PhysicsBody2D from hand collision — call immediately after initialize() to prevent self-collision.
func exclude_body(body: PhysicsBody2D) -> void:
	_hand.add_collision_exception_with(body)

##Begins retracting the hand back toward the spawn origin.
func start_retract() -> void:
	if is_instance_valid(_hand_particles):
		create_tween().tween_property(_hand_particles, "modulate:a", 0.0, PARTICLE_FADE_OUT)
	_phase = Phase.RETRACTING
	_dist_retracted = 0.0
	set_physics_process(true)

##Called by SpellcastGrappleState after an entity hit to begin a latch.
##If [param is_pulling_entity] is true, the grapple retracts and drags the entity with it.
##If false, the hand stays fixed and the state handles moving the player; emits latch_pull_complete immediately.
func setup_latch_pull_target(entity: Node, is_pulling_entity: bool) -> void:
	_entity_target = entity
	_pull_target_entity = is_pulling_entity
	_begin_latch()

func _begin_latch() -> void:
	if is_instance_valid(_hand_particles):
		create_tween().tween_property(_hand_particles, "modulate:a", 0.0, PARTICLE_FADE_OUT)
	_phase = Phase.LATCHING
	if _pull_target_entity:
		_dist_retracted = 0.0
		set_physics_process(true)
	else:
		latch_pull_complete.emit()

##Removes chain links that are behind [param world_pos] along the extension axis.
##Call each frame during PULL_PLAYER so links disappear as the player passes over them.
func trim_chains_behind_position(world_pos: Vector2) -> void:
	var player_proj := (world_pos - global_position).dot(_dir)
	while _chains.size() > 0:
		var chain: Node2D = _chains[0]
		if not is_instance_valid(chain):
			_chains.remove_at(0)
			continue
		if (chain.global_position - global_position).dot(_dir) >= player_proj + 12.0:
			break
		_chains.remove_at(0)
		_fade_and_free(chain)
		chain_retracted.emit()

##Fades remaining chains and moves the hand to [param target] via _process, then emits [signal retract_complete].
##Used for PULL_PLAYER arrival so the hand retracts to the player rather than the spawn origin.
func retract_to_position(target: Vector2) -> void:
	if is_instance_valid(_hand_particles):
		create_tween().tween_property(_hand_particles, "modulate:a", 0.0, PARTICLE_FADE_OUT)
	for chain in _chains:
		if is_instance_valid(chain):
			_fade_and_free(chain)
	_chains.clear()
	set_physics_process(false)
	var on_axis: Vector2 = global_position + _dir * (target - global_position).dot(_dir)
	_clip_material.set_shader_parameter("clip_origin", on_axis)
	_retract_to_start = _hand.global_position
	_retract_to_target = on_axis
	_retract_to_duration = maxf(0.15, _hand.global_position.distance_to(on_axis) / _retract_speed)
	_retract_to_elapsed = 0.0
	_retract_to_active = true
	set_process(true)

func _tick_retract_to(delta: float) -> void:
	_retract_to_elapsed += delta
	var t: float = clampf(_retract_to_elapsed / _retract_to_duration, 0.0, 1.0)
	_hand.global_position = _retract_to_start.lerp(_retract_to_target, t)
	_hand.modulate.a = 1.0 - t
	if t >= 1.0:
		_retract_to_active = false
		set_process(false)
		retract_complete.emit()

#endregion PUBLIC API
