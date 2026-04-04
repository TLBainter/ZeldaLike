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

@export_group("Transitions")
##The state to return to after the backstep ends.
@export var idle_state : State

var _backstep_dir : Vector2 = Vector2.ZERO
var _distance_traveled : float = 0.0
var _dodge_speed : float = 100.0
var _original_mask : int = -1

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_physics_process(false)
	super()

func enter():
	super()
	var character = get_character()
	# Blocked when exhausted (no energy), even though backstep itself costs 0.
	if coordinator.is_exhausted():
		if debug_me:
			print(debug_name, ": backstep blocked — exhausted.")
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
	# Lock facing and grant invulnerability.
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	# Freeze action layer — no attacking during backstep.
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
	set_physics_process(true)

func _physics_process(_delta : float):
	# Maintain backstep velocity and apply movement.
	root.body.velocity = _backstep_dir * _dodge_speed
	root.body.move_and_slide()
	_distance_traveled += _delta * _dodge_speed
	# Exit: max distance reached, or any world collision (mask is world-only during backstep).
	var max_dist : float = 0.1 * _dodge_speed
	if _distance_traveled >= max_dist or root.body.get_slide_collision_count() > 0:
		# TODO: Play 'backstep exit' directional animation (e.g. "BackstepExitDown") when animations are created.
		if idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "backstep+complete"))

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
	super()

#endregion FUNCTIONS
