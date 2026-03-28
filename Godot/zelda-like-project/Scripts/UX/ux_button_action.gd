##[b][color=red]ActionButtonSprite[/color][/b] handles the visuals of a button in the UI.[br]
##Used for the action buttons (A/B/X/Y, Up, Down, Right, Left, etc.)
class_name ActionButtonSprite
extends ButtonSprite

#region VARIABLES
@export_category("Components")
##A reference to this button's animation player
@export var anim_player : AnimationPlayer
@export_category("Settings")
##The action name this sprite represents
@export_enum("actionButton1", "actionButton2", "actionButton3", "actionButton4", "dPadUp", "dPadDown", "dPadRight", "dPadLeft") var action_name : String = "choose a button"
##The tint to show the button as when available
@export var available_tint : Color = Color(1, 1, 1, 1)
##the tint and visibility to apply when the button is unavailable
@export var unavailable_tint : Color = Color(0.5, 0.5, 0.5, 0.5)
##The TextureRect for displaying the assigned spell's mini icon.
@export var spell_texture_rect : TextureRect

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
		modulate = available_tint
	else:
		modulate = unavailable_tint

#region Spell Setting===========#
func set_equipped_spells(equipped_spells : EquippedSpellsComponent, slot_index : int) -> void:
	_equipped_spells = equipped_spells
	_my_slot = slot_index
	if _equipped_spells and not _equipped_spells.spell_equip_changed.is_connected(_on_spell_equip_changed):
		_equipped_spells.spell_equip_changed.connect(_on_spell_equip_changed)
	_current_spell = _equipped_spells.get_spell(_my_slot) if _equipped_spells else null
	_update_spell_display()

func _on_spell_equip_changed(slot : int, spell_resource : MenuItemResource) -> void:
	if slot != _my_slot:
		return
	_current_spell = spell_resource
	_update_spell_display()

func _update_spell_display() -> void:
	if not spell_texture_rect:
		return
	if _current_spell and _current_spell.mini_icon:
		spell_texture_rect.visible = true
		spell_texture_rect.texture = _current_spell.mini_icon
	else:
		spell_texture_rect.visible = false
#endregion Spell Setting===========#

#endregion FUNCTIONS
