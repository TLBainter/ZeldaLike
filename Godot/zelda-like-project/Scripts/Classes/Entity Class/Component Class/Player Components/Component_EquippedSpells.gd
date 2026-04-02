##[b][color=red]SpellSlotManager[/color][/b] tracks spell assignments to action buttons.[br]
##Each slot (1, 2, 3) can hold one MenuItemResource representing a spell.[br]
class_name EquippedSpellsComponent
extends Component

#region SIGNALS

##Emitted when a spell is assigned or unassigned from a slot.[br]
##[b]slot[/b]: The action button index (1, 2, or 3).[br]
##[b]spell_resource[/b]: The MenuItemResource, or null if unassigned.
signal spell_equip_changed(slot : int, spell_resource : MenuItemResource)

#endregion SIGNALS

#region VARIABLES

#=======INTERNAL VARIABLES=======#

##Spell assignments. Format: { slot_index : MenuItemResource }
var _slots : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

##Assigns a spell to a slot. Returns true if assignment changed.
func assign_spell(slot : int, spell_resource : MenuItemResource) -> bool:
	if slot < 1 or slot > 3:
		return false
	if _slots.get(slot) == spell_resource:
		#Already assigned here — do nothing.
		return false
	_slots[slot] = spell_resource
	spell_equip_changed.emit(slot, spell_resource)
	if debug_me:
		var spell_name = spell_resource.name if spell_resource else "null"
		print(debug_name, ": Slot ", slot, " assigned to ", spell_name)
	return true

##Unassigns a spell from a slot.
func unassign_spell(slot : int) -> void:
	if _slots.has(slot):
		_slots.erase(slot)
		spell_equip_changed.emit(slot, null)
		if debug_me:
			print(debug_name, ": Slot ", slot, " cleared.")

##Returns the spell assigned to a slot, or null.
func get_spell(slot : int) -> MenuItemResource:
	return _slots.get(slot, null)

##Returns the slot index (1-3) a spell is assigned to, or -1 if not assigned.
func get_slot_for_spell(item_id : String) -> int:
	for slot in _slots:
		var resource = _slots[slot]
		if resource and resource.item_id == item_id:
			return slot
	return -1

##Swaps the spells in two slots.
func swap_spells(slot_a : int, slot_b : int) -> void:
	var spell_a = _slots.get(slot_a, null)
	var spell_b = _slots.get(slot_b, null)
	if spell_a:
		_slots[slot_a] = spell_b if spell_b else null
	else:
		_slots.erase(slot_a)
	if spell_b:
		_slots[slot_b] = spell_a if spell_a else null
	else:
		_slots.erase(slot_b)
	#Clean up null entries.
	if _slots.has(slot_a) and _slots[slot_a] == null:
		_slots.erase(slot_a)
	if _slots.has(slot_b) and _slots[slot_b] == null:
		_slots.erase(slot_b)
	spell_equip_changed.emit(slot_a, get_spell(slot_a))
	spell_equip_changed.emit(slot_b, get_spell(slot_b))
	if debug_me:
		print(debug_name, ": Swapped slot ", slot_a, " and slot ", slot_b)

##Returns a copy of all current assignments.
func get_all_assignments() -> Dictionary:
	return _slots.duplicate()

#endregion FUNCTIONS
