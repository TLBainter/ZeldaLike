##[b][color=red]RecoverableResourceComponent[/color][/b] is the base class for resource components that recover over time.[br]
##Owns the recovery timer lifecycle and delegates resource-specific logic to subclasses via virtual hooks.[br]
##Subclasses must override [b]_is_resource_full()[/b], [b]_restore_one_tick()[/b], and [b]_on_recovery_complete()[/b].
class_name RecoverableResourceComponent
extends Component

#region VARIABLES

@export_category("Recovery")
@export_group("Recovery")
##How long after the last resource use before recovery begins (in seconds).
@export var recovery_delay : float = 2.0
##How much resource recovers per tick.
@export var recovery_amount : int = 1
##How often resource recovers (in seconds per tick).
@export var recovery_interval : float = 0.5

##Timer that counts down after last resource use before recovery begins.
var _recovery_delay_timer : Timer
##Timer that ticks at recovery_interval to restore resource.
var _recovery_tick_timer : Timer

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	_setup_recovery_timers()

##Creates and registers both recovery timers.
func _setup_recovery_timers() -> void:
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

##Stops any in-progress recovery and restarts the delay countdown.[br]
##Call this whenever the resource is consumed.
func _start_recovery_countdown() -> void:
	_recovery_tick_timer.stop()
	_recovery_delay_timer.stop()
	_recovery_delay_timer.start(recovery_delay)

func _on_recovery_delay_finished() -> void:
	if not _is_resource_full():
		_recovery_tick_timer.start(recovery_interval)
		_debug_log("Recovery started.")

func _on_recovery_tick() -> void:
	if _is_resource_full():
		_recovery_tick_timer.stop()
		_on_recovery_complete()
		return
	_restore_one_tick()
	if _is_resource_full():
		_recovery_tick_timer.stop()
		_on_recovery_complete()

##Virtual: return true when the resource is at maximum.
func _is_resource_full() -> bool:
	return true

##Virtual: restore one tick's worth of the resource.
func _restore_one_tick() -> void:
	pass

##Virtual: called when recovery finishes (resource reached maximum).
func _on_recovery_complete() -> void:
	pass

#endregion FUNCTIONS
