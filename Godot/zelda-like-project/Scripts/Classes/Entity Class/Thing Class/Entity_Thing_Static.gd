##[b][color=red]StaticThing[/color][/b] is a [b]Thing[/b] that does not move.[br]
##[br]
##Behavior is data-driven:[br]
##- Assign a [b]DecorObject[/b] resource to enable persistent breakable decor (grass, bushes, pots-on-tables).[br]
##- Add an [b]InteractableComponent[/b] child to make it interactable by the player.[br]
##- Without a [b]DecorObject[/b], this is a plain static entity (decoration, light source, signal receiver).
class_name StaticThing
extends Thing

#region VARIABLES

@export_group("Static Thing Settings")
##Optional: assign to enable persistent breakable decor behavior.[br]
##Controls sprite frames, break sounds, particles, and drops.
@export var decor_data : DecorObject
##Whether interacting with this object adds it to the player's inventory.
@export var get_on_interact : bool = false
##Signal to send to [b]signal_target[/b] nodes when interacted with.
@export var signal_to_send : String
##The nodes to receive [b]signal_to_send[/b].
@export var signal_target : Array[Node]

@export_group("Static Thing Components")
##The physics body (StaticBody2D or similar).
@export var body : Node2D
##The sprite to display for decor behavior. Required if using [b]DecorObject[/b].
@export var decor_sprite : Sprite2D

#=======INTERNAL VARIABLES (Decor)=======#

##Whether this decor has already been broken.
var _is_broken : bool = false
##Cached atlas frames sliced from the strip.
var _frames : Array[AtlasTexture] = []

#endregion

#region FUNCTIONS

func _ready():
	super._ready()
	subtype = "Static"
	if decor_data:
		_slice_frames()
		if decor_sprite:
			decor_sprite.hframes = 1
			decor_sprite.vframes = 1
			decor_sprite.frame = 0
		_randomize_initial_frame()

#region FRAME SLICING

##Slices the atlas strip into individual frame AtlasTextures.[br]
##Only runs when [b]decor_data[/b] is assigned.
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

##Sets the sprite to a random frame from the [b]initial_frames[/b] array.
func _randomize_initial_frame() -> void:
	if not decor_data or decor_data.initial_frames.is_empty() or _frames.is_empty():
		return
	var chosen_index : int = decor_data.initial_frames.pick_random()
	if chosen_index >= 0 and chosen_index < _frames.size():
		if decor_sprite:
			decor_sprite.texture = _frames[chosen_index]
	if debug_me:
		print(debug_name, ": Initialized with frame ", chosen_index)

#endregion FRAME SLICING

#region DAMAGE AND BREAKING

##Takes damage from an external source.[br]
##Requires [b]decor_data[/b]; any damage immediately breaks decor.
func take_damage(_amount : int) -> void:
	if _is_broken or not decor_data:
		return
	if not decor_data.breakable_by_attack:
		return
	if debug_me:
		print(debug_name, ": Taking damage. Breaking.")
	_break()

##Breaks this decor: switches sprite, plays sound, spawns particles and drops.[br]
##The object [b]persists[/b] -- it switches to the destroyed frame rather than being freed.
func _break() -> void:
	if _is_broken:
		return
	_is_broken = true
	if decor_data and decor_data.destroyed_frame >= 0 and decor_data.destroyed_frame < _frames.size():
		if decor_sprite:
			decor_sprite.texture = _frames[decor_data.destroyed_frame]
	if decor_data and decor_data.break_sounds and not decor_data.break_sounds.sl.is_empty():
		var clip = decor_data.break_sounds.sl.pick_random()
		if audioManager:
			audioManager.play(clip, "Environment")
	_spawn_particles()
	_spawn_drops()
	if interactable:
		interactable.set_active(false)
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
	if debug_me:
		print(debug_name, ": Broken. Switched to destroyed frame.")

#endregion DAMAGE AND BREAKING

#region PARTICLES

##Spawns a temporary sprite above the break position that plays the particle frames.
func _spawn_particles() -> void:
	if not decor_data or decor_data.particle_frames.is_empty() or _frames.is_empty():
		return
	for idx in decor_data.particle_frames:
		if idx < 0 or idx >= _frames.size():
			if debug_me:
				printerr(debug_name, ": Particle frame index ", idx, " out of range!")
			return
	var particle_sprite = Sprite2D.new()
	particle_sprite.texture = _frames[decor_data.particle_frames[0]]
	particle_sprite.z_as_relative = false
	particle_sprite.z_index = 10
	var spawn_pos = body.global_position if body else global_position
	particle_sprite.global_position = spawn_pos + Vector2(0, -decor_data.frame_height)
	get_tree().current_scene.add_child(particle_sprite)
	_animate_particle(particle_sprite, 0)
	if debug_me:
		print(debug_name, ": Particle spawned at ", particle_sprite.global_position)

func _animate_particle(particle_sprite : Sprite2D, frame_index : int) -> void:
	if not is_instance_valid(particle_sprite):
		return
	if frame_index >= decor_data.particle_frames.size():
		particle_sprite.queue_free()
		return
	var atlas_index = decor_data.particle_frames[frame_index]
	if atlas_index >= 0 and atlas_index < _frames.size():
		particle_sprite.texture = _frames[atlas_index]
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
			print(debug_name, ": Spawned drop '", pickup.item.first_get_dialogue_ref if pickup.item else "unknown", "' at ", item_spawn_pos)

#endregion DROPS

#endregion FUNCTIONS
