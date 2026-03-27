##[b][color=red]MagicComponent[/color][/b] handles the magic values for a character.[br]
##Magic is tracked in shards — every 6 shards forms a complete medallion.[br]
##Max magic equals total shards collected. Each medallion holds up to 6 magic.[br]
##Recovers over time with a configurable delay and tick rate.
class_name MagicComponent
extends Component

#region SIGNALS

##Emitted when magic changes.[br]
##[b]cur_magic[/b]: Current magic after the change.[br]
##[b]max_magic[/b]: Maximum possible magic (total shards).[br]
##[b]change_amount[/b]: How much magic changed (negative = consumed, positive = restored).
signal magicChanged(cur_magic : int, max_magic : int, change_amount : int)

##Emitted when a new shard is collected.[br]
##[b]total_shards[/b]: Total shards after collection.
signal shardCollected(total_shards : int)

#endregion SIGNALS

#region VARIABLES

@export_category("Magic Settings")
@export_group("Shard Configuration")
##The total number of magic shards the character starts with.[br]
##6 shards = 1 complete medallion. Max magic = total shards.
@export var starting_shards : int = 6

@export_group("Recovery")
##How long after the last magic use before recovery begins (in seconds).
@export var recovery_delay : float = 3.0
##How much magic recovers per tick.
@export var recovery_amount : int = 1
##How often magic recovers (in seconds per tick).
@export var recovery_interval : float = 0.75

##Total shards collected. Determines medallion layout and max magic.
var total_shards : int = 6
##Maximum magic value (equals total_shards).
var max_magic : int = 6
##Current magic value.
var cur_magic : int = 6:
	set(value):
		var new_magic = clampi(value, 0, max_magic)
		var change_amount = new_magic - cur_magic
		cur_magic = new_magic
		if change_amount != 0:
			magicChanged.emit(cur_magic, max_magic, change_amount)

#=======INTERNAL VARIABLES=======#

##Timer that counts down after last magic use before recovery begins.
var _recovery_delay_timer : Timer
##Timer that ticks at recovery_interval to restore magic.
var _recovery_tick_timer : Timer

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	total_shards = starting_shards
	max_magic = total_shards
	cur_magic = max_magic
	#Create recovery timers.
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
		print(debug_name, " initialized with ", total_shards, " shards (", max_magic, " max magic).")

##Consumes the specified amount of magic.[br]
##Returns [b]true[/b] if there was enough magic, [b]false[/b] if not.
func consume(amount : int) -> bool:
	if cur_magic < amount:
		if debug_me:
			print(debug_name, ": Not enough magic! Have ", cur_magic, ", need ", amount)
		return false
	self.cur_magic -= amount
	_recovery_tick_timer.stop()
	_recovery_delay_timer.stop()
	_recovery_delay_timer.start(recovery_delay)
	if debug_me:
		print(debug_name, ": Consumed ", amount, " magic. Remaining: ", cur_magic)
	return true

##Restores the specified amount of magic.
func restore(amount : int) -> void:
	self.cur_magic += amount
	if debug_me:
		print(debug_name, ": Restored ", amount, " magic. Current: ", cur_magic)

##Adds a shard, increasing max magic by 1 and restoring that 1 point.
func collect_shard() -> void:
	total_shards += 1
	max_magic = total_shards
	self.cur_magic += 1
	shardCollected.emit(total_shards)
	if debug_me:
		print(debug_name, ": Collected shard! Total: ", total_shards, " Max magic: ", max_magic)

##Returns the number of complete medallions (6 shards each).
func get_complete_medallion_count() -> int:
	return int(total_shards / 6.0)

##Returns how many shards are in the incomplete/partial medallion (0-5).[br]
##Returns 0 if all medallions are complete.
func get_partial_medallion_shards() -> int:
	return total_shards % 6

##Returns the total number of medallions to display (complete + partial if partial > 0).
func get_medallion_count() -> int:
	var count = get_complete_medallion_count()
	if get_partial_medallion_shards() > 0:
		count += 1
	return count

##Returns whether magic is at maximum.
func is_full() -> bool:
	return cur_magic >= max_magic

##Recovery timer callbacks.
func _on_recovery_delay_finished() -> void:
	if not is_full():
		_recovery_tick_timer.start(recovery_interval)
		if debug_me:
			print(debug_name, ": Recovery started.")

func _on_recovery_tick() -> void:
	if is_full():
		_recovery_tick_timer.stop()
		if debug_me:
			print(debug_name, ": Recovery complete. Magic is full.")
		return
	restore(recovery_amount)
	if debug_me:
		print(debug_name, ": Recovered ", recovery_amount, ". Current: ", cur_magic)
	if is_full():
		_recovery_tick_timer.stop()
		if debug_me:
			print(debug_name, ": Recovery complete. Magic is full.")

##Debug input for testing magic changes.[br]
##Numpad 7 to restore, Numpad 1 to consume.
func _unhandled_input(event : InputEvent):
	if debug_me:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_KP_7:
				restore(1)
			elif event.keycode == KEY_KP_1:
				consume(1)

#endregion FUNCTIONS
