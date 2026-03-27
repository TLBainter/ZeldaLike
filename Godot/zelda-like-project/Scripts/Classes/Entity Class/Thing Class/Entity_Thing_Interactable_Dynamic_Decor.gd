##[b][color=red]DynamicDecor[/color][/b] is an interactable decoration (grass, bushes, pots-on-tables, etc).[br]
##Unlike DynamicInteractable, DynamicDecor [b]persists[/b] after being broken — it switches[br]
##to a 'destroyed' sprite instead of being freed.[br]
##[br]
##When broken:[br]
##1. Plays a break sound.[br]
##2. Switches to the destroyed frame.[br]
##3. Spawns a particle sprite above the player that animates and despawns.[br]
##4. Resolves the drop table and spawns items.[br]
##[br]
##Expected scene structure:[br]
##DynamicDecor (Node2D) — this script[br]
##├── Body (CharacterBody2D or StaticBody2D)[br]
##│   ├── Sprite2D[br]
##│   └── CollisionShape2D[br]
##└── InteractArea (Area2D)[br]
##    └── CollisionShape2D
class_name DynamicDecor
extends Interactable

#region VARIABLES

@export_category("Decor Settings")
##The resource defining this decor's sprites, sounds, and drops.
@export var decor_data : DecorObject

@export_category("Decor Components")
##The sprite displaying this decor.
@export var decor_sprite : Sprite2D
##The body for physics/collision.
@export var body : StaticBody2D

#=======INTERNAL VARIABLES=======#

##Whether this decor has already been broken.
var _is_broken : bool = false
##Cached atlas frames sliced from the strip.
var _frames : Array[AtlasTexture] = []

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	super._ready()
	category = "Decor"
	_slice_frames()
	if decor_sprite:
		decor_sprite.hframes = 1
		decor_sprite.vframes = 1
		decor_sprite.frame = 0
	_randomize_initial_frame()

#region FRAME SLICING

##Slices the atlas strip into individual frame AtlasTextures.
func _slice_frames() -> void:
	_frames.clear()
	if not decor_data or not decor_data.atlas_strip or not decor_data.atlas_strip.atlas:
		return
	var strip = decor_data.atlas_strip
	var base_x : float = strip.region.position.x
	var base_y : float = strip.region.position.y
	var frame_w : int = decor_data.frame_width
	var frame_h : int = decor_data.frame_height
	var total_width : int = int(strip.region.size.x)
	var frame_count : int = int(float(total_width) / float(frame_w))
	for i in range(frame_count):
		var frame = AtlasTexture.new()
		frame.atlas = strip.atlas
		frame.region = Rect2(
			base_x + (i * frame_w),
			base_y,
			frame_w,
			frame_h
		)
		frame.filter_clip = true
		_frames.append(frame)
	if debug_me:
		print(debug_name, ": Sliced ", _frames.size(), " frames from strip.")

##Sets the sprite to a random frame from the initial_frames array.
func _randomize_initial_frame() -> void:
	if not decor_data or decor_data.initial_frames.is_empty() or _frames.is_empty():
		return
	var chosen_index : int = decor_data.initial_frames.pick_random()
	if chosen_index >= 0 and chosen_index < _frames.size():
		if decor_sprite:
			decor_sprite.texture = _frames[chosen_index]
			if debug_me:
				var t = _frames[chosen_index]
				print(debug_name, ": Set frame ", chosen_index, " region=", t.region, " atlas=", t.atlas)
		if debug_me:
			print(debug_name, ": Initialized with frame ", chosen_index)

#endregion FRAME SLICING

#region DAMAGE AND BREAKING

##Takes damage from an external source (attack).[br]
##For decor, any damage immediately breaks it.
func take_damage(amount : int) -> void:
	if _is_broken:
		return
	if not decor_data:
		return
	if not decor_data.breakable_by_attack:
		return
	if debug_me:
		print(debug_name, ": Taking damage: ", amount, ". Breaking.")
	_break()

##Breaks this decor: switches sprite, plays sound, spawns particles and drops.
func _break() -> void:
	if _is_broken:
		return
	_is_broken = true
	#Switch to destroyed frame.
	if decor_data and decor_data.destroyed_frame >= 0 and decor_data.destroyed_frame < _frames.size():
		if decor_sprite:
			decor_sprite.texture = _frames[decor_data.destroyed_frame]
	#Play break sound.
	if decor_data and decor_data.break_sounds and not decor_data.break_sounds.sl.is_empty():
		var clip = decor_data.break_sounds.sl.pick_random()
		if audioManager:
			audioManager.play(clip, "Environment")
	#Spawn particle effect.
	_spawn_particles()
	#Spawn drops.
	_spawn_drops()
	#Disable interaction so it can't be broken again.
	if interact:
		interact.set_deferred("monitoring", false)
		interact.set_deferred("monitorable", false)
	#Disable collision on the body so the player can walk through.
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	if debug_me:
		print(debug_name, ": Broken. Switched to destroyed frame.")

#endregion DAMAGE AND BREAKING

#region PARTICLES

##Spawns a temporary sprite above the break position that plays the particle frames.[br]
##The sprite renders above the player (z_index) and despawns after the animation finishes.
func _spawn_particles() -> void:
	if not decor_data or decor_data.particle_frames.is_empty() or _frames.is_empty():
		return
	#Validate all particle frame indices exist.
	for idx in decor_data.particle_frames:
		if idx < 0 or idx >= _frames.size():
			if debug_me:
				printerr(debug_name, ": Particle frame index ", idx, " out of range!")
			return
	var particle_sprite = Sprite2D.new()
	particle_sprite.texture = _frames[decor_data.particle_frames[0]]
	particle_sprite.z_as_relative = false
	particle_sprite.z_index = 10
	#Position above the decor.
	var spawn_pos = body.global_position if body else global_position
	particle_sprite.global_position = spawn_pos + Vector2(0, -decor_data.frame_height)
	get_tree().current_scene.add_child(particle_sprite)
	#Animate the particle frames using a timer.
	_animate_particle(particle_sprite, 0)
	if debug_me:
		print(debug_name, ": Particle spawned at ", particle_sprite.global_position)

##Advances the particle sprite to the next frame using recursive timer calls.
func _animate_particle(particle_sprite : Sprite2D, frame_index : int) -> void:
	if not is_instance_valid(particle_sprite):
		return
	if frame_index >= decor_data.particle_frames.size():
		#Animation finished — despawn.
		particle_sprite.queue_free()
		if debug_me:
			print(debug_name, ": Particle animation finished. Despawning.")
		return
	var atlas_index = decor_data.particle_frames[frame_index]
	if atlas_index >= 0 and atlas_index < _frames.size():
		particle_sprite.texture = _frames[atlas_index]
	#Schedule next frame.
	get_tree().create_timer(decor_data.particle_frame_duration).timeout.connect(
		_animate_particle.bind(particle_sprite, frame_index + 1)
	)

#endregion PARTICLES

#region DROPS

##Resolves the drop table and spawns WorldItems.
func _spawn_drops() -> void:
	if not decor_data or not decor_data.drop_table:
		return
	var player = _find_player()
	var drops : Array[PickupResource] = decor_data.drop_table.resolve(player)
	if drops.is_empty():
		return
	var spawn_pos = body.global_position if body else global_position
	var space_state = get_world_2d().direct_space_state
	#Calculate scatter direction away from player.
	var base_scatter_dir = Vector2.ZERO
	if player and player.body:
		base_scatter_dir = (spawn_pos - player.body.global_position).normalized()
	for i in range(drops.size()):
		var pickup = drops[i]
		if not pickup:
			continue
		var world_item = _create_world_item()
		world_item.pickup_data = pickup
		get_tree().current_scene.add_child(world_item)
		var scatter_dir : Vector2
		if base_scatter_dir != Vector2.ZERO:
			var spread_angle = randf_range(-0.6, 0.6)
			scatter_dir = base_scatter_dir.rotated(spread_angle)
		else:
			var scatter_angle = (TAU / max(drops.size(), 1)) * i + randf_range(-0.3, 0.3)
			scatter_dir = Vector2(cos(scatter_angle), sin(scatter_angle))
		scatter_dir = _find_clear_direction(space_state, spawn_pos, scatter_dir)
		var spawn_offset = scatter_dir * 12.0
		var item_spawn_pos = spawn_pos + spawn_offset + Vector2(0, -8)
		world_item.spawn(item_spawn_pos, spawn_pos.y + spawn_offset.y, scatter_dir, 60.0)
		if debug_me:
			print(debug_name, ": Spawned drop '", pickup.item.item_name if pickup.item else "unknown", "' at ", item_spawn_pos)

func _find_clear_direction(space_state : PhysicsDirectSpaceState2D, origin : Vector2, preferred_dir : Vector2) -> Vector2:
	var ray_length : float = 24.0
	var attempts : int = 8
	var angle_step : float = TAU / attempts
	for i in range(attempts):
		var test_angle = preferred_dir.angle() + (angle_step * i)
		var test_dir = Vector2(cos(test_angle), sin(test_angle))
		var query = PhysicsRayQueryParameters2D.create(origin, origin + test_dir * ray_length)
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return test_dir
	return preferred_dir

func _create_world_item() -> WorldItem:
	var item = WorldItem.new()
	var item_spr = Sprite2D.new()
	item_spr.name = "ItemSprite"
	item.add_child(item_spr)
	item.item_sprite = item_spr
	var shadow_spr = Sprite2D.new()
	shadow_spr.name = "ShadowSprite"
	shadow_spr.y_sort_enabled = false
	item.add_child(shadow_spr)
	item.shadow_sprite = shadow_spr
	var col_shape = CollisionShape2D.new()
	col_shape.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col_shape.shape = shape
	item.add_child(col_shape)
	item.collision = col_shape
	return item

#endregion DROPS

#endregion FUNCTIONS
