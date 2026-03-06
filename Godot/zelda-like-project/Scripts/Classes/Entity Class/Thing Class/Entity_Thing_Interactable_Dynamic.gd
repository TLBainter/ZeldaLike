##A [b][color=red]DynamicInteractable[/color][/b] is an interactable that can be interacted with,[br]
##in multiple ways, including breaking, damaging, lifting, throwing, etc.
class_name DynamicInteractable
extends Interactable

#region SIGNALS

signal snap_move_completed

#endregion SIGNALS

#region VARIABLES

@export_group("Dynamic Interactable Settings")
##The resource defining this object's capabilities, sounds, weight, and drop table.[br]
##Assign a [b]InteractableObject[/b] resource to configure this interactable.
@export var object_data : InteractableObject
@export_group("Dynamic Interactable Components")
##The physical body of this interactable. Expects a CharacterBody2D with attached sprites, colliders, etc.
@export var body : CharacterBody2D

#=======INTERNAL VARIABLES=======#

var _hold_character = null
var _hold_offset : Vector2 = Vector2.ZERO
var _is_held : bool = false

var _snap_target : Vector2 = Vector2.ZERO
var _snap_active : bool = false
var _snap_speed : float = 80.0

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	super._ready()
	category = "Dynamic"

func _physics_process(delta : float):
	if _is_held and _hold_character and body:
		body.global_position = _hold_character.body.global_position + _hold_offset
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
##Default distance is 8 pixels (half a 'grid' tile).[br]
##Uses move_and_collide to respect collisions.[br]
##Returns [b]true[/b] if the move completed without collision or [b]false[/b] if the move failed.
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
##[b]speed[/b]: Movement speed in pixels per second.[br]
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
##[b]offset[/b]: The offset above the character's body.[br]
##[b]character[/b]: The Character holding this object.
func hold(offset : Vector2, character):
	_hold_character = character
	_hold_offset = offset
	_is_held = true
	if root and root.shadow:
		root.shadow.visible = false
	disable_collision()
	if body and character.body:
		body.global_position = character.body.global_position + offset
	set_physics_process(true)
	if debug_me:
		print(debug_name, " is now being held by ", character, ".")

##Releases this object from being held and places it at the given position.[br]
##[b]restore_collision[/b]: Whether to re-enable collision on release. False for throws (projectile handles it).
func release(position : Vector2, restore_collision : bool = true):
	_is_held = false
	_hold_character = null
	set_physics_process(false)
	if body:
		body.global_position = position
	if restore_collision:
		enable_collision()
	if root and root.shadow:
		root.shadow.visible = true
	if debug_me:
		print(debug_name, " released at ", position)

##Disable all CollisionShape2D nodes on the body and stop Interact monitoring.
func disable_collision():
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.disabled = true
	if interact:
		interact.set_deferred("monitoring", false)
		interact.set_deferred("monitorable", false)

##Enable all CollisionShape2D nodes on the body and resume Interact monitoring.
func enable_collision():
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.disabled = false
	if interact:
		interact.set_deferred("monitoring", true)
		interact.set_deferred("monitorable", true)

##Breaks this object. Plays break animation, sound, drops loot, and queues free.[br]
##Called by ProjectileComponent on impact if breakable.
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
		queue_free()

func _on_break_anim_finished(_anim_name : String):
	#TODO: Spawn drops from drop_table here.
	queue_free()

#endregion FUNCTIONS
