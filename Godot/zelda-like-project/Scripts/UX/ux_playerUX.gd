##[b][color=red]playerUX[/color][/b] is primarily used to feed variable values to other entities within the player ui.
class_name PlayerUX
extends Control

#region SIGNALS

## A signal emitted to all UX elements ten times per second (instead of every frame) to check for UX overlaps.
signal check_ux_overlap
signal check_viewport_size

#endregion SIGNALS

#region VARIABLES
@export_group("PlayerUX External Components")
## a reference to the main player node.
@export var root : Player
## a reference to the player's character body 2D.
@onready var player : CharacterBody2D = root.body
## a reference to the player's camera
@onready var player_cam : PlayerCam = root.player_cam
## a reference to the player's input component
@export var input : PlayerInputComponent
@export_group("Player UX Internal Components")
## a reference to the player's currency display
@export var currency_display : CurrencyDisplay
## a reference to the heart container
@export var heartsContainer : HeartsDisplay
## a reference to the audio control node for player UI
@export var ui_audio : UIAudioControl
## a reference to the context button's text label (Button 4 Label)
@export var context_label : ContextLabel
## a reference to the dialogue controller
@export var dialogue_controller : DialogueUI
## a reference to the energy display for the player.
@export var energy_display : EnergyDisplay
## a reference to the magic display for the player.
@export var magic_display : MagicDisplay
## collection of references to the concoctions
@export_subgroup("Action Buttons")
@export var action_buttons_margin : InGameMargin
@export var action_button_1 : ActionButtonSprite
@export var action_button_2 : ActionButtonSprite
@export var action_button_3 : ActionButtonSprite
@export var action_button_4 : ActionButtonSprite
@export_subgroup("Concoctions")
##D-Pad Container Reference
@export var consumable_buttons : InGameMargin
##Do in this order: Up, Right, Down, Left [Restorative, Arcane, Energizing, Blood]
@export var salve_panels : Array[SalvePanel]

@export_group("Child Controls")
##Controls the speed at which entities within Player UX fade out when the player is beneath them.
@export var player_detection_fadeout_speed : float = 5.0
##The minimum alpha value for the UI, even when fading.
@export var ux_min_alpha : float = 0.1
@export_group("PlayerUX Debug")
@export var debug_me : bool = false
@export var debug_me_verbose : bool = false
@export var debug_name : String = "Player UI"
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	
	#Creates a timer for reference by other UX elements.
	#This timer ticks ten times per second, which is more efficient than Physics Process (every frame).
	var ux_check_timer = Timer.new()
	ux_check_timer.wait_time = 0.1
	ux_check_timer.autostart = true
	ux_check_timer.timeout.connect(check_ux_overlap.emit)
	add_child(ux_check_timer)
	if debug_me:
		print("ux_check_timer created!")
	
	#Set maximum hearts
	var hp_component : PlayerHealthComponent = root.health
	heartsContainer.set_max_hearts(hp_component.max_hearts)
	heartsContainer.update_hearts(hp_component.cur_health)
	hp_component.healthChanged.connect(_on_health_changed)
	#Calls the margin update on player UX launch.
	check_viewport_size.emit()
	
	#Set energy display
	var energy_comp : EnergyComponent = root.energy
	if energy_comp and energy_display:
		energy_display.initialize(energy_comp, player, player_cam)
	
	#Set magic display
	var magic_comp : MagicComponent = root.magic
	if magic_comp and magic_display:
		magic_display.initialize(magic_comp, player, player_cam)
	
	#Set currency display
	var currency_comp : CurrencyComponent = root.currency
	print("PlayerUX currency check: comp=", currency_comp, " display=", currency_display)

	if currency_comp and currency_display:
		currency_display.initialize(currency_comp)
	
	#Configure the concoctions
	if root.inventory and input:
		for panel in salve_panels:
			if panel:
				panel.initialize(root.inventory, input, root.concoction_use)
	
	#Configure spell equipment
	print("PlayerUX SPELL WIRE: equipped_spells=", root.equipped_spells)
	print("PlayerUX SPELL WIRE: btn1=", action_button_1, " btn2=", action_button_2, " btn3=", action_button_3)
	if debug_me:
		print("PlayerUX: root.equipped_spells = ", root.equipped_spells)
		print("PlayerUX: action_button_1 = ", action_button_1)
		print("PlayerUX: action_button_2 = ", action_button_2)
		print("PlayerUX: action_button_3 = ", action_button_3)
	if root.equipped_spells:
		var buttons = [action_button_1, action_button_2, action_button_3]
		for i in range(buttons.size()):
			if buttons[i]:
				if debug_me:
					print("PlayerUX: Calling set_equipped_spells on button ", i + 1, " (", buttons[i].action_name, ")")
				buttons[i].set_equipped_spells(root.equipped_spells, i + 1)
			else:
				if debug_me:
					print("PlayerUX: button ", i + 1, " is null!")
	else:
		if debug_me:
			print("PlayerUX: root.equipped_spells is null! Skipping spell wiring.")
	
	#Configure zoom call connections
	if player_cam:
		if energy_display and not player_cam.zoom_changed.is_connected(_on_zoom_changed):
			player_cam.zoom_changed.connect(_on_zoom_changed)

func _on_zoom_changed(is_zoomed : bool):
	if energy_display:
		if is_zoomed:
			energy_display.force_show(true)
		else:
			energy_display.force_show(false)
			if energy_display._energy_component and energy_display._energy_component.is_full():
				energy_display._target_alpha = 0.0
	if magic_display:
		if is_zoomed:
			magic_display.force_show(true)
		else:
			magic_display.force_show(false)
			if magic_display._magic_component and magic_display._magic_component.is_full():
				magic_display._target_alpha = 0.0
	if currency_display:
		currency_display.force_show(is_zoomed)

func _on_health_changed(new_hp, _max_hp, _change):
	heartsContainer.update_hearts(new_hp)
#endregion FUNCTIONS
