##[b][color=red]DynamicThing[/color][/b] is a [b]Thing[/b] that uses a [b]CharacterBody2D[/b] and can be physically manipulated:[br]
##lifted, thrown, pushed, pulled, and broken.[br]
##Assign an [b]InteractableObject[/b] resource to configure capabilities.[br]
##Add an [b]InteractableComponent[/b] child to make it interactable by the player.
class_name DynamicThing
extends Thing

#region SIGNALS

signal snap_move_completed

#endregion

#region VARIABLES

@export_group("Dynamic Thing Settings")
##Resource defining this object's capabilities, sounds, weight, and drop table.
@export var object_data : InteractableObject
@export_group("Dynamic Thing Components")
##The physical body. Expects a CharacterBody2D with attached sprites and colliders.
@export var body : CharacterBody2D

#=======INTERNAL VARIABLES=======#

var _hold_character = null
var _hold_offset : Vector2 = Vector2.ZERO
var _is_held : bool = false

var _snap_target : Vector2 = Vector2.ZERO
var _snap_active : bool = false
var _snap_speed : float = 80.0

var _last_damage_source_pos : Vector2 = Vector2.ZERO
var _damaged_by_attack : bool = false

#endregion

#region FUNCTIONS

func _ready():
	super._ready()
	subtype = "Dynamic"

func _physics_process(delta : float):
	if _is_held and _hold_character and body:
		body.global_position = _hold_character.body.global_position + Vector2(0, 1)
	elif _snap_active and body:
		var distance_left = body.global_position.distance_to(_snap_target)
		var move_amount = _snap_speed * delta
		if move_amount >= distance_left:
			body.global_position = _snap_target
			_snap_active = false
			set_physics_process(false)
			snap_move_completed.emit()
		else:
			var direction = (_snap_target - body.global_position).normalized()
			body.global_position += direction * move_amount
	else:
		set_physics_process(false)

##Attempts to move this object [b]distance[/b] pixels in the given [b]direction[/b] instantly.[br]
##Returns [b]true[/b] if the move completed without collision, [b]false[/b] if blocked.
func snap_move(direction : Vector2, distance : float = 8.0) -> bool:
	if not body:
		if debug_me:
			printerr(debug_name, " could not be moved because it does not have an assigned body!")
		return false
	var collision = body.move_and_collide(direction * distance, true)
	if collision:
		if debug_me:
			printerr(debug_name, " could not be moved because it collided with something!")
		return false
	body.move_and_collide(direction * distance)
	return true

##Smoothly moves this object to a position [b]distance[/b] pixels in the given [b]direction[/b].[br]
##Emits [b]snap_move_completed[/b] when finished.[br]
##Returns [b]true[/b] if the move started, [b]false[/b] if blocked by collision.
func smooth_snap_move(direction : Vector2, distance : float = 8.0, speed : float = 80.0, skip_test : bool = false) -> bool:
	if not body:
		return false
	if not skip_test:
		var collision = body.move_and_collide(direction * distance, true)
		if collision:
			return false
	_snap_target = body.global_position + (direction * distance)
	_snap_speed = speed
	_snap_active = true
	set_physics_process(true)
	return true

##Picks up this object: disables collision and begins following the hold position.[br]
##[b]offset[/b]: Offset above the character's body.[br]
##[b]character[/b]: The Character holding this object.
func hold(offset : Vector2, character):
	_hold_character = character
	_hold_offset = offset
	_is_held = true
	if shadow:
		shadow.visible = false
	disable_collision()
	if body and character.body:
		body.global_position = character.body.global_position + Vector2(0, 1)
	if sprite:
		sprite.position = offset
	set_physics_process(true)
	if debug_me:
		print(debug_name, " is now being held by ", character, ".")

##Releases this object and places it at the given position.[br]
##[b]restore_collision[/b]: Whether to re-enable collision on release.
func release(drop_position : Vector2, restore_collision : bool = true):
	_is_held = false
	_hold_character = null
	set_physics_process(false)
	if body:
		body.global_position = drop_position
		body.z_index = 0
	if restore_collision:
		if sprite:
			sprite.position = Vector2.ZERO
		enable_collision()
		if shadow:
			shadow.visible = true

##Disable all CollisionShape2D nodes on the body and stop interaction monitoring.
func disable_collision():
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.disabled = true
	if interactable:
		interactable.set_active(false)

##Enable all CollisionShape2D nodes on the body and resume interaction monitoring.
func enable_collision():
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.disabled = false
	if interactable:
		interactable.set_active(true)

#region BREAK

##Breaks this object. Plays break animation, sound, drops loot, and queues free.
func break_me():
	if debug_me:
		print(debug_name, " is breaking!")
	if object_data and object_data.material and object_data.material.break_sounds:
		var clip = object_data.material.break_sounds.sl.pick_random()
		if audioManager:
			audioManager.play(clip, "Environment")
	if anim and anim.has_animation("break"):
		anim.play("break")
		if not anim.animation_finished.is_connected(_on_break_anim_finished):
			anim.animation_finished.connect(_on_break_anim_finished, CONNECT_ONE_SHOT)
	else:
		if interactable:
			interactable.set_active(false)
		_spawn_drops(_find_player())
		queue_free()

func _spawn_drops(player = null):
	if not object_data or not object_data.drop_table:
		return
	var drops : Array[PickupResource] = object_data.drop_table.resolve(player)
	if drops.is_empty():
		return
	var spawn_pos = body.global_position if body else global_position
	var space_state = get_world_2d().direct_space_state
	var base_scatter_dir = Vector2.ZERO
	if _damaged_by_attack and _last_damage_source_pos != Vector2.ZERO:
		base_scatter_dir = (spawn_pos - _last_damage_source_pos).normalized()
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
		var impulse = 60.0 if _damaged_by_attack else 0.0
		world_item.spawn(item_spawn_pos, spawn_pos.y + spawn_offset.y, scatter_dir, impulse)
	_damaged_by_attack = false
	_last_damage_source_pos = Vector2.ZERO

func _on_break_anim_finished(_anim_name : String):
	if interactable:
		interactable.set_active(false)
	_spawn_drops(_find_player())
	queue_free()

#endregion BREAK

#region DAMAGE

##Takes damage from an external source (attack, projectile, etc).[br]
##Reduces durability. When durability reaches 0, breaks the object.
func take_damage(amount : int) -> void:
	if not object_data:
		if debug_me:
			print(debug_name, ": take_damage called but no object_data!")
		return
	_damaged_by_attack = true
	var player = _find_player()
	if player and player.body:
		_last_damage_source_pos = player.body.global_position
	object_data.durability -= amount
	if debug_me:
		print(debug_name, ": Took ", amount, " damage. Durability: ", object_data.durability)
	if object_data.material and object_data.material.impact_sounds:
		if not object_data.material.impact_sounds.sl.is_empty():
			var clip = object_data.material.impact_sounds.sl.pick_random()
			if audioManager:
				audioManager.play(clip, "Environment")
	if object_data.durability <= 0:
		if debug_me:
			print(debug_name, ": Durability depleted! Breaking.")
		break_me()

#endregion DAMAGE

#endregion FUNCTIONS
