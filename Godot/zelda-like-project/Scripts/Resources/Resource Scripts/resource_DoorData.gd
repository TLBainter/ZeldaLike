@tool
class_name DoorResource
extends Resource

const Direction = preload("res://Scripts/Constants/const_directions.gd")

@export_group("Locked Sprites")
@export var locked_top: Texture2D
@export var locked_bottom: Texture2D
@export var locked_left: Texture2D
@export var locked_right: Texture2D

@export_group("Unlocked Sprites")
@export var unlocked_top: Texture2D
@export var unlocked_bottom: Texture2D
@export var unlocked_left: Texture2D
@export var unlocked_right: Texture2D

@export_group("Unlocking Animation Strip")
@export var unlocking_top: Texture2D
@export var unlocking_bottom: Texture2D
@export var unlocking_left: Texture2D
@export var unlocking_right: Texture2D
@export var unlocking_frames: int = 4

@export_group("Opening Animation Strip")
@export var opening_top: Texture2D
@export var opening_bottom: Texture2D
@export var opening_left: Texture2D
@export var opening_right: Texture2D
@export var opening_frames: int = 4

@export_group("Audio")
@export var unlock_sound: SoundLibrary
@export var opening_sound: SoundLibrary
@export var opened_sound: SoundLibrary

#region DIRECTIONAL TEXTURE LOOKUP

##Get a sprite texture for the given state and direction.
##[param state]: "locked", "unlocked", "unlocking", or "opening"
##[param direction]: Direction constant (TOP, BOTTOM, LEFT, RIGHT)
func get_sprite(state: String, direction: int) -> Texture2D:
	var sprites: Array
	match state:
		"locked":
			sprites = [locked_top, locked_bottom, locked_left, locked_right]
		"unlocked":
			sprites = [unlocked_top, unlocked_bottom, unlocked_left, unlocked_right]
		"unlocking":
			sprites = [unlocking_top, unlocking_bottom, unlocking_left, unlocking_right]
		"opening":
			sprites = [opening_top, opening_bottom, opening_left, opening_right]
		_:
			return null

	# Map Direction constants to array indices
	var index = direction
	match direction:
		Direction.TOP: index = 0
		Direction.BOTTOM: index = 1
		Direction.LEFT: index = 2
		Direction.RIGHT: index = 3
		_: return null

	if index >= 0 and index < sprites.size():
		return sprites[index]
	return null

#region COMPATIBILITY WRAPPERS

##Compatibility wrapper. Use [method get_sprite] instead.
func get_locked_sprite(side: int) -> Texture2D:
	return get_sprite("locked", side)

##Compatibility wrapper. Use [method get_sprite] instead.
func get_unlocked_sprite(side: int) -> Texture2D:
	return get_sprite("unlocked", side)

##Compatibility wrapper. Use [method get_sprite] instead.
func get_unlocking_strip(side: int) -> Texture2D:
	return get_sprite("unlocking", side)

##Compatibility wrapper. Use [method get_sprite] instead.
func get_opening_strip(side: int) -> Texture2D:
	return get_sprite("opening", side)

#endregion COMPATIBILITY WRAPPERS

#endregion DIRECTIONAL TEXTURE LOOKUP
