##[b][color=red]StateDash[/color][/b] is the dash movement state.[br]
##Entered from StateRun via actionButton4 when the player has >= 1 energy.[br]
##The player dashes in their current movement direction at dodge_speed.[br]
##Dash distance = 2 * dodge_speed (pixels). Invulnerable while dashing.[br]
##Interrupted early by wall/surface collision.[br]
##[br]
##[b]LAYER[/b]: Movement
class_name StateDash
extends State

#region VARIABLES

@export_group("Transitions")
##The state to return to after the dash ends.
@export var idle_state : State

##Energy consumed per dash.
const DASH_COST : int = 1

var _dash_dir : Vector2 = Vector2.ZERO
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
	# Check and consume energy; abort back to idle if insufficient.
	if not coordinator.consume_energy(DASH_COST):
		if debug_me:
			print(debug_name, ": not enough energy to dash.")
		if idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "dash+insufficient_energy"))
		return
	# Determine dash direction from current velocity; fall back to facing.
	if root.body.velocity.length() > 10.0:
		_dash_dir = root.body.velocity.normalized()
	elif character and character.anim:
		_dash_dir = facing_to_vector(character.anim.facing)
	else:
		_dash_dir = Vector2.DOWN
	# Read dodge speed from stats resource.
	if root and "stats" in root and root.stats and root.stats.resource:
		_dodge_speed = root.stats.resource.dodge_speed
	_distance_traveled = 0.0
	# Lock facing and grant invulnerability.
	lock_facing()
	root.is_invulnerable = true
	root.is_dashing = true
	# Freeze action layer — no attacking during dash.
	coordinator.freeze_action()
	coordinator.update_context("", true)
	# Prime velocity so the very first physics frame moves correctly.
	root.body.velocity = _dash_dir * _dodge_speed
	# Phase through interactables (Layer 2); keep world geometry (Layer 1).
	_original_mask = root.body.collision_mask
	root.body.collision_mask = 1
	# TEMP: Darken and halve sprite opacity as a dash visual until animations are ready.
	if root.sprite:
		root.sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	# TODO: Play 'dash enter' directional animation (e.g. "DashEnterDown") when animations are created.
	set_physics_process(true)

func _physics_process(_delta : float):
	# Maintain dash velocity and apply movement.
	root.body.velocity = _dash_dir * (2.0 * _dodge_speed)
	root.body.move_and_slide()
	_distance_traveled += _delta * _dodge_speed
	# Exit: max distance reached, or any world collision (mask is world-only during dash).
	var max_dist : float = .3 * _dodge_speed
	if _distance_traveled >= max_dist or root.body.get_slide_collision_count() > 0:
		# TODO: Play 'dash exit' directional animation (e.g. "DashExitDown") when animations are created.
		if idle_state:
			state_machine.change_state(coordinator.try_transition(state_machine, idle_state, "dash+complete"))

func exit():
	set_physics_process(false)
	# TEMP: Restore sprite from dash visual.
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
