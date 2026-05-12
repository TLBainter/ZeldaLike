##[b][color=red]MagicMedallionGUI[/color][/b] controls the display of a single magic medallion in the player's magic UI.[br]
##Computes the correct sprite from a 17x17 sprite sheet based on shard count and current fill.[br]
##Updated by [b]MagicDisplay[/b] based on the character's current magic.
class_name MagicMedallionGUI
extends Panel

#region VARIABLES

@export_category("Medallion Components")
##The child TextureRect that displays the medallion sprite.
@export var sprite : TextureRect
##The texture's animator.
@export var animator : AnimationPlayer
##The texture's flasher.
@export var flasher : AnimationPlayer

@export_category("Medallion Settings")
##The full sprite sheet containing all medallion states.
@export var sprite_sheet : Texture2D

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v


##The size of each sprite cell in the sheet.
const CELL_SIZE : int = 17
##Cached AtlasTexture for reuse.
var _atlas : AtlasTexture

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	_atlas = AtlasTexture.new()
	if sprite_sheet:
		_atlas.atlas = sprite_sheet

##Updates the medallion's appearance based on its shard count and fill value.[br]
##[b]shards[/b]: How many shards this medallion has (1-6).[br]
##[b]fill[/b]: How much magic is currently in this medallion (0 to shards).
func update(shards : int, fill : int) -> void:
	if not sprite or not sprite_sheet:
		return
	shards = clampi(shards, 0, 6)
	fill = clampi(fill, 0, shards)
	var atlas = AtlasTexture.new()
	var grid_pos : Vector2i = _get_sprite_position(shards, fill)
	atlas.atlas = sprite_sheet
	atlas.region = Rect2(
		grid_pos.x * CELL_SIZE,
		grid_pos.y * CELL_SIZE,
		CELL_SIZE,
		CELL_SIZE
	)
	sprite.texture = atlas
	if debug_me:
		print(debug_name, " updated: shards=", shards, " fill=", fill, " grid=", grid_pos)

##Calculates the sprite grid position based on shard count and fill.[br]
##Returns a Vector2i(column, row) into the sprite sheet.
func _get_sprite_position(shards : int, fill : int) -> Vector2i:
	var col : int = 6 - fill
	var row : int
	if shards == 6:
		row = 0
	elif fill == shards:
		row = 1
	elif shards == 1 and fill == 0:
		row = 1
	else:
		row = 7 - shards
	var result = Vector2i(col, row)
	print("SPRITE LOOKUP: shards=", shards, " fill=", fill, " -> col=", col, " row=", row)
	return result
	
#region animations
##Plays the active magic animation loop.
func play_active_anim() -> void:
	if animator and animator.has_animation("ActiveMedallion"):
		if animator.current_animation != ("ActiveMedallion"):
			animator.play("ActiveMedallion")

##Stops the active magic animation and resets scale.
func stop_active_anim():
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
	if flasher and flasher.has_animation("MagicUseFlash"):
		flasher.stop()
		flasher.play("MagicUseFlash")
#endregion animations

#endregion FUNCTIONS
