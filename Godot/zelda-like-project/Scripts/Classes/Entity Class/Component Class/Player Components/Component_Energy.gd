##[b][color=red]EnergyComponent[/color][/b] handles the energy (stamina) values of a character.[br]
##Sends signals on change, manages current/maximum energy, and handles consumption/recovery.[br]
##Replaces the previous StaminaComponent.
class_name EnergyComponent
extends Component

#region SIGNALS

##Emitted when energy changes.[br]
##[b]cur_energy[/b]: Current energy after the change.[br]
##[b]max_energy[/b]: Maximum possible energy.[br]
##[b]change_amount[/b]: How much energy changed (negative = consumed, positive = restored).
signal energyChanged(cur_energy : int, max_energy : int, change_amount : int)

#endregion SIGNALS

#region VARIABLES

@export_category("Energy Settings")
@export_group("Bolt Configuration")
## Derived from stats resource (max_energy / 4). Set at runtime.
var max_bolts : int = 1

@export_group("Recovery")
##How long after the last energy use before recovery begins (in seconds).
@export var recovery_delay : float = 2.0
##How much energy recovers per tick.
@export var recovery_amount : int = 1
##How often energy recovers (in seconds per tick).
@export var recovery_interval : float = 0.5

@export_group("Costs")
##How much energy a roll consumes.
@export var roll_cost : int = 4

##The maximum energy value, calculated from max_bolts.
var max_energy : int = 4
##The current energy value.
var cur_energy : int = 4:
	set(value):
		var new_energy = clampi(value, 0, max_energy)
		var change_amount = new_energy - cur_energy
		cur_energy = new_energy
		if change_amount != 0:
			energyChanged.emit(cur_energy, max_energy, change_amount)
##Timer for counting down after last energy use before recovery begins.
var _recovery_delay_timer : Timer
##Timer that ticks at recovery_interval to restore energy.
var _recovery_tick_timer : Timer
##Whether you are currently exhausted
var is_exhausted_state : bool = false

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	var entity = get_parent()
	if entity and "stats" in entity and entity.stats and entity.stats.resource:
		max_energy = entity.stats.resource.max_energy
	else:
		max_energy = max_bolts * 4
	max_bolts = int(max_energy / 4.0)
	cur_energy = max_energy
	#Create and manager timers for energy recovery
	_recovery_delay_timer = Timer.new()
	_recovery_delay_timer.one_shot = true
	_recovery_delay_timer.wait_time = recovery_delay
	_recovery_delay_timer.timeout.connect(_on_recovery_delay_finished)
	add_child(_recovery_delay_timer)
	_recovery_tick_timer = Timer.new()
	_recovery_tick_timer.one_shot = false
	_recovery_tick_timer.wait_time = recovery_interval
	_recovery_tick_timer.timeout.connect(_on_recovery_tick)
	add_child(_recovery_tick_timer)
	if debug_me:
		print(debug_name, " initialized with ", max_bolts, " bolts (", max_energy, " max energy).")

##Consumes the specified amount of energy.[br]
##Returns [b]true[/b] if there was enough energy, [b]false[/b] if not (does not consume if insufficient).
func consume(amount : int) -> bool:
	if is_exhausted_state:
		if debug_me:
			print(debug_name, ": Cannot consume while exhausted!")
		return false
	if cur_energy < amount:
		if debug_me:
			print(debug_name, ": Not enough energy! Have ", cur_energy, ", need ", amount)
		return false
	if (cur_energy - amount) <= 0:
		is_exhausted_state = true
	self.cur_energy -= amount
	_recovery_tick_timer.stop()
	_recovery_delay_timer.stop()
	_recovery_delay_timer.start(recovery_delay)
	if debug_me:
		print(debug_name, ": Consumed ", amount, " energy. Remaining: ", cur_energy)
	return true

##Restores the specified amount of energy.
func restore(amount : int):
	var will_be_full = (cur_energy + amount) >= max_energy
	if will_be_full and is_exhausted_state:
		is_exhausted_state = false
		if debug_me:
			print(debug_name, ": No longer exhausted.")
	self.cur_energy += amount
	if debug_me:
		print(debug_name, ": Restored ", amount, " energy. Current: ", cur_energy)

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

##Called when the delay after last energy use has elapsed. Starts the recovery ticks.
func _on_recovery_delay_finished():
	if not is_full():
		_recovery_tick_timer.start(recovery_interval)
		if debug_me:
			print(debug_name, ": Recovery started.")

##Called each recovery tick. Restores energy and stops when full.
func _on_recovery_tick():
	if is_full():
		_recovery_tick_timer.stop()
		if is_exhausted_state:
			is_exhausted_state = false
			if debug_me:
				print(debug_name, ": No longer exhausted.")
		if debug_me:
			print(debug_name, ": Recovery complete. Energy is full.")
		return
	restore(recovery_amount)
	if debug_me:
		print(debug_name, ": Recovered ", recovery_amount, ". Current: ", cur_energy)
	if is_full():
		_recovery_tick_timer.stop()
		if debug_me:
			print(debug_name, ": Recovery complete. Energy is full.")

#endregion FUNCTIONS
