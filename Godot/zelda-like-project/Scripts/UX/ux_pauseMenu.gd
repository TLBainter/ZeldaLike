##[b][color=red]PauseMenu[/color][/b] controls the pause menu overlay.[br]
##Instantiated when the player pauses. Fades in a dark overlay, displays the menu,[br]
##and handles unpause input. Runs while the game is paused.[br]
class_name PauseMenu
extends Node

#region VARIABLES

@export_category("Pause Menu Components")
##The CanvasLayer containing the pause menu UI.
@export var canvas : CanvasLayer
##The MarginContainer or root control of the menu content.
@export var menu_container : Control
##The input controller for the menu.
@export var menu_controller : MenuController

@export_category("Fade Settings")
##How fast the dark overlay fades in (seconds).
@export var fade_in_duration : float = 0.3
##How fast the dark overlay fades out (seconds).
@export var fade_out_duration : float = 0.3
##The target darkness of the overlay (0.0 = transparent, 1.0 = fully black).
@export var overlay_darkness : float = 0.5

@export_category("Sounds")
##The sound library for random sounds to play when the player navigates a menu.
@export var nav_move_sounds : SoundLibrary
##Sound played when an unassigned spell is assigned to a button.
@export var inventory_confirm_sounds : SoundLibrary
##Sound played when an assigned spell is swapped between buttons.
@export var inventory_change_sounds : SoundLibrary

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

#=======INTERNAL VARIABLES=======#

##The dark overlay ColorRect.
var _overlay : ColorRect
##The canvas overlay layer.
var _overlay_layer : CanvasLayer
##Whether the menu is currently closing (fading out).
var _is_closing : bool = false
##Whether we are currently fading in.
var _fading_in : bool = false
##Whether we are currently fading out.
var _fading_out : bool = false
##Reference to the player's in-game UX canvas layer
var _player_ux_canvas : CanvasLayer = null
##Reference to this canvas's canvas layer
var _original_canvas_layer : int = 0
##Reference to the Hearts Margin's current alpha value.
var heart_fade_target : float = 1.0
##Reference to the Consumable Margin's current alpha value.
var consumable_fade_target : float = 1.0
## Reference to the Action Buttons Margin's current alpha value.
var action_button_fade_target : float = 1.0
##Internal reference to the action buttons.
var _action_buttons : Array = []

#endregion VARIABLES

#region FUNCTIONS

#region INITIALIZER
func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_create_overlay()
	_initialize()
	if debug_me:
		print(debug_name, ": Pause menu opened.")

##Open the pause menu; used in place of [color=blue]_ready()[/color] once the menu has been instantiated.
func open() -> void:
	_is_closing = false
	_fading_out = false
	if canvas:
		canvas.visible = true
	if _overlay_layer:
		_overlay_layer.visible = true
	if _overlay:
		_overlay.color.a = 0.0
	_initialize()
	if debug_me:
		print(debug_name, ": Pause menu reopened.")

func _initialize() -> void:
	#Get player references.
	var player = _find_player()
	var ux = _find_player_ux()
	if ux:
		_action_buttons = [null, ux.action_button_1, ux.action_button_2, ux.action_button_3]
	#Pass data to menu controller.
	if menu_controller:
		if player and player.inventory:
			menu_controller.set_inventory(player.inventory)
		if player and player.currency:
			menu_controller.set_currency(player.currency)
		if player and player.equipped_spells:
			menu_controller.set_equipped_spells(player.equipped_spells)
		menu_controller.activate()
		menu_controller.nav_move_sounds = nav_move_sounds
		menu_controller.pause_menu = self
	#Hide menu content initially.
	if menu_container:
		menu_container.modulate.a = 0.0
	#Pause and adjust UX.
	get_tree().paused = true
	_show_pause_ux()
	#Start fade in.
	_fading_in = true
	set_process(true)
#endregion INITIALIZER

func _unhandled_input(event : InputEvent) -> void:
	if _is_closing:
		return
	#Handle assignment of Spell Buttons
	if event.is_action_pressed("actionButton1") or event.is_action_pressed("actionButton2") or event.is_action_pressed("actionButton3"):
		if menu_controller and menu_controller.get_current() is MenuHoverableSpell:
			get_viewport().set_input_as_handled()
			return
	#Close on pause or actionButton1.
	if event.is_action_pressed("pause") or event.is_action_pressed("actionButton1"):
		get_viewport().set_input_as_handled()
		_close()

#region OVERLAY

##Creates a full-screen dark overlay on a CanvasLayer below the menu canvas.
func _create_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 99
	_overlay_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_overlay_layer)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_overlay_layer.add_child(_overlay)
	#Make sure the menu canvas renders above the overlay.
	if canvas:
		canvas.layer = 100

#endregion OVERLAY

#region FADE

##Fades out the overlay and menu, then unpauses and frees.
func _process(delta : float) -> void:
	if _fading_in:
		if _overlay:
			_overlay.color.a = move_toward(_overlay.color.a, overlay_darkness, delta / fade_in_duration)
		if menu_container:
			menu_container.modulate.a = move_toward(menu_container.modulate.a, 1.0, delta / fade_in_duration)
		#Check if fade in is complete.
		var overlay_done = _overlay.color.a >= overlay_darkness if _overlay else true
		var menu_done = menu_container.modulate.a >= 1.0 if menu_container else true
		if overlay_done and menu_done:
			_fading_in = false
			set_process(false)
	elif _fading_out:
		if _overlay:
			_overlay.color.a = move_toward(_overlay.color.a, 0.0, delta / fade_out_duration)
		if menu_container:
			menu_container.modulate.a = move_toward(menu_container.modulate.a, 0.0, delta / fade_out_duration)
		#Check if fade out is complete.
		var overlay_done = _overlay.color.a <= 0.0 if _overlay else true
		var menu_done = menu_container.modulate.a <= 0.0 if menu_container else true
		if overlay_done and menu_done:
			_fading_out = false
			set_process(false)
			_on_fade_out_complete()

func _on_fade_out_complete() -> void:
	get_tree().paused = false
	_restore_ux()
	if canvas:
		canvas.visible = false
	if _overlay_layer:
		_overlay_layer.visible = false
	if debug_me:
		print(debug_name, ": Pause menu closed. Game resumed.")

#endregion FADE

#region CLOSE

##Initiates the close sequence.
func _close() -> void:
	if _is_closing:
		return
	_is_closing = true
	if menu_controller:
		menu_controller.deactivate()
	_fading_in = false
	_fading_out = true
	set_process(true)
	if debug_me:
		print(debug_name, ": Closing pause menu...")

#endregion CLOSE

#region FIND PLAYER AND PLAYER_UX
func _find_player() -> Player:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0] as Player
	return null

func _find_player_ux() -> PlayerUX:
	var player = _find_player()
	if player and player.player_ux:
		return player.player_ux
	return null

func _find_ux_canvas_layer(node : Node) -> CanvasLayer:
	for child in node.get_children():
		if child is CanvasLayer:
			return child
	return null
#endregion FIND PLAYER

#region SHOW/HIDE IN-GAME UX

func _show_pause_ux() -> void:
	var ux = _find_player_ux()
	if not ux:
		return
	#OVERRIDE PAUSE TO FADE OUT########################
	if ux.heartsContainer:
		var hearts_margin = ux.heartsContainer.get_parent()
		if hearts_margin and hearts_margin is InGameMargin:
			hearts_margin.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
			heart_fade_target = hearts_margin.modulate.a
			hearts_margin.fade_out(0.0)
		elif hearts_margin:
			hearts_margin.visible = false
	#OVERRIDE PAUSE TO FADE OUT########################
	var consumable_buttons = ux.consumable_buttons
	if debug_me:
		print("PAUSE UX: consumable_buttons = ", consumable_buttons)
		print("PAUSE UX: consumable_buttons type = ", consumable_buttons.get_class() if consumable_buttons else "null")
		print("PAUSE UX: is InGameMargin = ", consumable_buttons is InGameMargin if consumable_buttons else false)
		print("PAUSE UX: consumable_buttons modulate.a = ", consumable_buttons.modulate.a if consumable_buttons else "null")
	if consumable_buttons and consumable_buttons is InGameMargin:
		consumable_buttons.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		consumable_fade_target = consumable_buttons.modulate.a
		consumable_buttons.fade_out(0.0)
		if debug_me:
			print("PAUSE UX: Consumables fade_out called")
	elif consumable_buttons:
		consumable_buttons.visible = false
		if debug_me:
			print("PAUSE UX: Consumables hidden via visible=false")
	# Fade action buttons IN to full alpha during pause.
	var action_buttons_margin = ux.action_buttons_margin
	if action_buttons_margin and action_buttons_margin is InGameMargin:
		action_buttons_margin.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		action_button_fade_target = action_buttons_margin.modulate.a
		action_buttons_margin.fade_in(1.0)
	# Instantly hide energy display.
	if ux.energy_display:
		ux.energy_display.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		ux.energy_display.set_paused(true)
	# Instantly hide magic display.
	if ux.magic_display:
		ux.magic_display.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		ux.magic_display.set_paused(true)
	#Raise PlayerUX canvas above the menu.
	_player_ux_canvas = _find_ux_canvas_layer(ux)
	if _player_ux_canvas:
		_original_canvas_layer = _player_ux_canvas.layer
		_player_ux_canvas.layer = 101

func _restore_ux() -> void:
	var ux = _find_player_ux()
	if not ux:
		return
	#Restore hearts.
	if ux.heartsContainer:
		var hearts_margin = ux.heartsContainer.get_parent()
		if hearts_margin and hearts_margin is InGameMargin:
			hearts_margin.process_mode = Node.PROCESS_MODE_INHERIT
			hearts_margin.fade_in(heart_fade_target)
	#Restore consumables.
	var consumable_buttons = ux.consumable_buttons
	if ux.consumable_buttons and consumable_buttons is InGameMargin:
		consumable_buttons.process_mode = Node.PROCESS_MODE_INHERIT
		consumable_buttons.modulate.a = 1.0
	elif ux.consumable_buttons:
		ux.consumable_buttons.visible = true
	# Restore action buttons to their pre-pause alpha.
	var action_buttons_margin = ux.action_buttons_margin
	if action_buttons_margin and action_buttons_margin is InGameMargin:
		action_buttons_margin.process_mode = Node.PROCESS_MODE_INHERIT
		action_buttons_margin.fade_out(action_button_fade_target)
	# Restore energy display.
	if ux.energy_display:
		ux.energy_display.process_mode = Node.PROCESS_MODE_INHERIT
		ux.energy_display.set_paused(false)
	# Restore magic display.
	if ux.magic_display:
		ux.magic_display.process_mode = Node.PROCESS_MODE_INHERIT
		ux.magic_display.set_paused(false)
	#Restore canvas layer.
	if _player_ux_canvas:
		_player_ux_canvas.layer = _original_canvas_layer
		_player_ux_canvas = null
#endregion SHOW/HIDE IN-GAME UX

#region Spell Assignment
func handle_spell_assignment(spell_panel : MenuHoverableSpell, slot : int) -> void:
	if not spell_panel or not spell_panel._equipped_spells:
		return
	var equipped = spell_panel._equipped_spells
	var item_res = spell_panel.item_resource
	if not item_res or item_res.item_id.is_empty():
		return
	if not spell_panel.player_has_item:
		return
	var current_slot = equipped.get_slot_for_spell(item_res.item_id)
	#Already assigned to this button -- do nothing.################
	if current_slot == slot:
		return
	var existing_in_target = equipped.get_spell(slot)
	var target_button : ActionButtonSprite = _action_buttons[slot] if slot < _action_buttons.size() else null
	var source_button : ActionButtonSprite = _action_buttons[current_slot] if current_slot > 0 and current_slot < _action_buttons.size() else null
	if current_slot == -1:
		#Not assigned anywhere -- simple assign.
		equipped.assign_spell(slot, item_res)
		_play_sound(inventory_confirm_sounds)
		if target_button:
			target_button._update_spell_display()
			target_button.play_assign_anim()
	elif existing_in_target == null:
		#Moving from one slot to empty slot.
		_play_sound(inventory_change_sounds)
		if source_button:
			source_button.play_unassign_anim()
		await get_tree().create_timer(source_button.get_unassign_duration() if source_button else 0.0).timeout
		equipped.unassign_spell(current_slot)
		equipped.assign_spell(slot, item_res)
		if source_button:
			source_button._update_spell_display()
		if target_button:
			target_button._update_spell_display()
			target_button.play_assign_anim()
	else:
		#Both occupied -- swap.
		_play_sound(inventory_change_sounds)
		if source_button:
			source_button.play_unassign_anim()
		if target_button:
			target_button.play_unassign_anim()
		var wait = 0.0
		if source_button:
			wait = maxf(wait, source_button.get_unassign_duration())
		if target_button:
			wait = maxf(wait, target_button.get_unassign_duration())
		await get_tree().create_timer(wait).timeout
		equipped.swap_spells(current_slot, slot)
		if source_button:
			source_button._update_spell_display()
			source_button.play_assign_anim()
		if target_button:
			target_button._update_spell_display()
			target_button.play_assign_anim()

func _play_sound(library : SoundLibrary) -> void:
	if library and not library.sl.is_empty() and audioManager:
		audioManager.play(library.sl.pick_random(), "UI")

#endregion Spell Assignment

#endregion FUNCTIONS
