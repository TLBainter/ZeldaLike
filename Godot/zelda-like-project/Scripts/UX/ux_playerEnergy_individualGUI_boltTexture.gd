##[b][color=red]EnergyBoltGUI[/color][/b] controls the display of a single energy bolt in the player's energy UI.[br]
##Uses a sprite sheet with 5 frames: full (0), 3/4 (1), 1/2 (2), 1/4 (3), empty (4).[br]
##Supports red flashing (exhausted) and white flashing (recovery pickup).[br]
##Updated by [b]EnergyDisplay[/b] based on the character's current energy.
class_name EnergyBoltGUI
extends Panel

#region VARIABLES

@export_category("Bolt Components")
##The child TextureRect that displays the bolt sprite.
@export var sprite : TextureRect
##The texture's animator.
@export var animator : AnimationPlayer
##The texture's flasher.
@export var flasher : AnimationPlayer

@export_category("Bolt Sprites")
##Full bolt (4/4 energy)
@export var sprite_full : AtlasTexture
##3/4 bolt
@export var sprite_3_4 : AtlasTexture
##1/2 bolt
@export var sprite_half : AtlasTexture
##1/4 bolt
@export var sprite_1_4 : AtlasTexture
##Empty bolt (0 energy)
@export var sprite_empty : AtlasTexture

@export_category("Flash Settings")
##The color used for the exhausted flash.
@export var exhausted_flash_color : Color = Color(1.0, 0.3, 0.3, 1.0)
##The color used for the recovery flash (pickup/potion).
@export var recovery_flash_color : Color = Color.WHITE
##How fast the flash cycles (flashes per second).
@export var flash_speed : float = 4.0

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v


##Whether the bolt is currently flashing red (exhausted).
var _is_flash_red : bool = false
##Whether the bolt is doing a one-shot white recovery flash.
var _is_flash_white : bool = false
##Timer tracking for flash oscillation.
var _flash_time : float = 0.0

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	set_process(false)

##Updates the bolt's appearance based on its fill value (0-4).[br]
##[b]fill[/b]: 0 = empty, 1 = 1/4, 2 = half, 3 = 3/4, 4 = full.
func update(fill : int) -> void:
	fill = clampi(fill, 0, 4)
	if not sprite:
		return
	match fill:
		4: sprite.texture = sprite_full
		3: sprite.texture = sprite_3_4
		2: sprite.texture = sprite_half
		1: sprite.texture = sprite_1_4
		0: sprite.texture = sprite_empty
	if debug_me:
		print(debug_name, " updated to fill: ", fill)

##Starts the red exhausted flash. Flashes continuously until stopped.
func start_exhausted_flash() -> void:
	_is_flash_red = true
	_flash_time = 0.0
	set_process(true)

##Stops the red exhausted flash and resets the sprite color.
func stop_exhausted_flash() -> void:
	_is_flash_red = false
	if sprite:
		sprite.modulate = Color.WHITE
	if not _is_flash_white:
		set_process(false)

##Performs a one-shot white flash for recovery pickups.[br]
##Flashes white briefly then returns to normal.
func do_recovery_flash() -> void:
	_is_flash_white = true
	_flash_time = 0.0
	if sprite:
		sprite.modulate = recovery_flash_color
	set_process(true)

func _process(delta : float) -> void:
	_flash_time += delta
	if _is_flash_white:
		if _flash_time > 0.15:
			_is_flash_white = false
			if sprite:
				sprite.modulate = Color.WHITE
			if not _is_flash_red:
				set_process(false)
			_flash_time = 0.0
		return
	if _is_flash_red:
		var t : float = (sin(_flash_time * flash_speed * TAU) + 1.0) / 2.0
		if sprite:
			sprite.modulate = Color.WHITE.lerp(exhausted_flash_color, t)

#region animations
##Plays the active bolt animation loop.
func play_active_anim() -> void:
	if animator and animator.has_animation("ActiveEnergy"):
		if animator.current_animation != "ActiveEnergy":
			animator.play("ActiveEnergy")

##Stops the active bolt animation and resets scale.
func stop_active_anim() -> void:
	if animator:
		animator.play("RESET")
		animator.stop()
	if flasher:
		flasher.play("RESET")
		flasher.stop()
	if sprite:
		sprite.scale = Vector2.ONE

##Plays the use flash animation (one-shot).
func play_use_flash() -> void:
	if flasher and flasher.has_animation("EnergyUseFlash"):
		flasher.stop()
		flasher.play("EnergyUseFlash")
#endregion animations

#endregion FUNCTIONS
