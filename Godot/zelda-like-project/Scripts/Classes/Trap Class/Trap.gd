##[b][color=red]Trap[/color][/b] drives a data-driven hazard that animates and deals damage to the player.[br]
##Reads all configuration from an assigned [b][color=yellow]TrapResource[/color][/b].[br]
##[br]
##Supports two trigger modes:[br]
##- [b]TIME_INTERVAL[/b]: fires on a global-clock-synced timer, paused when off-screen.[br]
##  All traps sharing the same [b]interval_seconds[/b] and [b]first_trigger_delay[/b] (set on each node) fire in unison.[br]
##- [b]PLAYER_TOUCH[/b]: fires once per player entry, resets on exit.
class_name Trap
extends Node2D

#region VARIABLES

@export_category("Trap Settings")
##The resource that defines this trap's sprite, behavior, and damage.
@export var trap_resource : TrapResource
##Extra delay before the very first trigger after the trap enters camera bounds.[br]
##E.g. interval_seconds=3, first_trigger_delay=2 → first trigger at 5s, all subsequent at 3s.[br]
##Two traps with identical [member first_trigger_delay] and [member TrapResource.interval_seconds] stay phase-locked.
@export var first_trigger_delay : float = 0.0

@export_group("Debug")
@export var debug : DebugSettings = DebugSettings.new()

@export_category("Trap Nodes")
##The Sprite2D that displays the trap animation.
@export var trap_sprite : Sprite2D
##The Area2D used for damage detection.[br]
##Collision layer and mask are set automatically at runtime.
@export var trap_damage_area : Area2D

#region INTERNAL VARIABLES
var _is_animating : bool = false
var _current_frame : int = 0
var _can_trigger : bool = true		# PLAYER_TOUCH only

var _frame_timer : Timer
##One-shot timer for TIME_INTERVAL mode.[br]
##Wait time is always computed from the global engine clock so all traps stay phase-locked.
var _sync_timer : Timer
var _touch_delay_timer : Timer		# PLAYER_TOUCH only (when touch_delay > 0)

var _vis_notifier : VisibleOnScreenNotifier2D
#endregion INTERNAL VARIABLES

#endregion VARIABLES

#region FUNCTIONS

#region READY
func _ready() -> void:
	if not trap_resource:
		push_warning(name + ": No TrapResource assigned; trap will not function.")
		return
	if not trap_sprite:
		push_warning(name + ": No TrapSprite assigned; trap will not function.")
		return
	if not trap_damage_area:
		push_warning(name + ": No TrapDamageArea assigned; trap will not function.")
		return

	trap_damage_area.collision_layer = 8	# Layer 4: Trap
	trap_damage_area.collision_mask = 1		# Layer 1: Character

	trap_sprite.texture = trap_resource.sprite_texture
	trap_sprite.hframes = trap_resource.frame_count
	trap_sprite.frame = 0

	_frame_timer = Timer.new()
	_frame_timer.one_shot = true
	_frame_timer.timeout.connect(_on_frame_timer_timeout)
	add_child(_frame_timer)

	match trap_resource.trigger_type:
		TrapResource.TriggerType.TIME_INTERVAL:
			_setup_interval_trigger()
		TrapResource.TriggerType.PLAYER_TOUCH:
			_setup_touch_trigger()
#endregion READY

#region SETUP HELPERS
func _setup_interval_trigger() -> void:
	_vis_notifier = VisibleOnScreenNotifier2D.new()
	add_child(_vis_notifier)
	_vis_notifier.screen_entered.connect(_on_screen_entered)
	_vis_notifier.screen_exited.connect(_on_screen_exited)

	_sync_timer = Timer.new()
	_sync_timer.one_shot = true
	_sync_timer.timeout.connect(_trigger)
	add_child(_sync_timer)

	if _vis_notifier.is_on_screen():
		_on_screen_entered()


func _setup_touch_trigger() -> void:
	trap_damage_area.body_entered.connect(_on_body_entered)
	trap_damage_area.body_exited.connect(_on_body_exited)

	if trap_resource.touch_delay > 0.0:
		_touch_delay_timer = Timer.new()
		_touch_delay_timer.one_shot = true
		_touch_delay_timer.wait_time = trap_resource.touch_delay
		_touch_delay_timer.timeout.connect(_trigger)
		add_child(_touch_delay_timer)
#endregion SETUP HELPERS

#region SYNC TIMER
##Starts [member _sync_timer] with a wait time calculated from the global engine clock.[br]
##[b]first_trigger_delay[/b] acts as a phase offset: two traps with the same
##[b]interval_seconds[/b] and [b]first_trigger_delay[/b] will always fire simultaneously,
##regardless of when they individually entered camera bounds.[br]
##[br]
##Trigger times (seconds from engine start): [code]first_trigger_delay + n * interval_seconds[/code]
func _start_sync_timer() -> void:
	var t : float = Time.get_ticks_msec() / 1000.0
	var phase : float = first_trigger_delay
	var interval : float = trap_resource.interval_seconds
	var time_until_next : float
	if t < phase:
		time_until_next = phase + interval - t
	else:
		var time_in_cycle : float = fmod(t - phase, interval)
		time_until_next = interval - time_in_cycle
	_sync_timer.start(time_until_next)
#endregion SYNC TIMER

#region TRIGGER
func _trigger() -> void:
	if _is_animating:
		return
	if trap_resource.trigger_sounds and trap_resource.trigger_sounds.sl.size() > 0:
		audioManager.play(trap_resource.trigger_sounds.sl.pick_random(), "Environment")
	_is_animating = true
	_current_frame = 0
	trap_sprite.frame = 0
	_frame_timer.start(trap_resource.frame_duration)
	_dprint("triggered")
#endregion TRIGGER

#region ANIMATION
func _on_frame_timer_timeout() -> void:
	if _current_frame == trap_resource.damage_frame:
		_try_deal_damage()

	_current_frame += 1

	if _current_frame >= trap_resource.frame_count:
		trap_sprite.frame = 0
		_is_animating = false

		match trap_resource.trigger_type:
			TrapResource.TriggerType.TIME_INTERVAL:
				if _vis_notifier and _vis_notifier.is_on_screen():
					_start_sync_timer()
	else:
		trap_sprite.frame = _current_frame
		_frame_timer.start(trap_resource.frame_duration)
#endregion ANIMATION

#region DAMAGE
func _try_deal_damage() -> void:
	match trap_resource.target_part:
		TrapResource.PlayerTargetPart.BODY:
			for body in trap_damage_area.get_overlapping_bodies():
				if body is PlayerBody:
					body.root.health.damaged(trap_resource.trap_damage, global_position)
					break
		TrapResource.PlayerTargetPart.FEET:
			for area in trap_damage_area.get_overlapping_areas():
				if area.get_parent() is PlayerBody and area == area.get_parent().root.foot_area:
					area.get_parent().root.health.damaged(trap_resource.trap_damage, global_position)
					break
#endregion DAMAGE

#region DEBUG
func _dprint(msg : String) -> void:
	if debug and debug.debug_me:
		var label : String = debug.debug_name if debug.debug_name != "" else str(name)
		print("[Trap] ", label, ": ", msg)
#endregion DEBUG

#region VISIBILITY (TIME_INTERVAL)
func _on_screen_entered() -> void:
	_dprint("entered camera bounds")
	if not _is_animating:
		_start_sync_timer()


func _on_screen_exited() -> void:
	_dprint("exited camera bounds")
	_sync_timer.stop()
#endregion VISIBILITY

#region BODY DETECTION (PLAYER_TOUCH)
func _on_body_entered(body : Node2D) -> void:
	if body is PlayerBody:
		if _can_trigger:
			_can_trigger = false
			if _touch_delay_timer:
				_touch_delay_timer.start()
			else:
				_trigger()


func _on_body_exited(body : Node2D) -> void:
	if body is PlayerBody:
		_can_trigger = true
		if _touch_delay_timer:
			_touch_delay_timer.stop()
#endregion BODY DETECTION

#endregion FUNCTIONS
