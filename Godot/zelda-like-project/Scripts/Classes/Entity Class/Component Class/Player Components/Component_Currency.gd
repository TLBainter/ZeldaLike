##[b][color=red]CurrencyComponent[/color][/b] tracks the player's notes (currency).[br]
##Supports an expandable maximum (wallet upgrades) and signals on change.
class_name CurrencyComponent
extends Component

#region SIGNALS

##Emitted when currency changes.[br]
##[b]cur_notes[/b]: Current notes after the change.[br]
##[b]max_notes[/b]: Maximum possible notes.[br]
##[b]change_amount[/b]: How much changed (negative = spent, positive = gained).
signal notes_changed(cur_notes : int, max_notes : int, change_amount : int)

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
			notes_changed.emit(cur_notes, max_notes, change_amount)

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	cur_notes = clampi(starting_notes, 0, max_notes)
	if textResolver:
		textResolver.register_category("cur", _resolve_text)
	if debug_me:
		print_rich(debug_name, ": [color=green][i]initialized[/i][/color] with [i]", cur_notes, "/", max_notes, "[/i] notes.")

##Calls the text resolver autoload for parsing of text.
func _resolve_text(key : String):
	match key:
		"currency": return cur_notes
		"max": return max_notes
		"difference": return max_notes - cur_notes
		"wallet":
			if max_notes <= 99: return "Pocket"
			elif max_notes <= 999: return "Wallet"
			else: return "Big Wallet"
	return null

##Adds notes to the player's currency.[br]
##Returns [b]true[/b] if any notes were added, [b]false[/b] if already at max.
func add(amount : int) -> bool:
	if cur_notes >= max_notes:
		if debug_me:
			print_rich(debug_name, ": [color=red][i]already at max notes[/i][/color]!")
		return false
	self.cur_notes += amount
	if debug_me:
		print_rich(debug_name, ": [color=green][i]added[/i][/color] [i]", amount, "[/i] notes. Current: [i]", cur_notes, "[/i]")
	return true

##Spends notes. Returns [b]true[/b] if enough notes were available, [b]false[/b] if not.
func spend(amount : int) -> bool:
	if cur_notes < amount:
		if debug_me:
			print_rich(debug_name, ": [color=red][i]not enough notes[/i][/color]! Have [i]", cur_notes, "[/i], need [i]", amount, "[/i]")
		return false
	self.cur_notes -= amount
	if debug_me:
		print_rich(debug_name, ": [color=red][i]spent[/i][/color] [i]", amount, "[/i] notes. Current: [i]", cur_notes, "[/i]")
	return true

##Returns whether the player has max notes.
func is_full() -> bool:
	return cur_notes >= max_notes

##Upgrades the maximum note capacity (wallet upgrade).
func upgrade_max(new_max : int) -> void:
	max_notes = new_max
	if debug_me:
		print_rich(debug_name, ": [color=green][i]max notes upgraded[/i][/color] to [i]", max_notes, "[/i]")

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
