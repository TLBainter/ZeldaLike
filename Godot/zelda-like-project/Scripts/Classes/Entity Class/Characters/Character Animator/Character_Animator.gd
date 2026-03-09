##[b][color=red]CharacterAnimator[/color][/b] is used to play the animations of a Character-type [b]Entity[/b] if they have an Animnation Player.[br]
##It uses signals from the character's Input Component to play the animations.
class_name CharacterAnimator
extends AnimationPlayer

#region VARIABLES
#region Export Variables
@export_group("Components")
@export_group("Export Animation Variables")
##Whether or not this character has diagonal movement; enabling this without diagonal animations will cause the cahracter to break.
@export var has_diagonal_movement : bool = false
@export_group("Debug")
##Whether or not you wish to debug this entity
@export var debug_me : bool = false
##The name you will use in the debugger for this component
@export var debug_name : String = ""
#endregion Export Variables
#region Internal Variables
## The parent entity; expects a character
@onready var root : Character = $".."
## A reference to the character's input component
@onready var input : InputComponent = root.input
@onready var anim : AnimationPlayer	= root.anim
##The direction the character is facing.
var facing : String = "down"
##The current prefix for idle animations. Set by states.
var idle_prefix : String = "Idle"
##The current prefix for walk animations. Set by stats.
var walk_prefix : String = "Walk"
##Whether the character's facing direction can be changed.
var can_update_facing : bool = true
##whether or not the character is currently moving.
var is_moving : bool = false
#endregion Internal Variables
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	input.onMove.connect(face)

##Sets the facing direction of the relevant character's sprite.[br]
##Has functionality for diagonal animations if required for the entity.
##Accepts "Vector2" to determine the face direction.
func set_facing(face_dir : Vector2):
	if face_dir == Vector2.ZERO:
		if facing == "":
			facing = "down"
		return
	#region face variables
	##whether the character is looking down
	var down : bool = false
	##whether the character is looking right
	var right : bool = false
	##whether the character is looking up
	var up : bool = false
	##whether the character is looking left
	var left : bool = false
	#endregion face variables
	#region set facing direction
	if abs(face_dir.x) > abs(face_dir.y):
		if face_dir.x < 0:
			facing = "left"
			left = true
			right = false
		else:
			facing = "right"
			right = true
			left = false
	else:
		if face_dir.y < 0:
			facing = "up"
			up = true
			down = false
		else:
			facing = "down"
			down = true
			up = false
	#endregion set facing direction
	#region diagonal facing directions
	if has_diagonal_movement:
		if up and left:
			facing = "up_left"
		elif up and right:
			facing = "up_right"
		elif down and left:
			facing = "down_left"
		elif down and right:
			facing = "down_right"
	#endregion diagonal facing directions
	
##Plays the animation dictated by the prefix combined with the current facing direction.[br]
##For example, [b]play_directional_anim("Lift")[/b] with facing [i]down[/i] plays "LiftDown".[br]
##Returns [b]true[/b] if the animation was found and played, [b]false[/b] otherwise (for debugging).[br]
func play_directional_anim(prefix : String, force : bool = false) -> bool:
	var anim_name : String = prefix + facing.capitalize().replace(" ", "")
	if has_animation(anim_name) and (force or current_animation != anim_name):
		play(anim_name)
		if debug_me:
			print(debug_name, " is playing animation ", anim_name)
		return true
	elif debug_me and not has_animation(anim_name):
		printerr(debug_name, " received a request to play ", prefix, " while facing ", facing, ", but ", anim_name, " does not exist for this animation player!")
	return false

#TODO: Remove walk/idle from this function and instead call animations based on what animation should be played.
#Will rely on state machines to determine.
##Sets the player's facing direction and plays their Walk Animation and Idle animation based on input.
func face(face_dir : Vector2, _delta : float):
	if not can_update_facing:
		return
	set_facing(face_dir)
	if face_dir != Vector2.ZERO:
		play_directional_anim(walk_prefix)
	else:
		play_directional_anim(idle_prefix)

#TODO: Remove forced idle from this function and instead call animations based on what animation should be played.
#Will rely on state machines to determine.
##Forces the character to face a given direction, bypassing input and state machine checks.[br]
##Used for interactions, cutscenes, and other scripted moments.[br]
##Plays the Idle animation for the resulting facing direction by default.
func force_face(face_dir : Vector2):
	if face_dir == Vector2.ZERO:
		return
	set_facing(face_dir)
	play_directional_anim("Idle")
	if debug_me:
		print(debug_name, " forced to face ", facing)
