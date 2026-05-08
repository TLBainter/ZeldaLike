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
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	subtype = "Enemy"
	add_to_group("enemies")
#endregion

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
