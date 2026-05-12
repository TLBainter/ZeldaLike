##Handles visuals of action buttons (A/B/X/Y, directional, etc.).
class_name ActionButtonSprite
extends Panel

#region VARIABLES
@export_category("Components")
@export var root : PlayerUX
@onready var input : PlayerInputComponent = root.input
@export var button_rect : TextureRect
@export var anim_player : AnimationPlayer
@export var flash_anim : AnimationPlayer
@export var motion_anim : AnimationPlayer

@export_category("Button Textures")
@export var button_1_texture : Texture2D
@export var button_2_texture : Texture2D
@export var button_3_texture : Texture2D
@export var button_4_texture : Texture2D

@export_category("Settings")
@export_enum("actionButton1", "actionButton2", "actionButton3", "actionButton4", "dPadUp", "dPadDown", "dPadRight", "dPadLeft") var action_name : String = "choose a button"
@export var available_tint : Color = Color(1, 1, 1, 1)
@export var unavailable_tint : Color = Color(0.5, 0.5, 0.5, 0.5)
@export var spell_texture_rect : TextureRect
@export var flip_spell_pos : bool = false:
	set(value):
		flip_spell_pos = value
		_apply_spell_position()

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _current_spell : MenuItemResource = null
var _equipped_spells : EquippedSpellsComponent = null
var _my_slot : int = -1
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	if input:
		if debug_me:
			print_rich(debug_name, ": [color=green][i]got input component[/i][/color] for button [b]", action_name, "[/b]")
		SignalUtil.safe_connect(input, "action_button_pressed", Callable(self, "_on_action_button_pressed"))
		set_available(true)
	else:
		if debug_me:
			print_rich(debug_name, ": [color=red][i]could not get input component[/i][/color] for button [b]", action_name, "[/b]")
	if spell_texture_rect and not _current_spell:
		spell_texture_rect.visible = false
	if debug_me:
		print_rich(debug_name, ": [b]", action_name, "[/b] _ready() hid spell_texture_rect. _current_spell=[i]", _current_spell, "[/i]")
	_apply_spell_position()
	_assign_button_texture()

func _on_action_button_pressed(btn : String):
	if btn == action_name:
		_play_press_anim()

func _play_press_anim():
	if anim_player:
		var anim_to_play : String = "actionButton_press"
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

func set_equipped_spells(equipped_spells : EquippedSpellsComponent, slot_index : int) -> void:
	_equipped_spells = equipped_spells
	_my_slot = slot_index
	if _equipped_spells:
		SignalUtil.safe_connect(_equipped_spells, "spell_equip_changed", Callable(self, "_on_spell_equip_changed"))
	_current_spell = _equipped_spells.get_spell(_my_slot) if _equipped_spells else null
	if debug_me:
		print_rich(debug_name, ": [b]", action_name, "[/b] set_equipped_spells called. slot=[i]", _my_slot, "[/i] _current_spell=[i]", _current_spell, "[/i]")
	_update_spell_display()

func _on_spell_equip_changed(slot : int, spell_resource : MenuItemResource) -> void:
	if slot != _my_slot:
		return
	_current_spell = spell_resource
	_update_spell_display()

func _update_spell_display() -> void:
	if debug_me:
		print_rich(debug_name, ": [b]", action_name, "[/b] _update_spell_display called.")
		print_rich("  spell_texture_rect=[i]", spell_texture_rect, "[/i]")
		print_rich("  _current_spell=[i]", _current_spell, "[/i]")
		if spell_texture_rect:
			print_rich("  BEFORE visible=[i]", spell_texture_rect.visible, "[/i] texture=[i]", spell_texture_rect.texture, "[/i]")
	if not spell_texture_rect:
		return
	if _current_spell and _current_spell.mini_icon:
		spell_texture_rect.visible = true
		spell_texture_rect.texture = _current_spell.mini_icon
	else:
		spell_texture_rect.visible = false
	if debug_me:
		print_rich("  AFTER visible=[i]", spell_texture_rect.visible, "[/i] texture=[i]", spell_texture_rect.texture, "[/i]")
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

func reset_anims() -> void:
	if motion_anim and motion_anim.is_playing():
		motion_anim.stop()
	if flash_anim and flash_anim.is_playing():
		flash_anim.stop()

func _apply_spell_position() -> void:
	if not spell_texture_rect:
		return
	spell_texture_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	spell_texture_rect.size = spell_texture_rect.texture.get_size() if spell_texture_rect.texture else Vector2(16, 16)
	if flip_spell_pos:
		spell_texture_rect.position = Vector2(0, 10)
	else:
		spell_texture_rect.position = Vector2(7, 10)

#endregion FUNCTIONS
