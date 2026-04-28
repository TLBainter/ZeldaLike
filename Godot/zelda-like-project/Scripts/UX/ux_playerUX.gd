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
@export var root : Player
@onready var player : CharacterBody2D = root.body
@onready var player_cam : PlayerCam = root.player_cam
@export var input : PlayerInputComponent
@export_group("Player UX Internal Components")
@export var currency_display : CurrencyDisplay
@export var dungeon_item_display : DungeonItemDisplay
@export var skullsContainer : SkullsDisplay
@export var ui_audio : UIAudioControl
@export var context_label : ContextLabel
@export var dialogue_controller : DialogueUI
@export var energy_display : EnergyDisplay
@export var magic_display : MagicDisplay
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
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	
	var ux_check_timer = Timer.new()
	ux_check_timer.wait_time = 0.1
	ux_check_timer.autostart = true
	ux_check_timer.timeout.connect(check_ux_overlap.emit)
	add_child(ux_check_timer)
	if debug_me:
		print("ux_check_timer created!")
	
	var hp_component : PlayerHealthComponent = root.health
	skullsContainer.set_max_skulls(hp_component.max_skulls)
	skullsContainer.update_skulls(hp_component.cur_health)
	hp_component.health_changed.connect(_on_health_changed)
	hp_component.max_health_changed.connect(_on_max_health_changed)
	check_viewport_size.emit()
	
	var energy_comp : EnergyComponent = root.energy
	if energy_comp and energy_display:
		energy_display.initialize(energy_comp, player, player_cam)
		energy_comp.max_energy_changed.connect(_on_max_energy_changed)
	
	var magic_comp : MagicComponent = root.magic
	if magic_comp and magic_display:
		magic_display.initialize(magic_comp, player, player_cam)
	
	var currency_comp : CurrencyComponent = root.currency
	if currency_comp and currency_display:
		currency_display.initialize(currency_comp)

	if root.inventory and dungeon_item_display:
		dungeon_item_display.initialize(root.inventory, self)
	
	if root.inventory and input:
		for panel in salve_panels:
			if panel:
				panel.initialize(root.inventory, input, root.concoction_use)
	
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
				energy_display.hide_immediately()
	if magic_display:
		if is_zoomed:
			magic_display.force_show(true)
		else:
			magic_display.force_show(false)
			if magic_display._magic_component and magic_display._magic_component.is_full():
				magic_display.hide_immediately()
	if currency_display:
		currency_display.force_show(is_zoomed)
	if dungeon_item_display:
		dungeon_item_display.force_show(is_zoomed)

func _on_health_changed(new_hp, max_hp, _change):
	var new_max_skulls := int(max_hp / 4.0)
	if new_max_skulls != skullsContainer.get_child_count():
		skullsContainer.set_max_skulls(new_max_skulls)
	skullsContainer.update_skulls(new_hp)

func _on_max_health_changed(new_max : int, new_cur : int):
	skullsContainer.set_max_skulls(int(new_max / 4.0))
	skullsContainer.update_skulls(new_cur)

func _on_max_energy_changed(new_max : int, _new_cur : int) -> void:
	energy_display.set_max_bolts(int(new_max / 4.0))
#endregion FUNCTIONS
