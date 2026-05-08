@icon("res://Editor Tools/Icons/icon_health.svg")
##[b][color=red]HealthComponent[/color][/b] addresses the current and maximum health of a member of the Entity Class,[br]
##as well as the damage and healing.
class_name HealthComponent
extends Component

#region SIGNALS

##Signal to emit when health is changed.[br]
##This signal expects the following: (current health (int), maximum health (int), and the amount by which the health was changed (int))[br]
##[b]cur_hp[/b]: How much health the entity currently has.[br]
##[b]max_hp[/b]: The maximum possible hit point value of the entity.[br]
##[b]chng_amt[/b]: The value by which the hit points were changed.[br]
##Note that this signal is emitted by the variable itself any time it is changed; no need to call it elsewhere!
signal health_changed(cur_hp : int, max_hp : int, chng_amt : int)
##Emitted when max_health is increased (e.g. heart container pickup). Does NOT emit health_changed.
signal max_health_changed(new_max : int, new_cur : int)
##Emitted after damage is applied. Carries the [b]DamageEffectResource[/b] to play (may be null), the world-space source position, and the damage amount.
signal damage_taken(effect : DamageEffectResource, position : Vector2, amount : int)

#endregion SIGNALS

#region VARIBALES
## Max health. Set at runtime from StatsComponent. Defaults to 4 if no stats resource.
var max_health : int = 4
##The current hit points of the entity.
##Set true during increase_max to suppress health_changed (max expansion, not a heal).
var _expanding_max : bool = false
var cur_health : int = 4:
	set(value):
		var new_health = clampi(value, 0, max_health)
		var chng_amt = new_health - cur_health
		cur_health = new_health
		if chng_amt != 0 and not _expanding_max:
			health_changed.emit(cur_health, max_health, chng_amt)
	
#endregion VARIBALES

#region FUNCTIONS

func _ready():
	var stats = _get_entity_stats()
	max_health = stats.max_health if stats else 4
	cur_health = max_health

func increase_max(amount: int) -> void:
	_expanding_max = true
	max_health += amount
	self.cur_health += amount
	_expanding_max = false
	max_health_changed.emit(max_health, cur_health)

#region HEAL
func healed(healing : int):
	self.cur_health += healing
	if debug_me:
		print_rich(debug_name, ": [color=green][i]gained[/i][/color] [i]", healing, "[/i] health. Now: [i]", cur_health, "[/i]")
#endregion HEAL

#region DAMAGE
func damaged(damage : int, source_position : Vector2 = Vector2.ZERO, effect : DamageEffectResource = null):
	var entity = _find_entity_parent()
	if entity and "is_invulnerable" in entity and entity.is_invulnerable:
		if debug_me:
			print_rich(debug_name, ": [color=red][i]damage blocked: entity is invulnerable[/i][/color].")
		return
	self.cur_health -= damage
	if debug_me:
		print_rich(debug_name, ": [color=red][i]took[/i][/color] [i]", damage, "[/i] damage. Now: [i]", cur_health, "[/i]")
	damage_taken.emit(effect, source_position, damage)
#endregion DAMAGE

#endregion FUNCTIONS
