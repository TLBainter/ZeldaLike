##[b][color=red]ItemUseComponent[/color][/b] is the base component for using items on the player.[br]
##Handles applying immediate and ongoing effects from an [b]ItemFunction[/b] resource[br]
##to the player's health, energy, and magic components.[br]
##[br]
##Subclasses: [b]ConcoctionItemUse[/b].
class_name ItemUseComponent
extends Component

#region SIGNALS

##Emitted when an item is successfully used.
signal item_used(item_id : String)
##Emitted when an ongoing effect starts.
signal ongoing_effect_started(item_id : String, duration : float)
##Emitted when an ongoing effect ends.
signal ongoing_effect_ended(item_id : String)

#endregion SIGNALS

#region VARIABLES

@export_category("Item Use Components")
##The player's health component.
@export var health_comp : Node ## PlayerHealthComponent
##The player's energy component.
@export var energy_comp : EnergyComponent
##The player's magic component.
@export var magic_comp : MagicComponent

#=======INTERNAL VARIABLES=======#

##Currently active ongoing effects.[br]
##Format: { "item_id" : { "timer": Timer, "tickers": Array[Timer] } }
var _active_effects : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

##Applies all effects from an ItemFunction resource.[br]
##Returns true if effects were applied, false if blocked.
func apply_effects(item_function : ItemFunction, item_id : String = "") -> bool:
	if not item_function:
		if debug_me:
			print(debug_name, ": No item function to apply!")
		return false
	#Apply immediate effects.
	for effect in item_function.immediate_effects:
		_apply_single_effect(effect.action, effect.amount, effect.target)
	if debug_me and not item_function.immediate_effects.is_empty():
		print(debug_name, ": Applied ", item_function.immediate_effects.size(), " immediate effects.")
	#Start ongoing effects if any.
	if item_function.has_ongoing_effects():
		_start_ongoing_effects(item_function, item_id)
	item_used.emit(item_id)
	return true

#region APPLY EFFECTS

##Applies a single effect to the appropriate player component.
func _apply_single_effect(action : EffectEnums.EffectAction, amount : int, target : EffectEnums.EffectTarget) -> void:
	match target:
		EffectEnums.EffectTarget.HEALTH:
			_apply_to_health(action, amount)
		EffectEnums.EffectTarget.ENERGY:
			_apply_to_energy(action, amount)
		EffectEnums.EffectTarget.MAGIC:
			_apply_to_magic(action, amount)

func _apply_to_health(action : EffectEnums.EffectAction, amount : int) -> void:
	if not health_comp:
		return
	if action == EffectEnums.EffectAction.ADD:
		health_comp.healed(amount)
		if debug_me:
			print(debug_name, ": Healed ", amount, " health.")
	else:
		health_comp.damaged(amount)
		if debug_me:
			print(debug_name, ": Dealt ", amount, " damage.")

func _apply_to_energy(action : EffectEnums.EffectAction, amount : int) -> void:
	if not energy_comp:
		return
	if action == EffectEnums.EffectAction.ADD:
		energy_comp.restore(amount)
		if debug_me:
			print(debug_name, ": Restored ", amount, " energy.")
	else:
		energy_comp.consume(amount)
		if debug_me:
			print(debug_name, ": Consumed ", amount, " energy.")

func _apply_to_magic(action : EffectEnums.EffectAction, amount : int) -> void:
	if not magic_comp:
		return
	if action == EffectEnums.EffectAction.ADD:
		magic_comp.restore(amount)
		if debug_me:
			print(debug_name, ": Restored ", amount, " magic.")
	else:
		magic_comp.consume(amount)
		if debug_me:
			print(debug_name, ": Consumed ", amount, " magic.")

#endregion APPLY EFFECTS

#region ONGOING EFFECTS

##Starts all ongoing effects from an ItemFunction, with tick timers and a duration timer.
func _start_ongoing_effects(item_function : ItemFunction, item_id : String) -> void:
	#Stop existing effects for this item if not stackable.
	if item_function is ItemFunctionConsumable and not item_function.stackable:
		if _active_effects.has(item_id):
			_stop_ongoing_effects(item_id)
	if item_function.ongoing_effects.is_empty():
		return
	#Create tick timers for each ongoing effect.
	var tickers : Array[Timer] = []
	for effect in item_function.ongoing_effects:
		var tick_timer = Timer.new()
		tick_timer.wait_time = effect.interval
		tick_timer.one_shot = false
		tick_timer.timeout.connect(_on_ongoing_tick.bind(effect.action, effect.amount, effect.target))
		add_child(tick_timer)
		tick_timer.start()
		tickers.append(tick_timer)
	#Create a duration timer to stop all tickers when the effect expires.
	var duration_timer = Timer.new()
	duration_timer.wait_time = item_function.ongoing_duration
	duration_timer.one_shot = true
	duration_timer.timeout.connect(_on_ongoing_expired.bind(item_id))
	add_child(duration_timer)
	duration_timer.start()
	_active_effects[item_id] = {
		"timer": duration_timer,
		"tickers": tickers,
	}
	ongoing_effect_started.emit(item_id, item_function.ongoing_duration)
	if debug_me:
		print(debug_name, ": Started ", tickers.size(), " ongoing effects for ", item_id, " (", item_function.ongoing_duration, "s)")

##Called each tick of an ongoing effect.
func _on_ongoing_tick(action : EffectEnums.EffectAction, amount : int, target : EffectEnums.EffectTarget) -> void:
	_apply_single_effect(action, amount, target)

##Called when an ongoing effect's duration expires.
func _on_ongoing_expired(item_id : String) -> void:
	_stop_ongoing_effects(item_id)

##Stops and cleans up all ongoing effects for a given item_id.
func _stop_ongoing_effects(item_id : String) -> void:
	if not _active_effects.has(item_id):
		return
	var data = _active_effects[item_id]
	#Stop and free all tick timers.
	for ticker in data["tickers"]:
		if is_instance_valid(ticker):
			ticker.stop()
			ticker.queue_free()
	#Stop and free the duration timer.
	if is_instance_valid(data["timer"]):
		data["timer"].stop()
		data["timer"].queue_free()
	_active_effects.erase(item_id)
	ongoing_effect_ended.emit(item_id)
	if debug_me:
		print(debug_name, ": Ongoing effects ended for ", item_id)

##Returns whether an ongoing effect is currently active for the given item_id.
func has_active_effect(item_id : String) -> bool:
	return _active_effects.has(item_id)

#endregion ONGOING EFFECTS

#endregion FUNCTIONS
