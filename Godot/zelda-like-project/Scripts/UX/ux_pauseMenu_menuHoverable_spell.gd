##[b][color=red]MenuHoverableSpell[/color][/b] extends [b]MenuHoverableItem[/b] for spell inventory panels.[br]
##Instead of quantity, displays the assigned action button's sprite.[br]
##While hovered, pressing action buttons 1-3 assigns/swaps spells.[br]
@tool
class_name MenuHoverableSpell
extends MenuHoverableItem

#region VARIABLES


##Reference to the SpellSlotManager. Set at runtime.
var _equipped_spells : EquippedSpellsComponent = null

#endregion VARIABLES

#region FUNCTIONS

##Sets the spell slot manager reference and updates display.
func set_equipped_spells(equipped_spells : EquippedSpellsComponent) -> void:
	_equipped_spells = equipped_spells
	if _equipped_spells:
		SignalUtil.safe_connect(_equipped_spells, "spell_equip_changed", Callable(self, "_on_spell_equip_changed"))
	_update_assignment_display()

#region ASSIGNMENT DISPLAY

##Updates the assignment TextureRect based on current spell slot data.
func _update_assignment_display() -> void:
	if not assignment_rect:
		return
	if not _equipped_spells or not item_resource or item_resource.item_id.is_empty():
		assignment_rect.visible = false
		return
	var slot = _equipped_spells.get_slot_for_spell(item_resource.item_id)
	if slot == -1:
		assignment_rect.visible = false
	else:
		assignment_rect.visible = true
		assignment_rect.texture = _get_button_sprite(slot)

##Returns the button sprite for a given slot index.
func _get_button_sprite(slot : int) -> Texture2D:
	match slot:
		1: return button_1_sprite
		2: return button_2_sprite
		3: return button_3_sprite
	return null

##Called when any spell slot changes. Updates display if relevant.
func _on_spell_equip_changed(_slot : int, _spell_resource : MenuItemResource) -> void:
	_update_assignment_display()

#endregion ASSIGNMENT DISPLAY

#region SPELL ASSIGNMENT

##Attempts to assign this spell to the given action button slot.[br]
##Handles all assignment/swap logic. Returns true if something changed.
func try_assign_to_slot(slot : int) -> bool:
	if not _equipped_spells or not item_resource or item_resource.item_id.is_empty():
		return false
	if not player_has_item:
		return false
	var current_slot = _equipped_spells.get_slot_for_spell(item_resource.item_id)
	if current_slot == slot:
		if debug_me:
			print(debug_name, ": Already assigned to button ", slot)
		return false
	var existing_in_target = _equipped_spells.get_spell(slot)
	if current_slot == -1:
		_equipped_spells.assign_spell(slot, item_resource)
		if debug_me:
			print(debug_name, ": Assigned to button ", slot)
		return true
	else:
		if existing_in_target == null:
			_equipped_spells.unassign_spell(current_slot)
			_equipped_spells.assign_spell(slot, item_resource)
			if debug_me:
				print(debug_name, ": Moved from button ", current_slot, " to button ", slot)
			return true
		else:
			_equipped_spells.swap_spells(current_slot, slot)
			if debug_me:
				print(debug_name, ": Swapped button ", current_slot, " with button ", slot)
			return true

#endregion SPELL ASSIGNMENT

#region HOVER OVERRIDES

func _on_hover() -> void:
	super._on_hover()
	_update_assignment_display()

func _on_unhover() -> void:
	super._on_unhover()
	_update_assignment_display()

#endregion HOVER OVERRIDES

#region QUANTITY OVERRIDE

##Spells don't show quantity -- hide the label entirely.
func _update_quantity() -> void:
	if quantity_label:
		quantity_label.visible = false

#endregion QUANTITY OVERRIDE

#endregion FUNCTIONS
