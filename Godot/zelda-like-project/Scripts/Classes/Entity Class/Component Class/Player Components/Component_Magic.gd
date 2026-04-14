@icon("res://Editor Tools/Icons/icon_magic.svg")
##[b][color=red]MagicComponent[/color][/b] handles the magic values for a character.[br]
##Magic is tracked in shards -- every 6 shards forms a complete medallion.[br]
##Max magic equals total shards collected. Each medallion holds up to 6 magic.[br]
##Recovers over time with a configurable delay and tick rate.
class_name MagicComponent
extends RecoverableResourceComponent

#region SIGNALS

##Emitted when magic changes.[br]
##[b]cur_magic[/b]: Current magic after the change.[br]
##[b]max_magic[/b]: Maximum possible magic (total shards).[br]
##[b]change_amount[/b]: How much magic changed (negative = consumed, positive = restored).
signal magic_changed(cur_magic : int, max_magic : int, change_amount : int)

##Emitted when a new shard is collected.[br]
##[b]total_shards[/b]: Total shards after collection.
signal shard_collected(total_shards : int)

#endregion SIGNALS

#region VARIABLES

@export_category("Magic Settings")
@export_group("Shard Configuration")
## Starting shards. Read from stats resource at runtime. Defaults to 6.
var starting_shards : int = 6

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
			magic_changed.emit(cur_magic, max_magic, change_amount)

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	var stats = _get_entity_stats()
	total_shards = stats.max_magic if stats else starting_shards
	max_magic = total_shards
	cur_magic = max_magic
	_setup_recovery_timers()
	_debug_log(str("initialized with ", total_shards, " shards (", max_magic, " max magic)."))

##Consumes the specified amount of magic.[br]
##Returns [b]true[/b] if there was enough magic, [b]false[/b] if not.
func consume(amount : int) -> bool:
	if cur_magic < amount:
		_debug_log(str("Not enough magic! Have ", cur_magic, ", need ", amount))
		return false
	self.cur_magic -= amount
	_start_recovery_countdown()
	_debug_log(str("Consumed ", amount, " magic. Remaining: ", cur_magic))
	return true

##Restores the specified amount of magic.
func restore(amount : int) -> void:
	self.cur_magic += amount
	_debug_log(str("Restored ", amount, " magic. Current: ", cur_magic))

##Adds a shard, increasing max magic by 1 and restoring that 1 point.
func collect_shard() -> void:
	total_shards += 1
	max_magic = total_shards
	self.cur_magic += 1
	shard_collected.emit(total_shards)
	_debug_log(str("Collected shard! Total: ", total_shards, " Max magic: ", max_magic))

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

func _is_resource_full() -> bool: return is_full()
func _restore_one_tick() -> void: restore(recovery_amount)
func _on_recovery_complete() -> void: _debug_log("Recovery complete. Magic is full.")

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
