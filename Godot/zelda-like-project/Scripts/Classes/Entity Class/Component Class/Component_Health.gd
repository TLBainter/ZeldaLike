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
#TODO: Make it so that the change amount also tells you whether the change was positive or negative.

#endregion SIGNALS

#region VARIBALES
#TODO: Ensure that this does not override scene-set current health.
## Max health. Set at runtime from StatsComponent. Defaults to 4 if no stats resource.
var max_health : int = 4
##The current hit points of the entity.
var cur_health : int = 4:
	set(value):
		var new_health = clampi(value, 0, max_health)
		var chng_amt = new_health - cur_health
		cur_health = new_health
		if chng_amt != 0:
			health_changed.emit(cur_health, max_health, chng_amt)
	
#endregion VARIBALES

#region FUNCTIONS

func _ready():
	var stats = _get_entity_stats()
	max_health = stats.max_health if stats else 4
	cur_health = max_health

#region HEAL
func healed(healing : int):
	self.cur_health += healing
	if debug_me:
		print_rich(debug_name, ": [color=green][i]gained[/i][/color] [i]", healing, "[/i] health. Now: [i]", cur_health, "[/i]")
#endregion HEAL

#region DAMAGE
func damaged(damage : int, _source_position : Vector2 = Vector2.ZERO):
	var entity = _find_entity_parent()
	if entity and "is_invulnerable" in entity and entity.is_invulnerable:
		if debug_me:
			print_rich(debug_name, ": [color=red][i]damage blocked: entity is invulnerable[/i][/color].")
		return
	self.cur_health -= damage
	if debug_me:
		print_rich(debug_name, ": [color=red][i]took[/i][/color] [i]", damage, "[/i] damage. Now: [i]", cur_health, "[/i]")
#endregion DAMAGE

#endregion FUNCTIONS
