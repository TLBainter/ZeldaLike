@tool
class_name DoorResource
extends Resource

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

func get_locked_sprite(side: int) -> Texture2D:
	match side:
		0: return locked_top
		1: return locked_bottom
		2: return locked_left
		3: return locked_right
	return null

func get_unlocked_sprite(side: int) -> Texture2D:
	match side:
		0: return unlocked_top
		1: return unlocked_bottom
		2: return unlocked_left
		3: return unlocked_right
	return null

func get_unlocking_strip(side: int) -> Texture2D:
	match side:
		0: return unlocking_top
		1: return unlocking_bottom
		2: return unlocking_left
		3: return unlocking_right
	return null

func get_opening_strip(side: int) -> Texture2D:
	match side:
		0: return opening_top
		1: return opening_bottom
		2: return opening_left
		3: return opening_right
	return null
