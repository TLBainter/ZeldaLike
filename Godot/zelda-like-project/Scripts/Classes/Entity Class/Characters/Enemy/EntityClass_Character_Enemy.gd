@icon("res://Editor Tools/Icons/icon_common-enemy.svg")
##[b][color=red]Enemy[/color][/b] is a character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds [b]Bosses[/b], [b]Mini Bosses[/b], and [b]Standard Enemies[/b].
class_name Enemy
extends Character

#region VARIABLES
#region ENEMY COMPONENTS
@export_group("Enemy Components")
##AI input handler for this enemy.
@export var input : InputComponent
##Holds all attack data and directional attack areas.
@export var attack_component : EnemyAttackComponent
#endregion
#region MISC EXPORT VARIABLES
@export_group("Misc Enemy Variables")
##the NPC's name as it will be displayed
@export var enemy_name : String
##Drop table resolved when this enemy dies.
@export var drop_table : DropTable
##Minimum seconds to wait between consecutive attacks.
@export var min_delay_between_attacks : float = 0.5
##Maximum seconds to wait between consecutive attacks.
@export var max_delay_between_attacks : float = 2.0
#endregion
#region RESPAWN EXPORT VARIABLES
##Controls when this enemy respawns after being killed.
enum Respawn {
	USE_ROOM_SETTINGS, ##Inherit the respawn setting from the parent Level (default).
	ON_RETURN,         ##Respawn every time this room is re-entered.
	ON_RE_ENTER,       ##Respawn only when the parent area (dungeon) is fully exited and re-entered.
	ON_RELOAD,         ##Respawn only when the game is reloaded (player death / load save).
	NEVER,             ##Never respawn. Once killed, remains dead permanently.
}
@export_group("Respawn")
@export var respawn: Respawn = Respawn.USE_ROOM_SETTINGS
##If enabled, uses [member alt_drop_table] for every kill after the first.
@export var use_alt_drop_table: bool = false:
	set(v):
		use_alt_drop_table = v
		notify_property_list_changed()
##Drop table used on the second kill onward when [member use_alt_drop_table] is enabled.[br]
##Leave empty to drop nothing after the first kill.
@export var alt_drop_table: DropTable
#endregion
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
##Unique ID for this enemy placement, used by [b]enemyManager[/b] for kill tracking.
var _enemy_id: String = ""
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	subtype = "Enemy"
	add_to_group("enemies")
	_enemy_id = _get_enemy_id()
	if not _enemy_id.is_empty() and enemyManager.should_suppress(_enemy_id, get_effective_respawn()):
		hide()
		set_process_mode(PROCESS_MODE_DISABLED)
		queue_free()
		return
#endregion

##Returns the unique placement ID used by [b]enemyManager[/b] for kill tracking.
func get_enemy_id() -> String:
	return _enemy_id

##Returns the resolved [enum Respawn] mode, reading from the parent [Level] if set to [constant Respawn.USE_ROOM_SETTINGS].
func get_effective_respawn() -> Respawn:
	if respawn != Respawn.USE_ROOM_SETTINGS:
		return respawn
	var level := Level.get_level_ancestor(self)
	if level:
		return level.get_effective_enemy_respawn()
	return Respawn.ON_RETURN

func _get_enemy_id() -> String:
	var scene := get_tree().current_scene
	if not scene or scene.scene_file_path.is_empty():
		return ""
	return scene.scene_file_path + "::" + str(scene.get_path_to(self))

func _validate_property(property: Dictionary) -> void:
	if property.name == "alt_drop_table" and not use_alt_drop_table:
		property.usage = PROPERTY_USAGE_NO_EDITOR

##Applies [param amount] damage to this enemy.[br]
##Guards against invulnerability. Triggers the Dying state when health reaches zero.[br]
##Pass a [b]DamageEffectResource[/b] to override the enemy's default effect for this hit.
func take_damage(amount : int, effect : DamageEffectResource = null) -> void:
	if is_invulnerable:
		return
	if not health:
		return
	health.damaged(amount, Vector2.ZERO, effect)
	if debug_me:
		print_rich(debug_name, ": took [b]", amount, "[/b] damage — health now [b]", health.cur_health, "/", health.max_health, "[/b].")
	if health.cur_health <= 0:
		var dying_state = state_machine.get_transition(StateID.DYING) if state_machine else null
		if dying_state:
			state_machine.request_no_control_change(dying_state)
	else:
		var damaged_state = state_machine.get_transition(StateID.DAMAGED) if state_machine else null
		if damaged_state:
			state_machine.request_no_control_change(damaged_state)

#endregion FUNCTIONS
