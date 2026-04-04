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
	#Ensure health can't go below 0 or above max_health
	set(value):
		#Get the new value of the entity's Hit Points
		var new_health = clampi(value, 0, max_health)
		#Get the value by which the health was changed, which is used for signal emitting.
		var chng_amt = new_health - cur_health
		#Change health
		cur_health = new_health
		if chng_amt != 0:
			health_changed.emit(cur_health, max_health, chng_amt)
	
#endregion VARIBALES

#region FUNCTIONS

func _ready():
	var entity = _find_entity_parent()
	if entity and "stats" in entity and entity.stats and entity.stats.resource:
		max_health = entity.stats.resource.max_health
	else:
		max_health = 4
	cur_health = max_health

#region HEAL
func healed(healing : int):
	self.cur_health += healing
	if debug_me:
		print(debug_name, " gained ", healing, " health.")
		print(debug_name, " now has ", cur_health, " remaining Hit Points.")
#endregion HEAL

#region DAMAGE
func damaged(damage : int):
	self.cur_health -= damage
	if debug_me:
		print(debug_name, " took ", damage, " damage.")
		print(debug_name, " now has ", cur_health, " remaining Hit Points.")
#endregion DAMAGE

#endregion FUNCTIONS
