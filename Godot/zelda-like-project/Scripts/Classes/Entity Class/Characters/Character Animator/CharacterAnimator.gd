##[b][color=red]CharacterAnimator[/color][/b] is used to play the animations of a Character-type [b]Entity[/b] if they have an Animnation Player.[br]
##It uses signals from the character's Input Component to play the animations.[br]
##If the character has [b]Visual → Sprite Sheets[/b] and [b]Visual → Animations[/b] resources defined, this node
##generates AnimationPlayer animations from them automatically at [code]_ready()[/code].
@tool
class_name CharacterAnimator
extends AnimationPlayer

#region VARIABLES
#region Export Variables
@export_group("Components")
@export_group("Export Animation Variables")
##Whether or not this character has diagonal movement; enabling this without diagonal animations will cause the cahracter to break.
@export var has_diagonal_movement : bool = false
@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()
##Toggle this in the editor to immediately regenerate animations from the character's Visual resources.[br]
##Useful for previewing auto-generated animations without running the game.
@export var _rebuild_animations : bool = false:
	set(v):
		if Engine.is_editor_hint() and v and is_node_ready():
			build_animations_from_resources()
		_rebuild_animations = false
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
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
@export var idle_prefix : String = AnimationName.IDLE
##The current prefix for walk animations. Set by stats.
@export var walk_prefix : String = AnimationName.WALK
##Whether the character's facing direction can be changed.
var can_update_facing : bool = true
##When non-empty, face() plays this prefix's directional animation instead of walk/idle.
var anim_override_prefix : String = ""
##whether or not the character is currently moving.
var is_moving : bool = false
#endregion Internal Variables
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	if Engine.is_editor_hint():
		return
	input.on_move.connect(face)
	build_animations_from_resources()

##Reads the character's [b]Visual → Sprite Sheets[/b] and [b]Visual → Animations[/b] resources and
##generates AnimationPlayer animations from them.[br]
##Already-existing animations (manually defined in the scene) are never overwritten.[br]
##Called automatically at [code]_ready()[/code]; also triggerable in the editor via the [i]Rebuild Animations[/i] toggle.
func build_animations_from_resources() -> void:
	if not root or root.visual_sprite_sheets.is_empty():
		return

	# Build sheet lookup: name → CharacterSpriteResource
	var sheet_map : Dictionary = {}
	for sheet : CharacterSpriteResource in root.visual_sprite_sheets:
		if sheet and sheet.sheet_name != "" and sheet.texture:
			sheet_map[sheet.sheet_name] = sheet

	# Apply the first sheet as the default texture on the sprite node.
	var default_sheet : CharacterSpriteResource = root.visual_sprite_sheets[0]
	if default_sheet and default_sheet.texture and root.sprite:
		root.sprite.texture  = default_sheet.texture
		root.sprite.hframes  = default_sheet.get_hframes()
		root.sprite.vframes  = default_sheet.get_vframes()

	# Ensure a default AnimationLibrary exists.
	if not has_animation_library(""):
		add_animation_library("", AnimationLibrary.new())
	var lib : AnimationLibrary = get_animation_library("")

	for anim_res : CharacterAnimationResource in root.visual_animations:
		if not anim_res or anim_res.animation_name == "" or anim_res.directions.is_empty():
			continue

		var sheet : CharacterSpriteResource = sheet_map.get(anim_res.sprite_sheet_name)
		if not sheet:
			if debug_me:
				printerr(debug_name, ": CharacterAnimationResource '", anim_res.animation_name,
					"' references unknown sprite sheet '", anim_res.sprite_sheet_name, "' — skipped.")
			continue

		var hframes    : int   = sheet.get_hframes()
		var frame_count : int  = anim_res.frame_count if anim_res.frame_count > 0 else hframes
		var frame_dur  : float = 1.0 / anim_res.frame_rate
		var is_default_sheet : bool = (sheet == default_sheet)

		for dir_entry : CharacterAnimationDirectionEntry in anim_res.directions:
			var anim_name : String = anim_res.animation_name + dir_entry.get_anim_suffix()

			if lib.has_animation(anim_name):
				continue  # Non-destructive: never overwrite manually-defined animations.

			var built : Animation = Animation.new()
			built.loop_mode = Animation.LOOP_LINEAR if anim_res.loops else Animation.LOOP_NONE
			built.length    = frame_count * frame_dur

			# Sprite frame track.
			# Track paths are relative to root_node (".." = root), NOT to self (the AnimationPlayer).
			var sprite_path : String = str(root.get_path_to(root.sprite))
			if debug_me:
				print(debug_name, ": track path = '", sprite_path, ":frame'")
			var frame_track : int = built.add_track(Animation.TYPE_VALUE)
			built.track_set_path(frame_track, NodePath(sprite_path + ":frame"))
			built.track_set_interpolation_type(frame_track, Animation.INTERPOLATION_NEAREST)
			built.value_track_set_update_mode(frame_track, Animation.UPDATE_DISCRETE)
			for f : int in frame_count:
				built.track_insert_key(frame_track, f * frame_dur, dir_entry.row * hframes + f)

			# If this animation uses a non-default sprite sheet, add texture/hframes/vframes
			# tracks at time 0 so the sprite switches automatically when the animation starts.
			if not is_default_sheet:
				var tex_track : int = built.add_track(Animation.TYPE_VALUE)
				built.track_set_path(tex_track, NodePath(sprite_path + ":texture"))
				built.track_set_interpolation_type(tex_track, Animation.INTERPOLATION_NEAREST)
				built.value_track_set_update_mode(tex_track, Animation.UPDATE_DISCRETE)
				built.track_insert_key(tex_track, 0.0, sheet.texture)

				var hf_track : int = built.add_track(Animation.TYPE_VALUE)
				built.track_set_path(hf_track, NodePath(sprite_path + ":hframes"))
				built.track_set_interpolation_type(hf_track, Animation.INTERPOLATION_NEAREST)
				built.value_track_set_update_mode(hf_track, Animation.UPDATE_DISCRETE)
				built.track_insert_key(hf_track, 0.0, hframes)

				var vf_track : int = built.add_track(Animation.TYPE_VALUE)
				built.track_set_path(vf_track, NodePath(sprite_path + ":vframes"))
				built.track_set_interpolation_type(vf_track, Animation.INTERPOLATION_NEAREST)
				built.value_track_set_update_mode(vf_track, Animation.UPDATE_DISCRETE)
				built.track_insert_key(vf_track, 0.0, sheet.get_vframes())

			lib.add_animation(anim_name, built)
			if debug_me:
				print(debug_name, ": generated animation '", anim_name, "' (", frame_count, " frames @ ", anim_res.frame_rate, " fps)")

##Sets the facing direction of the relevant character's sprite.[br]
##Has functionality for diagonal animations if required for the entity.
##Accepts "Vector2" to determine the face direction.
func set_facing(face_dir : Vector2):
	if face_dir == Vector2.ZERO:
		if facing == "":
			facing = "down"
		return
	var _prev_facing := facing
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
	# Hysteresis: require 1.4× axis dominance before switching, preventing oscillation near 45°.
	const AXIS_HYSTERESIS : float = 1.4
	var ax : float = abs(face_dir.x)
	var ay : float = abs(face_dir.y)
	var currently_horizontal : bool = facing == "left" or facing == "right"
	var use_horizontal : bool
	if currently_horizontal:
		use_horizontal = not (ay > ax * AXIS_HYSTERESIS)
	else:
		use_horizontal = ax > ay * AXIS_HYSTERESIS
	if use_horizontal:
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
	if debug_me_verbose and facing != _prev_facing:
		print_rich(debug_name, ": facing [i]", _prev_facing, "[/i] → [i]", facing, "[/i]")

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

##Sets the player's facing direction and plays their Walk Animation and Idle animation based on input.
func face(face_dir : Vector2, _delta : float):
	if not can_update_facing:
		if debug_me_verbose:
			print_rich(debug_name, " [face] blocked — can_update_facing=false  dir=", face_dir)
		return
	set_facing(face_dir)
	var coord := root.state_machine as StateCoordinator
	var movement_active : bool = coord != null \
		and coord.movement_layer != null \
		and (coord.movement_layer as StateMachineLayer).is_active
	if anim_override_prefix != "":
		play_directional_anim(anim_override_prefix)
	elif face_dir != Vector2.ZERO and movement_active:
		play_directional_anim(walk_prefix)
	else:
		if debug_me_verbose and face_dir != Vector2.ZERO:
			var _layer_str : String = str((coord.movement_layer as StateMachineLayer).is_active) if coord and coord.movement_layer else "N/A"
			print_rich(debug_name, " [face] playing IDLE despite non-zero dir=", face_dir,
				"  movement_active=", movement_active,
				"  layer_active=", _layer_str,
				"  current_anim=", current_animation)
		play_directional_anim(idle_prefix)

##Sets idle and walk prefixes based on exhaustion state.[br]
##Call this in any state that needs to reflect exhaustion; play the resulting animation separately.
func set_exhaustion_state(is_exhausted: bool) -> void:
	if is_exhausted:
		idle_prefix = AnimationName.EXHAUSTED_IDLE
		walk_prefix = AnimationName.EXHAUSTED_WALK
	else:
		idle_prefix = AnimationName.IDLE
		walk_prefix = AnimationName.WALK

##Forces the character to face a given direction, bypassing input and state machine checks.[br]
##Used for interactions, cutscenes, and other scripted moments.[br]
##Plays the Idle animation for the resulting facing direction by default.
func force_face(face_dir : Vector2):
	if face_dir == Vector2.ZERO:
		return
	set_facing(face_dir)
	play_directional_anim(AnimationName.IDLE)
	if debug_me:
		print(debug_name, " forced to face ", facing)

