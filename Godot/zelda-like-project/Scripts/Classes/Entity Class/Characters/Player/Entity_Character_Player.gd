##[b][color=red]Player[/color][/b] is the player character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds holds the control data for the player.
class_name Player
extends Character

#region VARIABLES
#region NPC COMPONENTS
@export_category("Player Components")
##Currency/money handler; expects type [color=yellow]CurrencyComponent[/color]
@export var currency : CurrencyComponent
##Magic handler; expects type [color=blue]MagicComponent[/color]
@export var magic : MagicComponent
##Stamina handler; excepts type [color=green]StaminaComponent[/color]
@export var energy : EnergyComponent
##Input handler; expects type [color=grey]InputComponent[/color]
@export var input : InputComponent
##A reference to the player UX element.
@export var player_ux : PlayerUX
##reference to the player's camera
@export var player_cam : PlayerCam
@export_group("Spells")
##A reference to the player's spell management component, which tracks equipped spells.
@export var equipped_spells : EquippedSpellsComponent
@export_group("Items")
##reference to the player's Inventory Component.
@export var inventory : InventoryComponentPlayer
##A reference to the player's Concoction Item Use Component.
@export var concoction_use : ConcoctionItemUse
@export_category("Player Flags")
##Whether or not the player can currently roll
var can_roll : bool = true
##Whether or not the player can currently move
var can_move : bool = true
##The display name for the player
var display_name : String = "Count"
#endregion
#region MISC EXPORT VARIABLES
#
#endregion
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	#establish variables
	subtype = "Player"
	add_to_group("player")
	if textResolver:
		textResolver.register_category("player", _resolve_text)
	input.actionButtonPressed.connect(_on_action_button_pressed)

func _resolve_text(key : String):
	match key:
		"name": return display_name if "display_name" in self else "Dracula"
		"health": return health.cur_health if health else 0
		"max_health": return health.max_health if health else 0
	return null

func _on_action_button_pressed(btn):
	match btn:
		"actionButton4":
			print("button4")
		#TODO: Add action button 3 logic
		"actionButton3":
			print("button3")
		#TODO: Add action button 2 logic
		"actionButton2":
			print("button2")
		#TODO: Add action button 1 logic
		"actionButton1":
			print("button1")

#region ACTION BUTTON 4

#endregion ACTION BUTTON 4

#region INTERACTIVITY CONTROL
##Prevent the character from moving at all
func freeze_input(should_freeze : bool):
	input.set_physics_process(not should_freeze)
	if should_freeze:
		body.velocity = Vector2.ZERO
		if anim:
			anim.stop()
	can_move = (not should_freeze)
		
#endregion INTERACTIVITY CONTROL
