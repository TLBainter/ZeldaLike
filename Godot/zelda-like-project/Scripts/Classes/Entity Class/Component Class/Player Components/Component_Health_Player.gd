##[b][color=red]HealthComponentPlayer[/color][/b] is the manager for the player's health bar (represented by hearts).[br]
##This utilizes a 4-part heart system, configures maximum health automatically, and also addreses damage.
class_name PlayerHealthComponent
extends HealthComponent

#region VARIABLES

##The maximum number of hearts the player has.
@export var max_hearts : int = 3

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
	#defines the player's max health.
	#since there are 4 hits in a single heart, the player's max health is equal to 4 * their maximum hearts!
	max_health = max_hearts * 4
	if debug_me:
		print("Player Max Health defined as ", max_health, " with ", max_hearts, " hearts.")
	if cur_health != max_health:
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
