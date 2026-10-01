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
##Maps dungeon names to item id prefixes for the DUNGEON slots; when unset, the lowercased dungeon name is the prefix.
@export var dungeon_registry : DungeonRegistry

@export_category("Fade Settings")
##How fast the dark overlay fades in (seconds).
@export var fade_in_duration : float = 0.3
##How fast the dark overlay fades out (seconds).
@export var fade_out_duration : float = 0.3
##The target darkness of the overlay (0.0 = transparent, 1.0 = fully black).
@export var overlay_darkness : float = 0.5

@export_category("Sounds")
##Sound played when an unassigned spell is assigned to a button.
@export var inventory_confirm_sounds : SoundLibrary
##Sound played when an assigned spell is swapped between buttons.
@export var inventory_change_sounds : SoundLibrary

@export_category("Sogard")
##Full-screen pause backdrop texture, faded with the menu.
@export var pause_bg : TextureRect
##Settings page (SogardSettings, PAUSE variant) shown on page 1.
@export var settings_page : SogardSettings
##System page root shown on page 2.
@export var system_page : Control
##Focus navigator for the system page buttons.
@export var system_nav : SogardNavInput
##System page button that closes the menu.
@export var btn_resume : SogardButton
##System page button that saves and returns to the title screen.
@export var btn_quit_title : SogardButton
##System page button that saves and quits the application.
@export var btn_quit_desktop : SogardButton
##Bottom page tabs: Inventory, Settings, System.
@export var tabs : SogardTabs
##Bottom bar root holding the tabs, glyph chips, location and resume hint.
@export var bottom_bar : Control
##Resume hint shown on pages 0 and 2.
@export var resume_hint : SogardHintBar
##Label showing the current scene name.
@export var location_label : Label
##Frame drawn around the hovered inventory cell.
@export var sogard_cursor : ReferenceRect
##Icons inside the A, B, X and Y spell sockets, in slot order.
@export var sock_icons : Array[TextureRect] = []
##Large icon of the hovered item in the info column.
@export var info_icon : TextureRect
##Category tag of the hovered item in the info column.
@export var info_tag : Label
##Glyph hint rows under the info text, top to bottom.
@export var glyph_rows : Array[SogardHintBar] = []
##Label under the altar showing the hovered item's name.
@export var info_name_label : Label
##Face-button glyphs on the A, B, X and Y sockets, in slot order.
@export var sock_glyphs : Array[TextureRect] = []
##Material applied to unequipped spell icons.
@export var desaturate_material : ShaderMaterial
##Pixels the cursor frame extends past the hovered cell.
@export var cursor_inset : int = 2
##Number of discrete alpha steps in the open and close fades.
@export var fade_steps : int = 3
##Scene loaded by Save and Quit to Title.
@export var quit_scene_path : String = "res://Scenes/Levels/TitleScreen.tscn"

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v


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
##Reference to the Skulls Margin's current alpha value.
var skull_fade_target : float = 1.0
##Reference to the Consumable Margin's current alpha value.
var consumable_fade_target : float = 1.0
## Reference to the Action Buttons Margin's current alpha value.
var action_button_fade_target : float = 1.0
##Internal reference to the action buttons.
var _action_buttons : Array = []
##Snapshot of spell assignments taken when the menu opens; used to detect changes on close.
var _spell_snapshot : Dictionary = {}
var _page : int = 0
var _modal_open : bool = false
var _fade_t : float = 0.0
var _last_hover : MenuHoverable = null
var _equipped : EquippedSpellsComponent = null
var _equip_sig : Array = []
var _spell_hoverables : Array[MenuHoverableSpell] = []
var _glyph_platform : String = SogardInputGlyphs.KEYBOARD
var _sock_chips : Dictionary = {}
var _altar_frames : Array[AtlasTexture] = []
var _altar_frame : int = 0
var _altar_time : float = 0.0
var _altar_fps : float = 0.0

#endregion VARIABLES

#region FUNCTIONS

#region INITIALIZER
func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_create_overlay()
	_setup_sogard()
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
	var player = _find_player()
	var ux = _find_player_ux()
	if ux:
		_action_buttons = [null, ux.action_button_1, ux.action_button_2, ux.action_button_3]
	if menu_controller:
		if player and player.inventory:
			menu_controller.set_inventory(player.inventory)
		if player and player.health:
			menu_controller.set_health(player.health)
		if player and player.currency:
			menu_controller.set_currency(player.currency)
		if player and player.equipped_spells:
			menu_controller.set_equipped_spells(player.equipped_spells)
		menu_controller.activate()
		menu_controller.pause_menu = self
	_apply_dungeon_context(player)
	if player and player.equipped_spells:
		_spell_snapshot = _build_spell_snapshot(player.equipped_spells)
	if menu_container:
		menu_container.modulate.a = 0.0
	get_tree().paused = true
	musicManager.set_pause_duck(true)
	_show_pause_ux()
	_sogard_on_open()
	_fading_in = true
	menuSfx.play_page_open()
	set_process(true)

##Resolves the player's current dungeon and item id prefix from the level, then pushes both to every DUNGEON slot cell.
func _apply_dungeon_context(player : Player) -> void:
	if not menu_container:
		return
	var in_dungeon : bool = false
	var prefix : String = ""
	var level : Level = Level.get_level_ancestor(player) if player else null
	if level and level.get_effective_type() == Level.LevelType.DUNGEON:
		in_dungeon = true
		prefix = level.get_effective_name().to_lower()
		if dungeon_registry:
			prefix = dungeon_registry.get_prefix(prefix)
	for node in menu_container.find_children("*", "Control", true, false):
		var cell := node as MenuHoverableItemDungeon
		if cell:
			cell.set_dungeon_context(prefix, in_dungeon)
#endregion INITIALIZER

func _unhandled_input(event : InputEvent) -> void:
	if _is_closing or _modal_open:
		return
	if _page == 0 and (event.is_action_pressed("actionButton1") or event.is_action_pressed("actionButton2") or event.is_action_pressed("actionButton3")):
		if menu_controller and menu_controller.get_current() is MenuHoverableSpell:
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause") or (_page == 0 and event.is_action_pressed("actionButton1")):
		get_viewport().set_input_as_handled()
		_close()
		return
	if _page == 2 and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_set_page(0)
		return
	var step : int = 0
	if InputMap.has_action("menuTabLeft") and event.is_action_pressed("menuTabLeft"):
		step = -1
	elif InputMap.has_action("menuTabRight") and event.is_action_pressed("menuTabRight"):
		step = 1
	if step != 0:
		get_viewport().set_input_as_handled()
		_set_page(posmod(_page + step, 3))

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
	if canvas:
		canvas.layer = 100

#endregion OVERLAY

#region FADE

##Steps the overlay and page alpha in fade_steps increments, then tracks the hovered cell while open.
func _process(delta : float) -> void:
	if _fading_in or _fading_out:
		_fade_t += delta
		var dur : float = fade_in_duration if _fading_in else fade_out_duration
		var t : float = 1.0
		if dur > 0.0:
			t = clampf(_fade_t / dur, 0.0, 1.0)
		var steps : int = maxi(fade_steps, 1)
		var a : float = floorf(t * steps) / steps
		if _fading_out:
			a = 1.0 - a
		_apply_fade_alpha(a)
		if t >= 1.0:
			if _fading_out:
				_fading_out = false
				set_process(false)
				_on_fade_out_complete()
				return
			_fading_in = false
	if not _is_closing:
		_update_sogard_frame()
		_step_altar(delta)

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
	menuSfx.play_page_close()
	musicManager.set_pause_duck(false)
	_check_and_save_spells()
	if menu_controller:
		menu_controller.deactivate()
	_sogard_on_close()
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
	if ux.skullsContainer:
		var skulls_margin = ux.skullsContainer.get_parent()
		if skulls_margin and skulls_margin is InGameMargin:
			skulls_margin.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
			skull_fade_target = skulls_margin.modulate.a
			skulls_margin.fade_out(0.0)
		elif skulls_margin:
			skulls_margin.visible = false
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
	var action_buttons_margin = ux.action_buttons_margin
	if action_buttons_margin and action_buttons_margin is InGameMargin:
		action_buttons_margin.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		action_button_fade_target = action_buttons_margin.modulate.a
		action_buttons_margin.fade_out(0.0)
	if ux.context_label:
		ux.context_label.visible = false
	if ux.energy_display:
		ux.energy_display.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		ux.energy_display.set_paused(true)
	if ux.magic_display:
		ux.magic_display.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		ux.magic_display.set_paused(true)
	if ux.dungeon_item_display:
		ux.dungeon_item_display.set_paused(true)
	_player_ux_canvas = _find_ux_canvas_layer(ux)
	if _player_ux_canvas:
		_original_canvas_layer = _player_ux_canvas.layer
		_player_ux_canvas.layer = 101

func _restore_ux() -> void:
	var ux = _find_player_ux()
	if not ux:
		return
	if ux.skullsContainer:
		var skulls_margin = ux.skullsContainer.get_parent()
		if skulls_margin and skulls_margin is InGameMargin:
			skulls_margin.process_mode = Node.PROCESS_MODE_INHERIT
			skulls_margin.fade_in(skull_fade_target)
	var consumable_buttons = ux.consumable_buttons
	if ux.consumable_buttons and consumable_buttons is InGameMargin:
		consumable_buttons.process_mode = Node.PROCESS_MODE_INHERIT
		consumable_buttons.modulate.a = 1.0
	elif ux.consumable_buttons:
		ux.consumable_buttons.visible = true
	var action_buttons_margin = ux.action_buttons_margin
	if action_buttons_margin and action_buttons_margin is InGameMargin:
		action_buttons_margin.process_mode = Node.PROCESS_MODE_INHERIT
		action_buttons_margin.fade_in(action_button_fade_target)
	if ux.context_label:
		ux.context_label.visible = true
	if ux.energy_display:
		ux.energy_display.process_mode = Node.PROCESS_MODE_INHERIT
		ux.energy_display.set_paused(false)
	if ux.magic_display:
		ux.magic_display.process_mode = Node.PROCESS_MODE_INHERIT
		ux.magic_display.set_paused(false)
	if ux.dungeon_item_display:
		ux.dungeon_item_display.restore_after_pause()
	if _player_ux_canvas:
		_player_ux_canvas.layer = _original_canvas_layer
		_player_ux_canvas = null
#endregion SHOW/HIDE IN-GAME UX

#region Spell Assignment

func _build_spell_snapshot(equipped : EquippedSpellsComponent) -> Dictionary:
	var snap := {}
	for slot in [1, 2, 3]:
		var res : MenuItemResource = equipped.get_spell(slot)
		snap[slot] = res.item_id if res else ""
	return snap

func _check_and_save_spells() -> void:
	var player = _find_player()
	if not player or not player.equipped_spells:
		return
	var current := _build_spell_snapshot(player.equipped_spells)
	if current != _spell_snapshot:
		saveManager.save()
		if debug_me:
			print(debug_name, ": Spell assignments changed; saving.")

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
	if current_slot == slot:
		return
	var existing_in_target = equipped.get_spell(slot)
	var target_button : ActionButtonSprite = _action_buttons[slot] if slot < _action_buttons.size() else null
	var source_button : ActionButtonSprite = _action_buttons[current_slot] if current_slot > 0 and current_slot < _action_buttons.size() else null
	if current_slot == -1:
		equipped.assign_spell(slot, item_res)
		_play_sound(inventory_confirm_sounds)
		if target_button:
			target_button._update_spell_display()
			target_button.play_assign_anim()
	elif existing_in_target == null:
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
	if library and not library.sounds.is_empty() and audioManager:
		audioManager.play(library.sounds.pick_random(), "UI")

#endregion Spell Assignment

#region SOGARD

##Joins the glyph group, connects page signals, clears the legacy hover cursor texture and caches spell cells. Runs once from _ready.
func _setup_sogard() -> void:
	_spell_hoverables.clear()
	add_to_group(SogardInputGlyphs.GROUP)
	if menu_container:
		for n in menu_container.find_children("*", "", true, false):
			if n is MenuHoverable:
				var h : MenuHoverable = n
				h.cursor_texture = null
				if h.cursor_rect:
					h.cursor_rect.texture = null
				if h is MenuHoverableSpell:
					_spell_hoverables.append(h as MenuHoverableSpell)
	if settings_page:
		settings_page.back_requested.connect(_on_settings_back)
		settings_page.resume_requested.connect(_on_settings_resume)
		settings_page.page_requested.connect(_on_page_requested)
		if settingsManager:
			settings_page.setting_changed.connect(settingsManager.on_settings_changed)
	if btn_resume:
		btn_resume.activated.connect(_on_resume_pressed)
	if btn_quit_title:
		btn_quit_title.activated.connect(_on_quit_title_pressed)
	if btn_quit_desktop:
		btn_quit_desktop.activated.connect(_on_quit_desktop_pressed)
	if tabs:
		tabs.tab_changed.connect(_on_tab_changed)
	if debug_me:
		print(debug_name, ": Sogard setup, spell cells: ", _spell_hoverables.size())

##Resets page, fade, sockets and info state each time the menu opens.
func _sogard_on_open() -> void:
	_page = 0
	_modal_open = false
	_fade_t = 0.0
	_last_hover = null
	if system_nav:
		system_nav.active = false
	_apply_page_visuals()
	if location_label:
		location_label.text = ""
		var scene : Node = get_tree().current_scene
		if scene:
			location_label.text = String(scene.name).capitalize().to_upper()
	_equipped = null
	var player : Player = _find_player()
	if player:
		_equipped = player.equipped_spells
	_equip_sig = _build_equip_sig()
	if settingsManager:
		_glyph_platform = settingsManager.get_glyph_platform()
	_refresh_sock_glyphs()
	_refresh_sockets()
	_refresh_desaturation()
	_refresh_info(null)
	_apply_fade_alpha(0.0)

##Stops page input and the cursor when the close fade starts.
func _sogard_on_close() -> void:
	if settings_page and _page == 1:
		settings_page.set_active(false)
	if system_nav:
		system_nav.active = false
	if sogard_cursor:
		sogard_cursor.visible = false
	_fade_t = 0.0

##Sets the alpha of the overlay and every faded page element.
func _apply_fade_alpha(a : float) -> void:
	if _overlay:
		_overlay.color.a = overlay_darkness * a
	for item in [menu_container, pause_bg, settings_page, system_page, bottom_bar, sogard_cursor]:
		if item:
			var ci : CanvasItem = item
			ci.modulate.a = a

##Shows the node for the current page and syncs tabs and hints. Does not change input activation.
func _apply_page_visuals() -> void:
	if menu_container:
		menu_container.visible = _page == 0
	if settings_page:
		settings_page.visible = _page == 1
	if system_page:
		system_page.visible = _page == 2
	if tabs:
		tabs.set_active(_page, false)
	if resume_hint:
		resume_hint.visible = _page != 1
	if sogard_cursor:
		sogard_cursor.visible = false

##Switches to page index and moves input between the inventory controller, settings and system nav.
func _set_page(index : int) -> void:
	if index == _page or _is_closing or _modal_open:
		return
	var prev : int = _page
	if prev == 1 and settings_page:
		settings_page.set_active(false)
	if prev == 2 and system_nav:
		system_nav.active = false
	if prev == 0 and menu_controller:
		menu_controller.deactivate()
	_page = index
	_last_hover = null
	_refresh_info(null)
	_apply_page_visuals()
	if index == 0 and menu_controller:
		menu_controller.activate()
	elif index == 1 and settings_page:
		if settingsManager:
			settings_page.set_values(settingsManager.get_all())
		settings_page.set_active(true)
	elif index == 2:
		if system_nav:
			system_nav.active = true
		if btn_resume:
			btn_resume.grab_focus()
	menuSfx.play_page_switch()
	if debug_me:
		print(debug_name, ": Page ", _page)

##Per-frame tracking while open: equip changes, hovered cell info and the cursor frame.
func _update_sogard_frame() -> void:
	if _equipped:
		var sig : Array = _build_equip_sig()
		if sig != _equip_sig:
			_equip_sig = sig
			_refresh_sockets()
			_refresh_desaturation()
			_last_hover = null
	var hover : MenuHoverable = null
	if _page == 0 and menu_controller:
		hover = menu_controller.get_current()
	if hover != _last_hover:
		_last_hover = hover
		_refresh_info(hover)
	if sogard_cursor:
		sogard_cursor.visible = hover != null
		if hover:
			var r : Rect2 = hover.get_global_rect().grow(cursor_inset)
			sogard_cursor.global_position = r.position
			sogard_cursor.size = r.size

##Returns the spells in slots 1 to 3, used to detect equip changes while open.
func _build_equip_sig() -> Array:
	var sig : Array = []
	if _equipped:
		for slot in range(1, 4):
			sig.append(_equipped.get_spell(slot))
	return sig

##Returns the equipped slot of a spell cell, or -1.
func _slot_of(spell : MenuHoverableSpell) -> int:
	if not _equipped or not spell or not spell.item_resource:
		return -1
	return _equipped.get_slot_for_spell(spell.item_resource.item_id)

##Fills the A, B, X and Y socket icons from each equipped spell's mini_icon, else main frame 0; slot 4 has no spell and stays empty.
func _refresh_sockets() -> void:
	for i in sock_icons.size():
		var icon : TextureRect = sock_icons[i]
		if not icon:
			continue
		var tex : Texture2D = null
		if _equipped:
			var res : MenuItemResource = _equipped.get_spell(i + 1)
			if res:
				if res.mini_icon:
					tex = res.mini_icon
				else:
					tex = MenuHoverableItem.main_frame(res)
		icon.texture = tex

##Applies desaturate_material to spell icons that are not equipped.
func _refresh_desaturation() -> void:
	for spell in _spell_hoverables:
		if not spell.item_rect:
			continue
		if _slot_of(spell) == -1:
			spell.item_rect.material = desaturate_material
		else:
			spell.item_rect.material = null

##Updates the info tag, name, altar icon and glyph rows for the hovered cell; null clears them.
func _refresh_info(hover : MenuHoverable) -> void:
	var tag : String = ""
	var title : String = ""
	var tex : Texture2D = null
	var frames : Array[AtlasTexture] = []
	var fps : float = 0.0
	var rows : Array = []
	if hover is MenuHoverableSpell:
		var spell : MenuHoverableSpell = hover
		if spell.player_has_item:
			var slot : int = _slot_of(spell)
			tex = spell.info_texture()
			title = spell.info_name()
			frames = spell.info_frames()
			fps = spell.anim_fps
			if slot == -1:
				tag = "BOOK / UNEQUIPPED"
			else:
				tag = "BOOK / SLOT " + _slot_label(slot)
				var glyph : String = _slot_key(slot)
				if spell.item_resource and spell.item_resource.item_id == ItemID.SPELL_GRAPPLE:
					rows.append([glyph + ":Hold, then release to cast"])
					rows.append(["dpad:Aim while holding"])
				else:
					rows.append([glyph + ":Cast"])
			rows.append(["act1+act2+act3:Equip/Reassign"])
	elif hover is MenuHoverableItem:
		var item : MenuHoverableItem = hover
		if item.player_has_item:
			tex = item.info_texture()
			title = item.info_name()
			frames = item.info_frames()
			fps = item.anim_fps
			tag = _tag_for(hover)
	elif hover is MenuHoverableCurrency:
		var wallet : MenuHoverableCurrency = hover
		if wallet.wallet_rect:
			tex = wallet.wallet_rect.texture
		title = wallet.info_title
		tag = _tag_for(hover)
	elif hover:
		tag = _tag_for(hover)
	if info_tag:
		info_tag.text = tag
	if info_name_label:
		info_name_label.text = title
	_altar_frames = frames
	_altar_frame = 0
	_altar_time = 0.0
	_altar_fps = fps
	if info_icon:
		info_icon.texture = tex
	for i in glyph_rows.size():
		var row : SogardHintBar = glyph_rows[i]
		if not row:
			continue
		row.visible = i < rows.size()
		if row.visible:
			var pairs : Array[String] = []
			for p in rows[i]:
				pairs.append(String(p))
			row.set_hints(pairs)

##Returns the category tag for a non-spell cell from its container path.
func _tag_for(hover : MenuHoverable) -> String:
	var path : String = String(hover.name)
	if menu_container:
		path = String(menu_container.get_path_to(hover))
	if "Ingredient" in path:
		return "INGREDIENT"
	if "Mobility" in path:
		return "EQUIPMENT"
	if "Concoction" in path:
		return "CONCOCTION"
	if "Resource" in path:
		return "VITALITY"
	if "Currency" in path:
		return "MONEY"
	if "Dungeon" in path:
		return "DUNGEON"
	return ""

##Glyph key for a slot: act1-act3 from MenuHoverableSpell.BADGE_KEYS; slot 4 is the north button (x on Switch, else y).
func _slot_key(slot : int) -> String:
	if slot == 4:
		return "x" if _glyph_platform == SogardInputGlyphs.SWITCH else "y"
	return str(MenuHoverableSpell.BADGE_KEYS.get(slot, "act1"))

##Slot text for the info tag: the InputMap key on keyboard, else the face-button name for the current platform.
func _slot_label(slot : int) -> String:
	var i : int = clampi(slot - 1, 0, 3)
	if _glyph_platform == SogardInputGlyphs.KEYBOARD:
		var key : String = SogardInputGlyphs.key_for_action(StringName("actionButton%d" % slot))
		return key if not key.is_empty() else str(slot)
	if _glyph_platform == SogardInputGlyphs.PS:
		return str(["CROSS", "CIRCLE", "SQUARE", "TRIANGLE"][i])
	if _glyph_platform == SogardInputGlyphs.SWITCH:
		return str(["B", "A", "Y", "X"][i])
	return str(["A", "B", "X", "Y"][i])

##Sets each sock's face-button glyph for the current platform; keyboard shows an InputMap key chip instead.
func _refresh_sock_glyphs() -> void:
	for i in sock_glyphs.size():
		var rect : TextureRect = sock_glyphs[i]
		if not rect:
			continue
		var chip : PanelContainer = _sock_chips.get(i)
		if _glyph_platform == SogardInputGlyphs.KEYBOARD:
			rect.texture = null
			var text : String = SogardInputGlyphs.key_for_action(StringName("actionButton%d" % (i + 1)))
			if not chip:
				chip = SogardHintBar.make_key_chip(text)
				chip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				rect.add_child(chip)
				_sock_chips[i] = chip
			else:
				(chip.get_child(0) as Label).text = text
			chip.visible = not text.is_empty()
		else:
			rect.texture = SogardGlyphs.get_texture(_glyph_platform, _slot_key(i + 1))
			if chip:
				chip.visible = false

##Settings hook: redraws the sock glyphs and the hovered cell's info rows for platform p.
func set_glyph_platform(p : String) -> void:
	if p == _glyph_platform:
		return
	_glyph_platform = p
	_refresh_sock_glyphs()
	if _last_hover:
		_refresh_info(_last_hover)

##Steps the altar icon through the hovered item's frames at its anim_fps; one frame or none leaves the static icon.
func _step_altar(delta : float) -> void:
	if not info_icon or _altar_frames.size() < 2 or _altar_fps <= 0.0:
		return
	_altar_time += delta
	var step : float = 1.0 / _altar_fps
	if _altar_time < step:
		return
	_altar_time = fmod(_altar_time, step)
	_altar_frame = (_altar_frame + 1) % _altar_frames.size()
	info_icon.texture = _altar_frames[_altar_frame]

##Settings back (B) returns to the inventory page.
func _on_settings_back() -> void:
	_set_page(0)

##Settings resume (START or Esc) closes the menu.
func _on_settings_resume() -> void:
	_close()

##LB or RB from a page moves one page left or right, wrapping.
func _on_page_requested(delta : int) -> void:
	_set_page(posmod(_page + delta, 3))

##Tab selection switches pages directly.
func _on_tab_changed(index : int) -> void:
	_set_page(index)

##Resume button closes the menu.
func _on_resume_pressed() -> void:
	_play_sound(inventory_confirm_sounds)
	_close()

##Opens the quit to title confirm.
func _on_quit_title_pressed() -> void:
	_summon_quit_modal("Quit to Title", "Progress will be saved.", _on_quit_title_chosen)

##Opens the quit to desktop confirm.
func _on_quit_desktop_pressed() -> void:
	_summon_quit_modal("Quit to Desktop", "Progress will be saved.", _on_quit_desktop_chosen)

##Summons a SogardModal with Quit and Cancel, defaulting to Cancel, and blocks page input until it closes.
func _summon_quit_modal(title : String, body : String, on_chosen : Callable) -> void:
	if _modal_open or _is_closing:
		return
	_play_sound(inventory_confirm_sounds)
	if system_nav:
		system_nav.active = false
	var modal : SogardModal = SogardModal.summon(self, title, body, PackedStringArray(["Quit", "Cancel"]), 1, true)
	if not modal:
		if system_nav:
			system_nav.active = _page == 2
		return
	_modal_open = true
	modal.option_chosen.connect(on_chosen)
	modal.closed.connect(_on_modal_closed)

##Restores system page input after the confirm closes.
func _on_modal_closed() -> void:
	_modal_open = false
	if system_nav and _page == 2 and not _is_closing:
		system_nav.active = true

##Quit to title on option 0: saves, hides and frees this menu, unpauses, resets transitions and loads quit_scene_path.
func _on_quit_title_chosen(index : int) -> void:
	if index != 0 or _is_closing:
		return
	_begin_quit()
	if canvas:
		canvas.visible = false
	if _overlay_layer:
		_overlay_layer.visible = false
	get_tree().paused = false
	musicManager.set_pause_duck(false)
	if services.scene_transition:
		services.scene_transition.reset()
	get_tree().change_scene_to_file(quit_scene_path)
	queue_free()

##Quit to desktop on option 0: saves, then quits.
func _on_quit_desktop_chosen(index : int) -> void:
	if index != 0 or _is_closing:
		return
	_begin_quit()
	get_tree().quit()

##Shared quit steps: stops menu input, keeps spell changes, writes the save and restores player UX.
func _begin_quit() -> void:
	_is_closing = true
	if menu_controller:
		menu_controller.deactivate()
	_sogard_on_close()
	_check_and_save_spells()
	if services.save:
		services.save.save()
	_restore_ux()
	if debug_me:
		print(debug_name, ": Quitting from pause menu.")

#endregion SOGARD

#endregion FUNCTIONS
