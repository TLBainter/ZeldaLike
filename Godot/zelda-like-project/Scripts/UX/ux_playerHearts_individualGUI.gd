##[b][color=red]HeartGUI[/color][/b] is a class that defines the overall appearance and control for individual hearts.[br]
##[i]Hearts[/i] here refers to the player's visual heart display for their hit points.
class_name HeartGUI
extends Panel

#region VARIABLES
@export_category("Heart Components")
##The heart sprite for the gui
@export var sprite : TextureRect
##The animation player for the heart's pulsing
@export var pulse_anim : AnimationPlayer
##The animation player for the heart's flashing
@export var flash_anim : AnimationPlayer
@export_category("Heart Images")
##Full heart
@export var sprite_4_4_heart : AtlasTexture
##3/4 heart
@export var sprite_3_4_heart : AtlasTexture
##half heart
@export var sprite_2_4_heart : AtlasTexture
##1/4 heart
@export var sprite_1_4_heart : AtlasTexture
##empty heart
@export var sprite_0_4_heart : AtlasTexture

#endregion VARIABLEs

#region FUNCTIONS
##Updates the value of a heart based on its fill rate
func update(update_value : int):
	#Ensure update value doesn't exceed heart allotment
	update_value = clampi(update_value, 0, 4)
	#set the heart's texture to be equal to the number of hits remaining in that heart
	match update_value:
		0: sprite.texture = sprite_0_4_heart
		1: sprite.texture = sprite_1_4_heart
		2: sprite.texture = sprite_2_4_heart
		3: sprite.texture = sprite_3_4_heart
		4: sprite.texture = sprite_4_4_heart

##Pulsates a heart; used when the heart is the currently-active one.
func pulse(pulse_state : bool):
	if not pulse_anim:
		return
	if pulse_state:
		if pulse_anim and pulse_anim.current_animation != "heart_pulse":
			pulse_anim.play("heart_pulse")
	elif pulse_anim.is_playing or sprite.scale != Vector2.ONE:
		sprite.scale = Vector2.ONE
		pulse_anim.stop()

func flash(flash_state : bool):
	if not flash_anim:
		return
	if flash_state:
		if flash_anim and flash_anim.current_animation != "heart_flash_lowHP":
			flash_anim.play("heart_flash_lowHP")
	elif flash_anim.is_playing() or sprite.modulate != Color.WHITE:
		sprite.modulate = Color.WHITE
		flash_anim.stop()

#endregion FUNCTIONS
