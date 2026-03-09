##[b][color=red]CurrencyComponent[/color][/b] tracks the player's notes (currency).[br]
##Supports an expandable maximum (wallet upgrades) and signals on change.
class_name CurrencyComponent
extends Component

#region SIGNALS

##Emitted when currency changes.[br]
##[b]cur_notes[/b]: Current notes after the change.[br]
##[b]max_notes[/b]: Maximum possible notes.[br]
##[b]change_amount[/b]: How much changed (negative = spent, positive = gained).
signal notesChanged(cur_notes : int, max_notes : int, change_amount : int)

#endregion SIGNALS

#region VARIABLES

@export_category("Currency Settings")
##The maximum number of notes the player can carry.[br]
##Can be increased by wallet upgrades.
@export var max_notes : int = 99
##The starting number of notes.
@export var starting_notes : int = 0

##The current number of notes.
var cur_notes : int = 0:
	set(value):
		var new_notes = clampi(value, 0, max_notes)
		var change_amount = new_notes - cur_notes
		cur_notes = new_notes
		if change_amount != 0:
			notesChanged.emit(cur_notes, max_notes, change_amount)

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	cur_notes = clampi(starting_notes, 0, max_notes)
	if debug_me:
		print(debug_name, " initialized with ", cur_notes, "/", max_notes, " notes.")

##Adds notes to the player's currency.[br]
##Returns [b]true[/b] if any notes were added, [b]false[/b] if already at max.
func add(amount : int) -> bool:
	if cur_notes >= max_notes:
		if debug_me:
			print(debug_name, ": Already at max notes!")
		return false
	self.cur_notes += amount
	if debug_me:
		print(debug_name, ": Added ", amount, " notes. Current: ", cur_notes)
	return true

##Spends notes. Returns [b]true[/b] if enough notes were available, [b]false[/b] if not.
func spend(amount : int) -> bool:
	if cur_notes < amount:
		if debug_me:
			print(debug_name, ": Not enough notes! Have ", cur_notes, ", need ", amount)
		return false
	self.cur_notes -= amount
	if debug_me:
		print(debug_name, ": Spent ", amount, " notes. Current: ", cur_notes)
	return true

##Returns whether the player has max notes.
func is_full() -> bool:
	return cur_notes >= max_notes

##Upgrades the maximum note capacity (wallet upgrade).
func upgrade_max(new_max : int) -> void:
	max_notes = new_max
	if debug_me:
		print(debug_name, ": Max notes upgraded to ", max_notes)

##Debug input for testing.[br]
##Numpad 9 to add, Numpad 3 to spend.
func _unhandled_input(event : InputEvent):
	if debug_me:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_KP_9:
				add(1)
			elif event.keycode == KEY_KP_3:
				spend(1)

#endregion FUNCTIONS
