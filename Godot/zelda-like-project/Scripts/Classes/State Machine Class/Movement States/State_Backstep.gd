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

var idle_state : State

var _dodge_executed : bool = false
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

func init_state_refs() -> void:
	idle_state = coordinator.get_state(StateIdling)

func enter():
	super()
	var character = get_character()
	# Blocked when exhausted (no energy), even though backstep itself costs 0.
	if coordinator.is_exhausted():
		if debug_me:
			print(debug_name, ": backstep blocked ; exhausted.")
		if idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "backstep+exhausted"))
		return
	# Backstep direction = opposite of current facing direction.
	if character and character.anim:
		_backstep_dir = -facing_to_vector(character.anim.facing)
	else:
		_backstep_dir = Vector2.UP
	# Read dodge speed from stats resource.
	if root and "stats" in root and root.stats and root.stats.resource:
		_dodge_speed = root.stats.resource.dodge_speed
	_distance_traveled = 0.0
	_max_dist = _clearance_adjusted_dist(_backstep_dir, 0.1 * _dodge_speed)
	# Lock facing and grant invulnerability.
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	# Freeze action layer -- no attacking during backstep.
	coordinator.freeze_action()
	coordinator.update_context("", true)
	# Prime velocity so the very first physics frame moves correctly.
	root.body.velocity = _backstep_dir * _dodge_speed
	# Phase through interactables (Layer 2); keep world geometry (Layer 1).
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 1
	# TEMP: Darken and halve sprite opacity as a backstep visual until animations are ready.
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	# TODO: Play 'backstep enter' directional animation (e.g. "BackstepEnterDown") when animations are created.
	if character and character.audio is CharacterAudioControl:
		character.audio.play_enter_backstep_sound()
	_dodge_executed = true
	set_physics_process(true)

func _physics_process(_delta : float):
	# Maintain backstep velocity and apply movement.
	root.body.velocity = _backstep_dir * _dodge_speed
	root.body.move_and_slide()
	_distance_traveled += _delta * _dodge_speed
	# Exit: max distance reached, or any world collision (mask is world-only during backstep).
	if _distance_traveled >= _max_dist or root.body.get_slide_collision_count() > 0:
		# TODO: Play 'backstep exit' directional animation (e.g. "BackstepExitDown") when animations are created.
		if idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "backstep+complete"))

##Returns the safe backstep distance in physical pixels.[br]
##Checks the full player shape at the endpoint (not just the center point), so it handles
##multiple objects in sequence and objects wider than the gap between them.[br]
##If the shape at the endpoint overlaps any interactable, binary-searches for the front face
##of the first blocking object and returns that distance instead.[br]
##If the path is clear or the player fully clears all objects, returns proposed_max unchanged.
func _clearance_adjusted_dist(direction: Vector2, proposed_max: float) -> float:
	var saved_mask : int = root.body.collision_mask
	root.body.collision_mask = 2  # Interactable Layer only.
	# Quick path: no layer-2 object anywhere in the sweep at all.
	if not root.body.test_move(root.body.global_transform, direction * proposed_max):
		root.body.collision_mask = saved_mask
		return proposed_max
	# Shape-based endpoint check: test the full player collision shape at the endpoint.
	# recovery_as_collision=true causes test_move to report initial overlaps at the from transform.
	var endpoint_xform : Transform2D = root.body.global_transform.translated(direction * proposed_max)
	if not root.body.test_move(endpoint_xform, Vector2.ZERO, null, 0.08, true):
		# Player shape is clear at the endpoint -- passes through all objects in the path.
		root.body.collision_mask = saved_mask
		return proposed_max
	# Shape overlaps at endpoint -- binary-search for the front face of the first blocker.
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
	# TEMP: Restore sprite from backstep visual.
	if root.sprite:
		root.sprite.modulate = Color.WHITE
	# Restore collision mask.
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
	super()

#endregion FUNCTIONS
