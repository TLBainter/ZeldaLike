##[b][color=red]SkullGUI[/color][/b] is a class that defines the overall appearance and control for individual skulls.[br]
##[i]Skulls[/i] here refers to the player's visual skull display for their hit points.
class_name SkullGUI
extends Panel

#region VARIABLES
@export_category("Skull Components")
##The skull sprite for the gui
@export var sprite : TextureRect
##The animation player for the skull's pulsing
@export var pulse_anim : AnimationPlayer
##The animation player for the skull's flashing
@export var flash_anim : AnimationPlayer
@export_category("Skull Images")
##Full skull
@export var sprite_4_4_skull : AtlasTexture
##3/4 skull
@export var sprite_3_4_skull : AtlasTexture
##half skull
@export var sprite_2_4_skull : AtlasTexture
##1/4 skull
@export var sprite_1_4_skull : AtlasTexture
##empty skull
@export var sprite_0_4_skull : AtlasTexture

#endregion VARIABLEs

var _fill_value : int = 0

#region FUNCTIONS
##Updates the value of a skull based on its fill rate
func update(update_value : int):
	_fill_value = clampi(update_value, 0, 4)
	match _fill_value:
		0: sprite.texture = sprite_0_4_skull
		1: sprite.texture = sprite_1_4_skull
		2: sprite.texture = sprite_2_4_skull
		3: sprite.texture = sprite_3_4_skull
		4: sprite.texture = sprite_4_4_skull

##Pulsates a skull; used when the skull is the currently-active one.
func pulse(pulse_state : bool, speed : float = 1.0):
	if not pulse_anim:
		return
	if pulse_state:
		if pulse_anim and pulse_anim.current_animation != "skull_pulse":
			pulse_anim.play("skull_pulse")
		pulse_anim.speed_scale = speed
	elif pulse_anim.is_playing() or sprite.scale != Vector2.ONE:
		sprite.scale = Vector2.ONE
		pulse_anim.play("RESET")
		pulse_anim.speed_scale = 1.0
	z_index = 1 if pulse_state else 0
	if pulse_state:
		modulate.a = 1.0
	elif _fill_value == 0:
		modulate.a = 0.7
	else:
		modulate.a = 0.9

func flash(flash_state : bool):
	if not flash_anim:
		return
	if flash_state:
		if flash_anim and flash_anim.current_animation != "skull_flash_lowHP":
			flash_anim.play("skull_flash_lowHP")
	elif flash_anim.is_playing() or sprite.modulate != Color.WHITE:
		sprite.modulate = Color.WHITE
		flash_anim.stop()

#endregion FUNCTIONS
