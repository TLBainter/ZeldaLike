##[b][color=red]HealthComponentPlayer[/color][/b] is the manager for the player's health bar (represented by skulls).[br]
##This utilizes a 4-part heart system, configures maximum health automatically, and also addreses damage.
class_name PlayerHealthComponent
extends HealthComponent

signal block_succeeded

#region VARIABLES

## Derived from stats resource (max_health / 4). Set at runtime.
var max_skulls : int = 3
## Snapshot of max_health taken at _ready(), before any runtime increase_max calls.
## Used by upgrade cap checks to determine how many skulls the player started with.
var base_max_health : int = 0

var _pending_hits : Array = []   # Array of {damage: int, position: Vector2, effect: DamageEffectResource}
var _hit_buffered : bool = false

const IFRAMES_DURATION: float = 0.25
var _iframes_active: bool = false
var _iframes_timer: Timer

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	_iframes_timer = Timer.new()
	_iframes_timer.one_shot = true
	_iframes_timer.wait_time = IFRAMES_DURATION
	_iframes_timer.timeout.connect(_on_iframes_expired)
	add_child(_iframes_timer)

	#region DEBUG HEALTH NOTIF
	var debug_health_notice : bool = false
	if debug_me:
		if debug_health_notice == false:
			print("You can control the player's health with the num pad.")
			print("Press Numpad Key 8 to recover health,")
			print("and press Numpad Key 2 to lose health.")
			debug_health_notice = true
	#endregion DEBUG HEALTH NOTIF
	
	#region Set Max HP
	var stats = _get_entity_stats()
	max_health = stats.max_health if stats else max_skulls * 4
	max_skulls = int(max_health / 4.0)
	base_max_health = max_health
	if debug_me:
		print("Player Max Health defined as ", max_health,
			" with ", max_skulls, " skulls.")
	cur_health = max_health
	if debug_me:
		print("Player Current Health is now ", cur_health, ".")
	#endregion Set Max HP

func _unhandled_input(event: InputEvent):
	if debug_me:
		_debug_health(event)

func _debug_health(event):
	if debug_me and event.is_action_pressed("hurtPlayer"):
		print(debug_name, " is being hurt by an input event!")
		damaged(1)
	elif debug_me and event.is_action_pressed("healPlayer"):
		print(debug_name, " is being healed by an input event!")
		healed(1)

func increase_max(amount: int) -> void:
	var old_max := max_health
	var old_cur := cur_health
	super.increase_max(amount)
	max_skulls = int(max_health / 4.0)
	if debug_me_verbose:
		print(debug_name, ": increase_max(", amount, ") -> max_health ", old_max, "->", max_health,
			" | max_skulls ", int(old_max / 4.0), "->", max_skulls,
			" | cur_health ", old_cur, "->", cur_health)

func damaged(damage : int, source_position : Vector2 = Vector2.ZERO, effect : DamageEffectResource = null) -> void:
	if _iframes_active:
		return
	_pending_hits.append({ "damage": damage, "position": source_position, "effect": effect })
	if not _hit_buffered:
		_hit_buffered = true
		_apply_best_hit.call_deferred()

func _apply_best_hit() -> void:
	_hit_buffered = false
	if _pending_hits.is_empty():
		return
	var entity = _find_entity_parent()
	if entity and "is_invulnerable" in entity and entity.is_invulnerable:
		_pending_hits.clear()
		return
	var _body = entity.get("body") if entity else null
	var player_pos : Vector2 = _body.global_position if _body else (entity.global_position if entity else Vector2.ZERO)
	_pending_hits.sort_custom(func(a, b) -> bool:
		if a["damage"] != b["damage"]:
			return a["damage"] > b["damage"]
		return a["position"].distance_squared_to(player_pos) < b["position"].distance_squared_to(player_pos)
	)
	var best : Dictionary = _pending_hits[0]
	_pending_hits.clear()
	if entity and entity.get("is_blocking") and entity.is_blocking:
		var source_pos : Vector2 = best["position"]
		if source_pos != Vector2.ZERO:
			var damage_dir := (source_pos - player_pos).normalized()
			var block_vec  := _facing_to_vec(entity.block_facing)
			if damage_dir.dot(block_vec) > 0.5:
				if entity.energy and entity.energy.consume(1):
					block_succeeded.emit()
					return
				# Energy = 0: fall through - damage applied, health_changed fires, StateBlock exits
	cur_health -= int(best["damage"])
	_iframes_active = true
	_iframes_timer.start()
	damage_taken.emit(best.get("effect"), best["position"], int(best["damage"]))

func _on_iframes_expired() -> void:
	_iframes_active = false

func _facing_to_vec(f: String) -> Vector2:
	match f:
		"up":    return Vector2(0, -1)
		"down":  return Vector2(0,  1)
		"left":  return Vector2(-1, 0)
		"right": return Vector2(1,  0)
	return Vector2.ZERO

#endregion FUNCTIONS
