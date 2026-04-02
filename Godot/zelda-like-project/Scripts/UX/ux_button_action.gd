##[b][color=red]ActionButtonSprite[/color][/b] handles the visuals of a button in the UI.[br]
##Used for the action buttons (A/B/X/Y, Up, Down, Right, Left, etc.)
class_name ActionButtonSprite
extends Panel

#region VARIABLES
@export_category("Components")
##A reference to the UI control node
@export var root : PlayerUX
##A reference to the player's input component
@onready var input : PlayerInputComponent = root.input
## The TextureRect displaying the button image.
@export var button_rect : TextureRect
##A reference to this button's animation player
@export var anim_player : AnimationPlayer
##The AnimationPlayer for spell assignment flash effects (glow/tint).
@export var flash_anim : AnimationPlayer
##The AnimationPlayer for spell assignment motion effects (slide/bounce).
@export var motion_anim : AnimationPlayer

@export_category("Button Textures")
## Texture to use when action_name is "actionButton1"
@export var button_1_texture : Texture2D
## Texture to use when action_name is "actionButton2"
@export var button_2_texture : Texture2D
## Texture to use when action_name is "actionButton3"
@export var button_3_texture : Texture2D
## Texture to use when action_name is "actionButton4"
@export var button_4_texture : Texture2D

@export_category("Settings")
##The action name this sprite represents
@export_enum("actionButton1", "actionButton2", "actionButton3", "actionButton4", "dPadUp", "dPadDown", "dPadRight", "dPadLeft") var action_name : String = "choose a button"
##The tint to show the button as when available
@export var available_tint : Color = Color(1, 1, 1, 1)
##the tint and visibility to apply when the button is unavailable
@export var unavailable_tint : Color = Color(0.5, 0.5, 0.5, 0.5)
##The TextureRect for displaying the assigned spell's mini icon.
@export var spell_texture_rect : TextureRect
##Flips the spell icon to the left side of the button instead of the right.
@export var flip_spell_pos : bool = false:
	set(value):
		flip_spell_pos = value
		_apply_spell_position()

@export_category("Debug")
##Whether or not you want this entity to print to the debugger
@export var debug_me : bool = false
@export var debug_name : String = "Button"

#====INTERNAL====#
#SPELL TRACKING VARIABLES#
var _current_spell : MenuItemResource = null
var _equipped_spells : EquippedSpellsComponent = null
var _my_slot : int = -1
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	if input:
		if debug_me:
			print("Got input component for button ", action_name)
		if not input.actionButtonPressed.is_connected(_on_action_button_pressed):
			input.actionButtonPressed.connect(_on_action_button_pressed)
		#TODO: Fix this logic; it may not always be true. Setting availability should happen outside of this script, being called by other entities.
		#Perhaps set_available should have a default state stored within itself.
		set_available(true)
	else:
		if debug_me:
			print("Could not get input component for button ", action_name)
	if spell_texture_rect and not _current_spell:
		spell_texture_rect.visible = false
	if debug_me:
			print("ACTION BTN ", action_name, ": _ready() hid spell_texture_rect. _current_spell=", _current_spell)
	_apply_spell_position()
	_assign_button_texture()

func _on_action_button_pressed(btn : String):
	if btn == action_name:
		_play_press_anim()

func _play_press_anim():
	if anim_player:
		##Names the animation to play; it is imperative that this match the animation in the ActionButtonAnimator!
		var anim_to_play : String = action_name + "_press"
		if anim_player.has_animation(anim_to_play):
			anim_player.stop()
			anim_player.play(anim_to_play)
		elif debug_me:
			printerr("Animation not found: ", anim_to_play, " on button ", debug_name)

func set_available(active : bool):
	if active:
		if button_rect: button_rect.modulate = available_tint
	else:
		if button_rect: button_rect.modulate = unavailable_tint

func _assign_button_texture() -> void:
	if not button_rect:
		return
	match action_name:
		"actionButton1": button_rect.texture = button_1_texture
		"actionButton2": button_rect.texture = button_2_texture
		"actionButton3": button_rect.texture = button_3_texture
		"actionButton4": button_rect.texture = button_4_texture

#region Spell Setting===========#
func set_equipped_spells(equipped_spells : EquippedSpellsComponent, slot_index : int) -> void:
	_equipped_spells = equipped_spells
	_my_slot = slot_index
	if _equipped_spells and not _equipped_spells.spell_equip_changed.is_connected(_on_spell_equip_changed):
		_equipped_spells.spell_equip_changed.connect(_on_spell_equip_changed)
	_current_spell = _equipped_spells.get_spell(_my_slot) if _equipped_spells else null
	if debug_me:
		print("ACTION BTN ", action_name, ": set_equipped_spells called. slot=", _my_slot, " _current_spell=", _current_spell)
	_update_spell_display()

func _on_spell_equip_changed(slot : int, spell_resource : MenuItemResource) -> void:
	if slot != _my_slot:
		return
	_current_spell = spell_resource
	if debug_me:
		print("ACTION BTN ", action_name, ": _on_spell_equip_changed. slot=", slot, " spell=", spell_resource, " mini_icon=", spell_resource.mini_icon if spell_resource else "null")
	_update_spell_display()

func _update_spell_display() -> void:
	if debug_me:
		print("ACTION BTN ", action_name, ": _update_spell_display called.")
		print("  spell_texture_rect=", spell_texture_rect)
		print("  _current_spell=", _current_spell)
		print("  mini_icon=", _current_spell.mini_icon if _current_spell else "null")
		if spell_texture_rect:
			print("  BEFORE visible=", spell_texture_rect.visible, " texture=", spell_texture_rect.texture)
	if not spell_texture_rect:
		return
	if _current_spell and _current_spell.mini_icon:
		spell_texture_rect.visible = true
		spell_texture_rect.texture = _current_spell.mini_icon
	else:
		spell_texture_rect.visible = false
	if debug_me:
		print("  AFTER visible=", spell_texture_rect.visible, " texture=", spell_texture_rect.texture)
	_apply_spell_position()
#endregion Spell Setting===========#

#region Animator================#
##Plays the assign animation (motion + flash). Call after updating spell display.
func play_assign_anim() -> void:
	if motion_anim and motion_anim.has_animation("assign_motion"):
		motion_anim.stop()
		motion_anim.play("assign_motion")
	if flash_anim and flash_anim.has_animation("assign_flash") and _current_spell:
		var anim = flash_anim.get_animation("assign_flash")
		var flash_color : Color = _current_spell.flash_color if _current_spell.flash_color else Color.WHITE
		for track_idx in range(anim.get_track_count()):
			var path = anim.track_get_path(track_idx)
			if ":self_modulate" in str(path):
				if anim.track_get_key_count(track_idx) > 1:
					anim.track_set_key_value(track_idx, 1, flash_color)
				if anim.track_get_key_count(track_idx) > 3:
					anim.track_set_key_value(track_idx, 3, flash_color)
				break
	if flash_anim and flash_anim.has_animation("assign_flash"):
		flash_anim.stop()
		flash_anim.play("assign_flash")

##Plays the unassign animation (motion + flash). Await this before changing display.
func play_unassign_anim() -> void:
	if motion_anim and motion_anim.has_animation("unassign_motion"):
		motion_anim.stop()
		motion_anim.play("unassign_motion")
	if flash_anim and flash_anim.has_animation("unassign_flash") and _current_spell:
		var anim = flash_anim.get_animation("unassign_flash")
		var flash_color : Color = _current_spell.flash_color if _current_spell.flash_color else Color.WHITE
		for track_idx in range(anim.get_track_count()):
			var path = anim.track_get_path(track_idx)
			if ":self_modulate" in str(path):
				if anim.track_get_key_count(track_idx) > 1:
					anim.track_set_key_value(track_idx, 1, flash_color)
				break
	if flash_anim and flash_anim.has_animation("unassign_flash"):
		flash_anim.stop()
		flash_anim.play("unassign_flash")

##Returns the duration of the unassign_motion animation, or 0 if not found.
func get_unassign_duration() -> float:
	if motion_anim and motion_anim.has_animation("unassign_motion"):
		return motion_anim.get_animation("unassign_motion").length
	return 0.0

##Resets both animation players to their default state.
func reset_anims() -> void:
	if motion_anim and motion_anim.is_playing():
		motion_anim.stop()
	if flash_anim and flash_anim.is_playing():
		flash_anim.stop()
#endregion Animator================#

#region Position===============#
func _apply_spell_position() -> void:
	if not spell_texture_rect:
		return
	spell_texture_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	spell_texture_rect.size = spell_texture_rect.texture.get_size() if spell_texture_rect.texture else Vector2(16, 16)
	if flip_spell_pos:
		spell_texture_rect.position = Vector2(0, 10)
	else:
		spell_texture_rect.position = Vector2(7, 10)
#endregion Position============#

#endregion FUNCTIONS
