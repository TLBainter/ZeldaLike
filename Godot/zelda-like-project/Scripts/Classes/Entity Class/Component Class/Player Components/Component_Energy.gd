@icon("res://Editor Tools/Icons/icon_energy.svg")
##[b][color=red]EnergyComponent[/color][/b] handles the energy (stamina) values of a character.[br]
##Sends signals on change, manages current/maximum energy, and handles consumption/recovery.[br]
##Replaces the previous StaminaComponent.
class_name EnergyComponent
extends RecoverableResourceComponent

#region SIGNALS

##Emitted when energy changes.[br]
##[b]cur_energy[/b]: Current energy after the change.[br]
##[b]max_energy[/b]: Maximum possible energy.[br]
##[b]change_amount[/b]: How much energy changed (negative = consumed, positive = restored).
signal energy_changed(cur_energy : int, max_energy : int, change_amount : int)

##Emitted when max energy increases.[br]
##[b]max_energy[/b]: New maximum energy.[br]
##[b]cur_energy[/b]: Current energy after the increase.
signal max_energy_changed(max_energy : int, cur_energy : int)

#endregion SIGNALS

#region VARIABLES

@export_category("Energy Settings")
@export_group("Bolt Configuration")
## Derived from stats resource (max_energy / 4). Set at runtime.
var max_bolts : int = 1

@export_group("Costs")
##How much energy a dash consumes.
@export var dash_cost : int = 1

##The maximum energy value, calculated from max_bolts.
var max_energy : int = 4
##The current energy value.
var cur_energy : int = 4:
	set(value):
		var new_energy = clampi(value, 0, max_energy)
		var change_amount = new_energy - cur_energy
		cur_energy = new_energy
		if change_amount != 0:
			energy_changed.emit(cur_energy, max_energy, change_amount)
##Whether you are currently exhausted
var is_exhausted_state : bool = false

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	var stats = _get_entity_stats()
	if stats:
		max_energy = stats.max_energy
		_debug_log(str("Read max_energy=", max_energy, " from StatsResource."))
	else:
		max_energy = max_bolts * 4
		_debug_log(str("No StatsResource found. Defaulting max_energy=", max_energy))
	max_bolts = int(max_energy / 4.0)
	cur_energy = max_energy
	_setup_recovery_timers()
	_debug_log(str("initialized with ", max_bolts, " bolts (", max_energy, " max energy)."))

func increase_max(amount: int) -> void:
	max_energy += amount
	max_bolts = int(max_energy / 4.0)
	self.cur_energy += amount
	max_energy_changed.emit(max_energy, cur_energy)

##Consumes the specified amount of energy.[br]
##Returns [b]true[/b] if there was enough energy, [b]false[/b] if not (does not consume if insufficient).
func consume(amount : int) -> bool:
	if is_exhausted_state:
		_debug_log("Cannot consume while exhausted!")
		return false
	if cur_energy < amount:
		_debug_log(str("Not enough energy! Have ", cur_energy, ", need ", amount))
		return false
	if (cur_energy - amount) <= 0:
		is_exhausted_state = true
	self.cur_energy -= amount
	_start_recovery_countdown()
	_debug_log(str("Consumed ", amount, " energy. Remaining: ", cur_energy))
	return true

##Restores the specified amount of energy.
func restore(amount : int):
	var will_be_full = (cur_energy + amount) >= max_energy
	if will_be_full and is_exhausted_state:
		is_exhausted_state = false
		_debug_log("No longer exhausted.")
	self.cur_energy += amount
	_debug_log(str("Restored ", amount, " energy. Current: ", cur_energy))

##Returns whether the character is exhausted (0 energy).
func is_exhausted() -> bool:
	return cur_energy <= 0

##Returns whether energy is at maximum.
func is_full() -> bool:
	return cur_energy >= max_energy

##Debug input for testing energy changes.[br]
##Numpad 6 to restore, Numpad 4 to consume.
func _unhandled_input(event : InputEvent):
	if debug_me:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_KP_6:
				restore(1)
			elif event.keycode == KEY_KP_4:
				consume(1)

func _is_resource_full() -> bool: return is_full()
func _restore_one_tick() -> void: restore(recovery_amount)
func _on_recovery_complete() -> void:
	if is_exhausted_state:
		is_exhausted_state = false
		_debug_log("No longer exhausted.")
	_debug_log("Recovery complete. Energy is full.")

#endregion FUNCTIONS
