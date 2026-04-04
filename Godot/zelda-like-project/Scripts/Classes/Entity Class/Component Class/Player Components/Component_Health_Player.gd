##[b][color=red]HealthComponentPlayer[/color][/b] is the manager for the player's health bar (represented by hearts).[br]
##This utilizes a 4-part heart system, configures maximum health automatically, and also addreses damage.
class_name PlayerHealthComponent
extends HealthComponent

#region VARIABLES

## Derived from stats resource (max_health / 4). Set at runtime.
var max_hearts : int = 3

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#region DEBUG HEALTH NOTIF
	var debug_health_notice : bool = false
	if debug_me:
		#provide instructions for health debugging if they have not yet been given
		if debug_health_notice == false:
			print("You can control the player's health with the num pad.")
			print("Press Numpad Key 8 to recover health,")
			print("and press Numpad Key 2 to lose health.")
			debug_health_notice = true
	#endregion DEBUG HEALTH NOTIF
	
	#region Set Max HP
	#Read max_health from the stats resource if available.
	var entity = _find_entity_parent()
	if entity and "stats" in entity and entity.stats and entity.stats.resource:
		max_health = entity.stats.resource.max_health
	else:
		max_health = max_hearts * 4
	#Derive heart count from max_health (4 HP per heart).
	max_hearts = int(max_health / 4.0)
	if debug_me:
		print("Player Max Health defined as ", max_health, 
			" with ", max_hearts, " hearts.")
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
	

#endregion FUNCTIONS
