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
@export var health_comp : HealthComponent
##The player's energy component.
@export var energy_comp : EnergyComponent
##The player's magic component.
@export var magic_comp : MagicComponent

##Currently active ongoing effects.[br]
##Format: { "item_id" : { "timer": Timer, "tickers": Array[Timer] } }
var _active_effects : Dictionary = {}
##Registry of effect handlers keyed by EffectTarget.[br]
##Add new targets with [method register_effect_handler] instead of editing [method _apply_single_effect].
var _effect_handlers : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	_effect_handlers[EffectEnums.EffectTarget.HEALTH] = _apply_to_health
	_effect_handlers[EffectEnums.EffectTarget.ENERGY] = _apply_to_energy
	_effect_handlers[EffectEnums.EffectTarget.MAGIC] = _apply_to_magic

##Registers a handler callable for a given EffectTarget.[br]
##Callable signature: func(action: EffectEnums.EffectAction, amount: int) -> void[br]
##Call this to support new effect targets without editing this file.
func register_effect_handler(target: EffectEnums.EffectTarget, handler: Callable) -> void:
	_effect_handlers[target] = handler

##Applies all effects from an ItemFunction resource.[br]
##Returns true if effects were applied, false if blocked.
func apply_effects(item_function : ItemFunction, item_id : String = "") -> bool:
	if not item_function:
		if debug_me:
			print_rich(debug_name, ": [color=red][i]no item function to apply[/i][/color]!")
		return false
	for effect in item_function.immediate_effects:
		_apply_single_effect(effect.action, effect.amount, effect.target)
	if debug_me and not item_function.immediate_effects.is_empty():
		print_rich(debug_name, ": [color=green][i]applied[/i][/color] [i]", item_function.immediate_effects.size(), "[/i] immediate effects.")
	if item_function.has_ongoing_effects():
		_start_ongoing_effects(item_function, item_id)
	item_used.emit(item_id)
	return true

#region APPLY EFFECTS

##Applies a single effect to the appropriate player component.
func _apply_single_effect(action : EffectEnums.EffectAction, amount : int, target : EffectEnums.EffectTarget) -> void:
	if _effect_handlers.has(target):
		_effect_handlers[target].call(action, amount)

func _apply_to_health(action : EffectEnums.EffectAction, amount : int) -> void:
	if not health_comp:
		return
	if action == EffectEnums.EffectAction.ADD:
		health_comp.healed(amount)
		if debug_me:
			print_rich(debug_name, ": [color=green][i]healed[/i][/color] [i]", amount, "[/i] health.")
	else:
		health_comp.damaged(amount)
		if debug_me:
			print_rich(debug_name, ": [color=red][i]dealt[/i][/color] [i]", amount, "[/i] damage.")

func _apply_to_energy(action : EffectEnums.EffectAction, amount : int) -> void:
	if not energy_comp:
		return
	if action == EffectEnums.EffectAction.ADD:
		energy_comp.restore(amount)
		if debug_me:
			print_rich(debug_name, ": [color=green][i]restored[/i][/color] [i]", amount, "[/i] energy.")
	else:
		energy_comp.consume(amount)
		if debug_me:
			print_rich(debug_name, ": [color=red][i]consumed[/i][/color] [i]", amount, "[/i] energy.")

func _apply_to_magic(action : EffectEnums.EffectAction, amount : int) -> void:
	if not magic_comp:
		return
	if action == EffectEnums.EffectAction.ADD:
		magic_comp.restore(amount)
		if debug_me:
			print_rich(debug_name, ": [color=green][i]restored[/i][/color] [i]", amount, "[/i] magic.")
	else:
		magic_comp.consume(amount)
		if debug_me:
			print_rich(debug_name, ": [color=red][i]consumed[/i][/color] [i]", amount, "[/i] magic.")

#endregion APPLY EFFECTS

#region ONGOING EFFECTS

##Starts all ongoing effects from an ItemFunction, with tick timers and a duration timer.
func _start_ongoing_effects(item_function : ItemFunction, item_id : String) -> void:
	if item_function is ItemFunctionConsumable and not item_function.stackable:
		if _active_effects.has(item_id):
			_stop_ongoing_effects(item_id)
	if item_function.ongoing_effects.is_empty():
		return
	var tickers : Array[Timer] = []
	for effect in item_function.ongoing_effects:
		var tick_timer = Timer.new()
		tick_timer.wait_time = effect.interval
		tick_timer.one_shot = false
		tick_timer.timeout.connect(_on_ongoing_tick.bind(effect.action, effect.amount, effect.target))
		add_child(tick_timer)
		tick_timer.start()
		tickers.append(tick_timer)
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
		print_rich(debug_name, ": [color=green][i]started[/i][/color] [i]", tickers.size(), "[/i] ongoing effects for [i]", item_id, "[/i] ([i]", item_function.ongoing_duration, "[/i]s)")

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
	for ticker in data["tickers"]:
		if is_instance_valid(ticker):
			ticker.stop()
			ticker.queue_free()
	if is_instance_valid(data["timer"]):
		data["timer"].stop()
		data["timer"].queue_free()
	_active_effects.erase(item_id)
	ongoing_effect_ended.emit(item_id)
	if debug_me:
		print_rich(debug_name, ": [color=red][i]ongoing effects ended[/i][/color] for [i]", item_id, "[/i]")

##Returns whether an ongoing effect is currently active for the given item_id.
func has_active_effect(item_id : String) -> bool:
	return _active_effects.has(item_id)

##Pauses all active ongoing-effect timers mid-countdown without resetting them.
func pause_effects() -> void:
	for item_id in _active_effects:
		var data = _active_effects[item_id]
		if is_instance_valid(data["timer"]):
			data["timer"].paused = true
		for ticker in data["tickers"]:
			if is_instance_valid(ticker):
				ticker.paused = true

##Resumes all active ongoing-effect timers from where they were paused.
func resume_effects() -> void:
	for item_id in _active_effects:
		var data = _active_effects[item_id]
		if is_instance_valid(data["timer"]):
			data["timer"].paused = false
		for ticker in data["tickers"]:
			if is_instance_valid(ticker):
				ticker.paused = false

#endregion ONGOING EFFECTS

#endregion FUNCTIONS
