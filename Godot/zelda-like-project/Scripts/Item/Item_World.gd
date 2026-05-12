##[b][color=red]WorldItem[/color][/b] is the scene script for items that exist in the game world.[br]
##Handles spawn animation (Float/Drop/Bounce gravity), bob animation, shadow sync,[br]
##sparkle animation, auto-pickup on player contact, item application, and first-get dialogue.[br]
##[br]
##Sprites are sliced at runtime from the item's atlas strip (5 frames at 16x16).[br]
##Frame 0 = static. Frames 1-4 = animation.[br]
##[br]
##[b]Gravity Types[/b]:[br]
##- [b]Float[/b]: Slow drift downward with sinusoidal horizontal sway. Shadow appears on landing.[br]
##- [b]Drop[/b]: Slight arc away from spawn point, no bounce. Shadow appears on landing.[br]
##- [b]Bounce[/b]: Arcs away from spawn, bounces 1-5 times (each shorter). Shadow appears on landing.[br]
class_name WorldItem
extends Area2D

#region SIGNALS

##Emitted when this item is picked up by the player.
signal item_picked_up(pickup : PickupResource)

#endregion SIGNALS

#region CONSTANTS

const FRAME_SIZE : int = 16
const FRAME_COUNT : int = 5
const ANIM_FRAME_COUNT : int = 4

#endregion CONSTANTS

#region VARIABLES

@export_category("World Item Components")
##The sprite displaying this item. Bobs up and down when idle.
@export var item_sprite : Sprite2D
##The sprite displaying the shadow beneath the item. Syncs animation with the bob.
@export var shadow_sprite : Sprite2D
##The collision shape for player detection.
@export var collision : CollisionShape2D

@export_category("World Item Settings")
##The pickup resource defining this item's data. Set at spawn time or in the inspector.
@export var pickup_data : PickupResource

@export_category("Bob Settings")
##How many pixels the item bobs up from its resting position.
@export var bob_height : float = 3.0
##How fast the item bobs (cycles per second).
@export var bob_speed : float = 1.5

@export_category("Sparkle Settings")
##Minimum seconds between sparkle animations.
@export var sparkle_min_interval : float = 2.0
##Maximum seconds between sparkle animations.
@export var sparkle_max_interval : float = 5.0
##How fast sparkle frames advance (seconds per frame).
@export var sparkle_frame_duration : float = 0.08

@export_category("Spawn Settings")
@export_group("Float")
##How fast the item drifts down when using Float gravity.
@export var float_fall_speed : float = 30.0
##How far the item sways horizontally during Float.
@export var float_sway_amount : float = 8.0
##How fast the item sways during Float (cycles per second).
@export var float_sway_speed : float = 2.0
@export_group("Drop")
##How fast the item falls when using Drop gravity.
@export var drop_fall_speed : float = 120.0
##The initial upward velocity for the Drop arc.
@export var drop_arc_strength : float = 40.0
@export_group("Bounce")
##How fast the item moves during Bounce gravity.
@export var bounce_speed : float = 100.0
##The initial upward velocity for the first Bounce.
@export var bounce_initial_height : float = 24.0
##How much each subsequent bounce is reduced (multiplier, 0-1).
@export var bounce_decay : float = 0.5

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v


#region Cached Frame Textures
##Sliced frames from the item strip. Index 0 = static, 1-4 = animation.
var _item_frames : Array[AtlasTexture] = []
##Sliced frames from the shadow strip. Index 0 = static, 1-4 = animation.
var _shadow_frames : Array[AtlasTexture] = []
#endregion Cached Frame Textures

#region Spawn State
##Whether the item has finished its spawn animation and can be picked up.
var _can_pickup : bool = false
##The target Y position for gravity (ground level).
var _target_y : float = 0.0
##Spawn scatter direction (horizontal).
var _scatter_dir : Vector2 = Vector2.ZERO
##Whether we are still in the spawn phase.
var _is_spawning : bool = false
##The starting X position for Float sway calculations.
var _float_start_x : float = 0.0
##Accumulated time for Float sway.
var _float_time : float = 0.0
##Current vertical velocity for Drop/Bounce arc.
var _vertical_velocity : float = 0.0
##Current horizontal velocity for Drop/Bounce.
var _horizontal_velocity : float = 0.0
##How many bounces remain (Bounce only).
var _bounces_remaining : int = 0
##Current bounce height (decreases each bounce).
var _current_bounce_height : float = 0.0
##Initial horizontal impulse applied on spawn (decays over time).
var _impulse_velocity : Vector2 = Vector2.ZERO
##How fast the impulse decays.
var _impulse_decay : float = 200.0
#endregion Spawn State

#region Bob State
##Accumulated time for the bob sine wave.
var _bob_time : float = 0.0
##The resting Y offset of the item sprite (set after spawn completes).
var _sprite_rest_y : float = 0.0
#endregion Bob State

#region Sparkle State
##Timer until the next sparkle plays.
var _sparkle_timer : float = 0.0
##Whether a sparkle animation is currently playing.
var _sparkle_playing : bool = false
##Current sparkle frame index (0-3, maps to strip frames 1-4).
var _sparkle_frame : int = 0
##Time spent on the current sparkle frame.
var _sparkle_frame_time : float = 0.0
#endregion Sparkle State

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_process(false)
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	_slice_strips()
	_apply_static_sprites()
	if shadow_sprite:
		shadow_sprite.visible = false

#region STRIP SLICING

##Slices the item and shadow atlas strips into individual frame AtlasTextures.
func _slice_strips() -> void:
	_item_frames.clear()
	_shadow_frames.clear()
	if not pickup_data or not pickup_data.item:
		return
	var item = pickup_data.item
	if item.item_strip:
		_item_frames = _slice_strip(item.item_strip)
	if item.shadow_strip:
		_shadow_frames = _slice_strip(item.shadow_strip)

func _slice_strip(strip : AtlasTexture) -> Array[AtlasTexture]:
	var frames : Array[AtlasTexture] = []
	if not strip or not strip.atlas:
		return frames
	var base_x : float = strip.region.position.x
	var base_y : float = strip.region.position.y
	for i in range(FRAME_COUNT):
		var frame = AtlasTexture.new()
		frame.atlas = strip.atlas
		frame.region = Rect2(
			base_x + (i * FRAME_SIZE),
			base_y,
			FRAME_SIZE,
			FRAME_SIZE
		)
		frames.append(frame)
	return frames

##Sets the item and shadow sprites to their static (frame 0) textures.
func _apply_static_sprites() -> void:
	if item_sprite and not _item_frames.is_empty():
		item_sprite.texture = _item_frames[0]
		item_sprite.scale = Vector2(0.5, 0.5)
	if shadow_sprite and not _shadow_frames.is_empty():
		shadow_sprite.texture = _shadow_frames[0]
		shadow_sprite.y_sort_enabled = false
		shadow_sprite.scale = Vector2(0.5, 0.5)

#endregion STRIP SLICING

#region SPAWNING

##Spawns the item at the given position with a scatter direction.[br]
##[b]spawn_pos[/b]: Where the item appears.[br]
##[b]ground_y[/b]: The Y position to fall to (ground level).[br]
##[b]scatter_direction[/b]: Direction to scatter horizontally.
func spawn(spawn_pos : Vector2, ground_y : float = -1.0, scatter_direction : Vector2 = Vector2.ZERO, impulse_speed : float = 0.0) -> void:
	global_position = spawn_pos
	_target_y = ground_y if ground_y >= 0.0 else spawn_pos.y
	_scatter_dir = scatter_direction.normalized()
	_can_pickup = false
	_is_spawning = true
	if collision:
		collision.set_deferred("disabled", true)
	if shadow_sprite:
		shadow_sprite.visible = false
	if pickup_data:
		match pickup_data.gravity_type:
			"Float":
				_float_start_x = spawn_pos.x
				_float_time = randf() * TAU
			"Drop":
				_vertical_velocity = -drop_arc_strength
				_horizontal_velocity = _scatter_dir.x * drop_fall_speed * 0.3
			"Fall":
				_vertical_velocity = -drop_arc_strength * 0.4
			"Bounce":
				_bounces_remaining = randi_range(1, 5)
				_current_bounce_height = bounce_initial_height
				_vertical_velocity = -_current_bounce_height
				_horizontal_velocity = _scatter_dir.x * bounce_speed * 0.4
	if impulse_speed > 0.0 and scatter_direction != Vector2.ZERO:
		_impulse_velocity = scatter_direction.normalized() * impulse_speed
	if pickup_data and pickup_data.gravity_type == "Float":
		_impulse_velocity = Vector2.ZERO
	var nearest_ground := _find_nearest_ground_position(spawn_pos)
	if nearest_ground != spawn_pos:
		_scatter_dir = (nearest_ground - spawn_pos).normalized()
		if pickup_data and pickup_data.gravity_type == "Float":
			_float_start_x = nearest_ground.x
			_target_y = nearest_ground.y
		else:
			_impulse_velocity = _scatter_dir * max(impulse_speed, 80.0)
	set_physics_process(true)
	if debug_me:
		print(debug_name, ": Spawned at ", spawn_pos, " target_y=", _target_y, " gravity=", pickup_data.gravity_type if pickup_data else "none")

func _physics_process(delta : float) -> void:
	if not _is_spawning:
		set_physics_process(false)
		return
	if not pickup_data:
		_finish_spawn()
		return
	if _impulse_velocity.length() > 0.5:
		global_position += _impulse_velocity * delta
		_impulse_velocity = _impulse_velocity.move_toward(Vector2.ZERO, _impulse_decay * delta)
	match pickup_data.gravity_type:
		"Float":
			_process_float(delta)
		"Drop":
			_process_drop(delta)
		"Fall":
			_process_fall(delta)
		"Bounce":
			_process_bounce(delta)
		_:
			_finish_spawn()

##Float gravity: slow drift down with horizontal sway.
func _process_float(delta : float) -> void:
	_float_time += delta * float_sway_speed * TAU
	global_position.x = _float_start_x + sin(_float_time) * float_sway_amount
	global_position.y = move_toward(global_position.y, _target_y, float_fall_speed * delta)
	if global_position.y >= _target_y:
		_finish_spawn()

##Drop gravity: slight arc, no bounce.
func _process_drop(delta : float) -> void:
	_vertical_velocity += drop_fall_speed * 2.0 * delta
	global_position.y += _vertical_velocity * delta
	global_position.x += _horizontal_velocity * delta
	_horizontal_velocity = move_toward(_horizontal_velocity, 0.0, drop_fall_speed * delta)
	if global_position.y >= _target_y:
		global_position.y = _target_y
		_finish_spawn()

##Drop heavily; has a minor, negligible arc.
func _process_fall(delta : float) -> void:
	_vertical_velocity += drop_fall_speed * 1.5 * delta
	global_position.y += _vertical_velocity * delta
	if global_position.y >= _target_y:
		global_position.y = _target_y
		_finish_spawn()

##Bounce gravity: arcs away, bounces multiple times with decay.
func _process_bounce(delta : float) -> void:
	_vertical_velocity += bounce_speed * 2.0 * delta
	global_position.y += _vertical_velocity * delta
	global_position.x += _horizontal_velocity * delta
	_horizontal_velocity = move_toward(_horizontal_velocity, 0.0, bounce_speed * 0.5 * delta)
	if global_position.y >= _target_y:
		global_position.y = _target_y
		if _bounces_remaining > 0:
			_bounces_remaining -= 1
			_current_bounce_height *= bounce_decay
			_vertical_velocity = -_current_bounce_height
			if debug_me:
				print(debug_name, ": Bounce! Remaining: ", _bounces_remaining, " height: ", _current_bounce_height)
		else:
			_finish_spawn()

func _push_out_of_walls() -> void:
	if not collision or not collision.shape:
		return
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = collision.shape
	params.collision_mask = (1 << 3) | (1 << 4) | (1 << 5)
	params.transform = global_transform
	if space.collide_shape(params).is_empty():
		return
	var dirs := [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP,
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]
	for dir in dirs:
		params.transform = Transform2D(0.0, global_position + dir * 8.0)
		if space.collide_shape(params).is_empty():
			global_position += dir * 8.0
			return

##BFS outward from [param world_pos] to find the nearest GroundTilemap cell center.
##Returns [param world_pos] unchanged if already on ground, no tilemap exists, or none found within 15 tiles.
func _find_nearest_ground_position(world_pos : Vector2) -> Vector2:
	var ground_nodes := get_tree().current_scene.find_children("*", "GroundTilemap")
	if ground_nodes.is_empty():
		return world_pos
	var ground := ground_nodes.front() as GroundTilemap
	var start_tile := ground.local_to_map(ground.to_local(world_pos))
	if ground.get_cell_source_id(start_tile) != -1:
		return world_pos
	var visited : Dictionary = { start_tile: true }
	var queue : Array[Vector2i] = [start_tile]
	var searched := 0
	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	while not queue.is_empty() and searched < 225:
		var cur : Vector2i = queue.pop_front()
		searched += 1
		if ground.get_cell_source_id(cur) != -1:
			return ground.to_global(ground.map_to_local(cur))
		for d in dirs:
			var nb : Vector2i = cur + d
			if not visited.has(nb):
				visited[nb] = true
				queue.append(nb)
	return world_pos

##Called when the spawn animation is complete.
func _finish_spawn() -> void:
	_is_spawning = false
	set_physics_process(false)
	global_position.y = _target_y
	_push_out_of_walls()
	_can_pickup = true
	if collision:
		collision.set_deferred("disabled", false)
	if shadow_sprite:
		shadow_sprite.visible = true
	if item_sprite:
		_sprite_rest_y = item_sprite.position.y
	_bob_time = 0.0
	_sparkle_timer = randf_range(sparkle_min_interval, sparkle_max_interval)
	set_process(true)
	if debug_me:
		print(debug_name, ": Spawn complete. Idle started.")

#endregion SPAWNING

#region IDLE BEHAVIOR (BOB + SPARKLE + SHADOW)

func _process(delta : float) -> void:
	_update_bob(delta)
	_update_shadow()
	_update_sparkle(delta)

func _update_bob(delta : float) -> void:
	if not item_sprite:
		return
	_bob_time += delta
	var bob_offset : float = -abs(sin(_bob_time * bob_speed * PI)) * bob_height
	item_sprite.position.y = _sprite_rest_y + bob_offset

func _update_shadow() -> void:
	if not shadow_sprite or _shadow_frames.size() < FRAME_COUNT:
		return
	var bob_offset : float = 0.0
	if item_sprite:
		bob_offset = abs(item_sprite.position.y - _sprite_rest_y)
	var progress : float = clampf(bob_offset / max(bob_height, 0.01), 0.0, 1.0)
	var frame_index : int = clampi(int(progress * ANIM_FRAME_COUNT), 0, ANIM_FRAME_COUNT - 1) + 1
	shadow_sprite.texture = _shadow_frames[frame_index]

##Manages the sparkle animation timer and playback.
func _update_sparkle(delta : float) -> void:
	if not item_sprite or _item_frames.size() < FRAME_COUNT:
		return
	if _sparkle_playing:
		_sparkle_frame_time += delta
		if _sparkle_frame_time >= sparkle_frame_duration:
			_sparkle_frame_time = 0.0
			_sparkle_frame += 1
			if _sparkle_frame >= ANIM_FRAME_COUNT:
				_sparkle_playing = false
				_sparkle_frame = 0
				item_sprite.texture = _item_frames[0]
				_sparkle_timer = randf_range(sparkle_min_interval, sparkle_max_interval)
			else:
				item_sprite.texture = _item_frames[_sparkle_frame + 1]
	else:
		_sparkle_timer -= delta
		if _sparkle_timer <= 0.0:
			_sparkle_playing = true
			_sparkle_frame = 0
			_sparkle_frame_time = 0.0
			if not _item_frames.is_empty():
				item_sprite.texture = _item_frames[1]

#endregion IDLE BEHAVIOR

#region PICKUP

##Called when a body enters the pickup area.
func _on_body_entered(body : Node) -> void:
	if not _can_pickup:
		return
	if body is PlayerBody:
		_pickup(body)

##Called externally (e.g. from the attack hit query) to attempt pickup.
func try_pickup(player_body : PlayerBody) -> void:
	if not _can_pickup:
		return
	_pickup(player_body)

##Handles the pickup: applies item effects, plays sound, shows dialogue, and cleans up.
func _pickup(player_body : PlayerBody) -> void:
	_can_pickup = false
	if not pickup_data or not pickup_data.item:
		queue_free()
		return
	var item = pickup_data.item
	var player = player_body.root
	if not player:
		queue_free()
		return
	_apply_effects(item, player)
	var _item_key : String = item.resource_path
	var _is_first_pickup : bool = not _first_tone_items.has(_item_key)
	if _is_first_pickup:
		_first_tone_items[_item_key] = true
		item_picked_up.emit(pickup_data)
		_start_item_get_sequence(item, player)
		return
	elif item.use_sounds and not item.use_sounds.sounds.is_empty():
		if audioManager:
			audioManager.play(item.use_sounds.sounds.pick_random(), "UI")
	var should_show_dialogue : bool = false
	if item.always_show_dialogue and item.first_get_dialogue_ref != "":
		should_show_dialogue = true
	elif item.first_get_dialogue_ref != "":
		var item_id = item.first_get_dialogue_ref
		if not _has_been_collected(item_id):
			_mark_collected(item_id)
			should_show_dialogue = true
	if should_show_dialogue:
		if not _item_frames.is_empty():
			player.show_item_get(_item_frames[0])
		if player.player_ux and player.player_ux.dialogue_controller:
			player.player_ux.dialogue_controller.dialogue_closed.connect(
				player.dismiss_item_get, CONNECT_ONE_SHOT
			)
		_show_first_get_dialogue(item, player)
	item_picked_up.emit(pickup_data)
	if debug_me:
		print(debug_name, ": Picked up ", item.first_get_dialogue_ref)
	queue_free()

##Applies the item's effects to the player.
func _apply_effects(item : ItemResource, player) -> void:
	if item.recover_health > 0 and player.health:
		player.health.healed(item.recover_health)
		if debug_me:
			print(debug_name, ": Restored ", item.recover_health, " health.")
	if item.recover_energy > 0 and player.energy:
		player.energy.restore(item.recover_energy)
		if debug_me:
			print(debug_name, ": Restored ", item.recover_energy, " energy.")
	if item.recover_magic > 0 and player.magic:
		player.magic.restore(item.recover_magic)
		if debug_me:
			print(debug_name, ": Restored ", item.recover_magic, " magic.")
	if item.grant_notes > 0 and player.currency:
		player.currency.add(item.grant_notes)
		if debug_me:
			print(debug_name, ": Granted ", item.grant_notes, " notes.")

##Shows the first-get dialogue for this item.
func _show_first_get_dialogue(item : ItemResource, player) -> void:
	if item.first_get_dialogue_ref != "" and player.player_ux and player.player_ux.dialogue_controller:
		var data = dialogueDB.get_dialogue_data(item.first_get_dialogue_ref)
		if not data.is_empty():
			player.freeze_input(true)
			player.player_ux.dialogue_controller.start_dialogue(data, player.input)
	if debug_me:
		print(debug_name, ": Showing first-get dialogue for ", item.first_get_dialogue_ref)

func _start_item_get_sequence(item : ItemResource, player) -> void:
	if item_sprite:
		item_sprite.visible = false
	if shadow_sprite:
		shadow_sprite.visible = false
	player.freeze_input(true)
	if player.anim and player.anim is CharacterAnimator:
		player.anim.can_update_facing = false
		player.anim.force_face(Vector2.DOWN)
		player.anim.play_directional_anim(AnimationName.ITEM_GET, true)
		player.anim.animation_finished.connect(_on_world_item_get_done.bind(item, player), CONNECT_ONE_SHOT)
	else:
		_on_world_item_get_done("", item, player)

func _on_world_item_get_done(_anim_name : String, item : ItemResource, player) -> void:
	if musicManager:
		musicManager.play_item_tone(musicManager.first_item_get_tone)
	if not _item_frames.is_empty():
		player.show_item_get(_item_frames[0])
	var ref := item.first_get_dialogue_ref
	if ref != "" and player.player_ux and player.player_ux.dialogue_controller:
		if item.always_show_dialogue or not _has_been_collected(ref):
			if not item.always_show_dialogue:
				_mark_collected(ref)
			var data = dialogueDB.get_dialogue_data(ref)
			if not data.is_empty():
				var dc = player.player_ux.dialogue_controller
				dc.start_dialogue(data, player.input)
				dc.dialogue_closed.connect(_on_world_item_dialogue_closed.bind(player), CONNECT_ONE_SHOT)
				return
	player.dismiss_item_get()
	_finish_world_item_get(player)

func _on_world_item_dialogue_closed(player) -> void:
	player.dismiss_item_get()
	_finish_world_item_get(player)

func _finish_world_item_get(player) -> void:
	if player.anim and player.anim is CharacterAnimator:
		player.anim.can_update_facing = true
	player.freeze_input(false)
	if debug_me:
		print(debug_name, ": First-get sequence complete.")
	queue_free()

#endregion PICKUP

#region COLLECTION TRACKING
static var _collected_items : Dictionary = {}
static var _first_tone_items : Dictionary = {}

static func _has_been_collected(item_id : String) -> bool:
	return _collected_items.has(item_id)

static func _mark_collected(item_id : String) -> void:
	_collected_items[item_id] = true
#endregion COLLECTION TRACKING

#endregion FUNCTIONS
