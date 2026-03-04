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
##Whether the character's facing direction can be changed.
var can_update_facing : bool = true
##whether or not the character is currently moving.
var is_moving : bool = false
#endregion Internal Variables
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	input.onMove.connect(face)

#TODO: Add diagonal facing directions
##This function sets the 'facing direction' of the character.
func face(face_dir : Vector2, _delta : float):
	if not can_update_facing:
		return
	##whether the character is looking down
	var down : bool = false
	##whether the character is looking right
	var right : bool = false
	##whether the character is looking up
	var up : bool = false
	##whether the character is looking left
	var left : bool = false
	#region left/right facing directions
	if face_dir.length() > 0.1:
		if abs(face_dir.x) > abs(face_dir.y):
			# Mostly Horizontal
			if face_dir.x < 0:
				left = true
				right = false
				facing = "left"
			else:
				right = true
				left = false
				facing = "right"
		else:
			# Mostly Vertical
			if face_dir.y < 0:
				up = true
				down = false
				facing = "up"
			else:
				down = true
				up = false
				facing = "down"
	#if you do not have a facing direction, set it to down.
	if face_dir == Vector2.ZERO and facing == "":
		down = true
		facing = "down"
	#endregion
	#region Diagonal Facing
	if has_diagonal_movement:
		if up and left:
			facing = "up_left"
		elif up and right:
			facing = "up_right"
		elif down and left:
			facing = "down_left"
		elif down and right:
			facing = "down_right"
	#endregion
	#region Walk/Run
	#set the animation type prefix
	var anim_type : String
	#If we are moving...
	if face_dir != Vector2.ZERO:
		anim_type = "Walk"
	#
	#
	#INFO: This is where you will put other options, with 'else' being the idle animation.
	#
	#
	else: anim_type = "Idle"
	#Capitalize the facing direction to match with animation formatting, then play the relevant animation.
	var anim_name : String = anim_type + facing.capitalize().replace(" ", "")
	if has_animation(anim_name) and current_animation != anim_name:
			play(anim_name)
			if debug_me:
				print(debug_name, " is playing animation ", anim_name)
	#endregion

##Forces the character to face a given direction, bypassing input and state machine checks.[br]
##Used for interactions, cutscenes, and other scripted moments.[br]
##Plays the Idle animation for the resulting facing direction.

func force_face(face_dir : Vector2):
	if face_dir == Vector2.ZERO:
		return
	if abs(face_dir.x) > abs(face_dir.y):
		if face_dir.x < 0:
			facing = "left"
		else:
			facing = "right"
	else:
		if face_dir.y < 0:
			facing = "up"
		else:
			facing = "down"
	var anim_name : String = "Idle" + facing.capitalize().replace(" ","")
	if has_animation(anim_name):
		play(anim_name)
	elif debug_me:
		print(debug_name, " does not have an animation called ", anim_name)
	if debug_me:
		print(debug_name, " forced to face ", facing)
#endregion FUNCTIONS
