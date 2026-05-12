##[b][color=red]EnemyManager / enemyManager[/color][/b] is an autoload that tracks enemy kill state for respawn and alt-drop logic.[br]
##Kill state is tiered: permanently dead (saved), session dead (runtime), and area dead (runtime).[br]
##[b]saveManager[/b] writes and restores [b]_killed_once[/b] and [b]_permanently_dead[/b] as part of its save file.[br]
##[br]
##Use [b]should_suppress(id, mode)[/b] in Enemy._ready() to decide whether to remove the enemy on load.
extends Node

##Emitted after an enemy is marked as killed. [b]saveManager[/b] connects to this to queue a deferred save.
signal enemy_killed(id: String)

#region VARIABLES

##Every enemy ID killed at least once. Saved to file. Drives alt drop table logic.
var _killed_once: Dictionary = {}
##Subset of [b]_killed_once[/b] for NEVER-respawn enemies. Saved to file. Suppresses enemy on scene load.
var _permanently_dead: Dictionary = {}
##ON_RELOAD enemies killed this game session. Runtime only - cleared on load_game / new_game.
var _session_dead: Dictionary = {}
##ON_RE_ENTER enemies killed this area visit. Runtime only - cleared when the area context changes.
var _area_dead: Dictionary = {}
##Path of the current area (parent level or standalone scene). Set by Level._enter_tree().
var _current_area_path: String = ""

#endregion VARIABLES

#region PUBLIC API

##Returns [b]true[/b] if the enemy with [param id] has been killed at least once.
func has_been_killed_once(id: String) -> bool:
	return _killed_once.has(id)

##Returns [b]true[/b] if the enemy with [param id] should be suppressed (not appear) given its [param respawn_mode].
func should_suppress(id: String, respawn_mode: int) -> bool:
	match respawn_mode:
		Enemy.Respawn.NEVER:       return _permanently_dead.has(id)
		Enemy.Respawn.ON_RELOAD:   return _session_dead.has(id)
		Enemy.Respawn.ON_RE_ENTER: return _area_dead.has(id)
		_: return false

##Records an enemy kill. Must be called from StateDead before [b]queue_free()[/b].
func mark_killed(id: String, respawn_mode: int) -> void:
	if id.is_empty():
		push_warning("EnemyManager: mark_killed called with empty id; skipping.")
		return
	_killed_once[id] = true
	match respawn_mode:
		Enemy.Respawn.NEVER:       _permanently_dead[id] = true
		Enemy.Respawn.ON_RELOAD:   _session_dead[id] = true
		Enemy.Respawn.ON_RE_ENTER: _area_dead[id] = true
	enemy_killed.emit(id)

##Called by [b]Level._enter_tree()[/b]. Clears [b]_area_dead[/b] whenever the player moves to a new area.
func notify_area_changed(new_area_path: String) -> void:
	if new_area_path != _current_area_path:
		_area_dead.clear()
		_current_area_path = new_area_path

##Clears runtime-only kill state. Called by [b]saveManager[/b] during [method load_game].
func on_game_reload() -> void:
	_session_dead.clear()
	_area_dead.clear()

##Returns a copy of the data that should be persisted. Called by [b]saveManager[/b] during [method save].
func get_save_data() -> Dictionary:
	return {
		"killed_once":     _killed_once.duplicate(),
		"permanently_dead": _permanently_dead.duplicate(),
	}

##Replaces persisted kill state. Called by [b]saveManager[/b] during [method load_game].
func restore_data(data: Dictionary) -> void:
	_killed_once      = data.get("killed_once",      {}).duplicate()
	_permanently_dead = data.get("permanently_dead", {}).duplicate()

##Clears all kill state. Called by [b]saveManager[/b] during [method new_game].
func clear() -> void:
	_killed_once.clear()
	_permanently_dead.clear()
	_session_dead.clear()
	_area_dead.clear()
	_current_area_path = ""

#endregion PUBLIC API
