@icon("res://Editor Tools/Icons/icon_move.svg")
##[b][color=red]MoveComponent[/color][/b] is the handler for all movement a Character entity can take, regardless of their type.[br]
class_name MoveComponent
extends Component

#region VARIABLES
#region Export Variables
@export_group("Movement Components")
@export_group("Movement Variables")
@export_subgroup("Values")
##Minimum distance (px) to maintain from wall colliders. When > 0, each axis of the
##movement vector is zeroed if moving that way would bring the body within this range.
##Set to ~4 on enemies to prevent corner-pressing. Leave at 0 for the player.
@export var collision_buffer : float = 0.0
##When true: if this body slides against the player for several consecutive frames,
##the Character-layer bit is briefly removed from its collision mask so it can
##reposition without physically carrying the player. Re-enabled automatically.
@export var phase_through_on_stuck : bool = false
#endregion
#region Internal Variables
## The parent entity; resolved by walking up the scene tree to find the owning Character.
@onready var root : Character = _find_entity_parent() as Character
##The entity from which this move component receives its move signals; expects an InputComponent
@onready var input : InputComponent = root.input
##a reference to the CharacterBody2D node of a character
@onready var body : CharacterBody2D = root.body
##The direction of the entity's movement; this is received from the moveSignal.
var move_dir : Vector2
##The strength of the entity's movement; this is received from the moveSignal.
var move_str : float

const _STUCK_FRAME_THRESHOLD : int = 8
const _PHASE_THROUGH_FRAMES : int = 24
var _stuck_frames : int = 0
var _phase_through_countdown : int = 0
#endregion
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	var stats = _get_entity_stats()
	root.move_speed = stats.walk_speed if stats else 50.0
	input.on_move.connect(move)

func move(move_input, move_strength):
	move_dir = move_input
	move_str = move_strength
	if root.is_dashing:
		return
	if root.is_blocking:
		body.velocity = Vector2.ZERO
		return
	if root.state_machine and root.state_machine.movement_layer \
	and not root.state_machine.movement_layer.is_active:
		body.velocity = Vector2.ZERO
		return
	var velocity := move_dir * root.move_speed
	if collision_buffer > 0.0 and velocity != Vector2.ZERO:
		var pre_buf := velocity
		var x_blocked := false
		var y_blocked := false
		if velocity.x != 0.0 and body.test_move(body.transform, Vector2(sign(velocity.x), 0.0) * collision_buffer):
			velocity.x = 0.0
			x_blocked = true
		if velocity.y != 0.0 and body.test_move(body.transform, Vector2(0.0, sign(velocity.y)) * collision_buffer):
			velocity.y = 0.0
			y_blocked = true
		if debug_me and (x_blocked or y_blocked):
			print_rich("[color=red]", debug_name, " BUFFER[/color]",
				"  pre=", pre_buf, "  post=", velocity,
				"  x_blocked=", x_blocked, "  y_blocked=", y_blocked)
	body.velocity = velocity
	body.move_and_slide()
	if phase_through_on_stuck:
		_tick_phase_through()
	var _slide_n := body.get_slide_collision_count()
	if debug_me_verbose:
		print_rich("[color=cyan]", debug_name, " MOVE[/color]",
			"  dir=", move_dir, "  vel_in=", velocity,
			"  vel_out=", snapped(body.velocity, Vector2(0.01, 0.01)),
			"  buf=", collision_buffer, "  slides=", _slide_n)
	if debug_me and _slide_n > 0:
		for i in _slide_n:
			var col := body.get_slide_collision(i)
			var collider := col.get_collider()
			print_rich("[color=orange]", debug_name, " SLIDE[/color]",
				"  pos=", snapped(body.global_position, Vector2(0.1, 0.1)),
				"  vel_in=", velocity,
				"  hit=[i]", collider.name if collider else "unknown", "[/i]",
				" (", collider.get_class() if collider else "?", ")")

func _tick_phase_through() -> void:
	if _phase_through_countdown > 0:
		_phase_through_countdown -= 1
		if _phase_through_countdown == 0:
			body.set_collision_mask_value(1, true)
			body.set_collision_layer_value(1, true)
			_stuck_frames = 0
		return
	var pressed_against_player := false
	for i in body.get_slide_collision_count():
		var col := body.get_slide_collision(i)
		var collider := col.get_collider()
		if collider and collider.get_parent() and collider.get_parent().is_in_group("player"):
			pressed_against_player = true
			break
	if pressed_against_player:
		_stuck_frames += 1
		if _stuck_frames >= _STUCK_FRAME_THRESHOLD:
			body.set_collision_mask_value(1, false)
			body.set_collision_layer_value(1, false)
			_phase_through_countdown = _PHASE_THROUGH_FRAMES
	else:
		_stuck_frames = 0

##For playing footstep sounds and adding effects, eventually.
func play_footstep():
	pass
	
#endregion FUNCTIONS
