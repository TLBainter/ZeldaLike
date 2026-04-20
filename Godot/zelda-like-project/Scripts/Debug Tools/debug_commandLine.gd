##[b][color=red]DebugConsole[/color][/b] is a simple in-game text prompt for debug commands.[br]
##Press TAB to open/close. Type commands and press Enter to execute.[br]
##[br]
##[b]Commands:[/b][br]
##[code]/give item_id quantity[/code] -- Adds items to player inventory. Quantity defaults to 1.[br]
##[code]/remove item_id quantity[/code] -- Removes items from player inventory. Quantity defaults to 1.[br]
##[code]/list[/code] -- Prints all current inventory contents.[br]
##[code]/items[/code] -- Prints all valid ItemID constants.[br]
class_name DebugCommandLine
extends CanvasLayer

#region VARIABLES

var _input_field : LineEdit
var _output_label : RichTextLabel
var _panel : PanelContainer
var _is_open : bool = false
var _inventory : InventoryComponent = null
var _health : PlayerHealthComponent = null
var _energy : EnergyComponent = null
var _magic : MagicComponent = null
var _currency : CurrencyComponent = null

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false

func _input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		if _is_open:
			_close()
		else:
			_open()
		return
	if _is_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _open() -> void:
	print("CONSOLE: _open() called")
	_is_open = true
	_panel.visible = true
	_input_field.text = ""
	_input_field.grab_focus()
	print("CONSOLE: after grab_focus. has_focus=", _input_field.has_focus())
	if not _inventory:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty() and "inventory" in players[0]:
			_inventory = players[0].inventory
	if not _currency:
		var players = get_tree().get_nodes_in_group("player")
		if "currency" in players[0]:
			_currency = players[0].currency
	if not _health:
		var players = get_tree().get_nodes_in_group("player")
		if "health" in players[0]:
			_health = players[0].health
	if not _energy:
		var players = get_tree().get_nodes_in_group("player")
		if "energy" in players[0]:
			_energy = players[0].energy
	if not _magic:
		var players = get_tree().get_nodes_in_group("player")
		if "magic" in players[0]:
			_magic = players[0].magic

func _close() -> void:
	print("CONSOLE: _close() called")
	_is_open = false
	_panel.visible = false
	_input_field.release_focus()

func _on_input_gui_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_input_field.accept_event()
		var text = _input_field.text.strip_edges()
		_input_field.text = ""
		_input_field.caret_column = 0
		if text.is_empty():
			return
		_execute_command(text)

func _execute_command(text : String) -> void:
	var parts = text.split(" ", false)
	if parts.is_empty():
		return
	var command = parts[0].to_lower()
	match command:
		"/give":
			_cmd_give(parts)
		"/remove":
			_cmd_remove(parts)
		"/set":
			_cmd_set(parts)
		"/list":
			_cmd_list()
		"/items":
			_cmd_items()
		"/help":
			_cmd_help()
		"/upgrade":
			_cmd_upgrade(parts)
		"/enable":
			_cmd_enable(parts)
		"/disable":
			_cmd_disable(parts)
		"/save":
			_cmd_save()
		"/load":
			_cmd_load()
		"/new":
			_cmd_new_game(parts)
		_:
			_print_output("[color=red]Unknown command: " + command + ". Type /help for commands.[/color]")

#region COMMANDS

func _cmd_give(parts : Array) -> void:
	if parts.size() < 2:
		_print_output("[color=red]Usage: /give item_id [quantity][/color]")
		return
	if parts[1].to_lower() == "all":
		_cmd_give_all(parts)
		return
	var item_id = parts[1]
	var quantity = 1
	if parts.size() >= 3:
		quantity = int(parts[2])
		if quantity <= 0:
			quantity = 1
	if not _validate_item_id(item_id):
		_print_output("[color=yellow]Warning: '" + item_id + "' not found in ItemID constants. Giving anyway.[/color]")
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	var mir_cap : MenuItemResource = ItemID.MENU_ITEM_RESOURCES.get(item_id)
	var upgrade_cap := mir_cap as MenuItemUpgradeResource
	if upgrade_cap and upgrade_cap.max_quantity > 0:
		var max_total : int = upgrade_cap.get_adjusted_max_total(_health.base_max_health if _health else 0)
		var current_qty : int = _inventory.get_quantity(item_id)
		quantity = mini(quantity, max_total - current_qty)
		if quantity <= 0:
			_print_output("[color=yellow]" + item_id + " is already at max (" + str(upgrade_cap.max_quantity) + " sets).[/color]")
			return
	var qty_before : int = _inventory.get_quantity(item_id)
	_inventory.add_item(item_id, quantity)
	var qty_after : int = _inventory.get_quantity(item_id)
	_apply_upgrade_permanent_effects(item_id, qty_before, qty_after)
	_print_output("[color=green]Gave " + str(quantity) + "x " + item_id + ". Total: " + str(qty_after) + "[/color]")

func _cmd_give_all(parts : Array) -> void:
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	var quantity = 1
	if parts.size() >= 3:
		var category = parts[2].to_lower()
		if category.is_valid_int():
			quantity = int(category)
			_give_all_items(quantity)
			return
		if parts.size() >= 4:
			quantity = int(parts[3])
			if quantity <= 0:
				quantity = 1
		if ItemID.CATEGORIES.has(category):
			var items = ItemID.CATEGORIES[category]
			for item_id in items:
				_inventory.add_item(item_id, quantity)
			_print_output("[color=green]Gave " + str(quantity) + "x of all " + str(items.size()) + " " + category + " items.[/color]")
		else:
			var valid = ", ".join(ItemID.CATEGORIES.keys())
			_print_output("[color=red]Unknown category: '" + category + "'. Valid: " + valid + "[/color]")
	else:
		_give_all_items(quantity)

func _give_all_items(quantity : int = 1) -> void:
	var all_ids = _get_all_item_ids()
	for item_id in all_ids:
		_inventory.add_item(item_id, quantity)
	_print_output("[color=green]Gave " + str(quantity) + "x of all " + str(all_ids.size()) + " items.[/color]")

func _cmd_remove(parts : Array) -> void:
	if parts.size() < 2:
		_print_output("[color=red]Usage: /remove item_id [quantity][/color]")
		return
	if parts[1].to_lower() == "all":
		_cmd_remove_all(parts)
		return
	var item_id = parts[1]
	var quantity = 1
	if parts.size() >= 3:
		quantity = int(parts[2])
		if quantity <= 0:
			quantity = 1
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	var removed = _inventory.remove_item(item_id, quantity)
	_print_output("[color=green]Removed " + str(removed) + "x " + item_id + ". Remaining: " + str(_inventory.get_quantity(item_id)) + "[/color]")

func _cmd_remove_all(parts : Array) -> void:
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	if parts.size() >= 3:
		var category = parts[2].to_lower()
		if ItemID.CATEGORIES.has(category):
			var items = ItemID.CATEGORIES[category]
			for item_id in items:
				_inventory.set_quantity(item_id, 0)
			_print_output("[color=green]Removed all " + category + " items.[/color]")
			return
		else:
			var valid = ", ".join(ItemID.CATEGORIES.keys())
			_print_output("[color=red]Unknown category: '" + category + "'. Valid: " + valid + "[/color]")
			return
	_inventory.clear_inventory()
	_print_output("[color=green]Cleared entire inventory.[/color]")

func _cmd_list() -> void:
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	var items = _inventory.get_all_items()
	if items.is_empty():
		_print_output("[color=yellow]Inventory is empty.[/color]")
		return
	var text = "[color=white]Inventory:[/color]\n"
	for item_id in items:
		text += "  " + item_id + ": " + str(items[item_id]) + "\n"
	_print_output(text)

func _cmd_items() -> void:
	var constants = _get_all_item_ids()
	if constants.is_empty():
		_print_output("[color=red]No ItemID constants found.[/color]")
		return
	var text = "[color=white]Valid ItemIDs:[/color]\n"
	for c in constants:
		text += "  " + c + "\n"
	_print_output(text)

func _cmd_upgrade(parts : Array) -> void:
	if parts.size() < 2:
		_print_output("[color=red]Usage: /upgrade <item_id>[/color]")
		return
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	var item_id : String = " ".join(parts.slice(1)).replace(" ", "_").to_lower()
	if not ItemID.MOBILITY_UPGRADES.has(item_id):
		_print_output("[color=red]No upgrade defined for '" + item_id + "'.[/color]")
		return
	var upgraded_id : String = ItemID.MOBILITY_UPGRADES[item_id]
	if _inventory.has_item(upgraded_id):
		_print_output("[color=yellow]'" + item_id + "' is already upgraded to '" + upgraded_id + "'.[/color]")
		return
	if not _inventory.has_item(item_id):
		_print_output("[color=yellow]Player does not have '" + item_id + "'. Granting upgrade directly.[/color]")
	_inventory.remove_item(item_id, 1)
	_inventory.add_item(upgraded_id, 1)
	_print_output("[color=green]Upgraded '" + item_id + "' → '" + upgraded_id + "'.[/color]")

func _cmd_enable(parts : Array) -> void:
	if parts.size() >= 3 and parts[1].to_lower() == "verbose" and parts[2].to_lower() == "debug":
		var n = _set_debug_on_all(true, true)
		_print_output("[color=green]Verbose debug enabled on " + str(n) + " nodes.[/color]")
	elif parts.size() >= 2 and parts[1].to_lower() == "debug":
		var n = _set_debug_on_all(true, false)
		_print_output("[color=green]Debug enabled on " + str(n) + " nodes.[/color]")
	else:
		_print_output("[color=red]Usage: /enable debug | /enable verbose debug[/color]")

func _cmd_disable(parts : Array) -> void:
	if parts.size() >= 3 and parts[1].to_lower() == "verbose" and parts[2].to_lower() == "debug":
		var n = _set_debug_on_all(false, true)
		_print_output("[color=green]Verbose debug disabled on " + str(n) + " nodes.[/color]")
	elif parts.size() >= 2 and parts[1].to_lower() == "debug":
		var n = _set_debug_on_all(false, false)
		_print_output("[color=green]Debug disabled on " + str(n) + " nodes.[/color]")
	else:
		_print_output("[color=red]Usage: /disable debug | /disable verbose debug[/color]")

func _set_debug_on_all(enabled : bool, verbose_only : bool) -> int:
	return _debug_recurse(get_tree().root, enabled, verbose_only)

func _debug_recurse(node : Node, enabled : bool, verbose_only : bool) -> int:
	var count := 0
	if node.get("debug") is DebugSettings:
		if verbose_only:
			node.debug.debug_me_verbose = enabled
		else:
			node.debug.debug_me = enabled
		count += 1
	for child in node.get_children():
		count += _debug_recurse(child, enabled, verbose_only)
	return count

func _cmd_save() -> void:
	saveManager.save()
	_print_output("[color=green]Game saved.[/color]")

func _cmd_load() -> void:
	if saveManager.load_game():
		_print_output("[color=green]Save loaded.[/color]")
	else:
		_print_output("[color=red]No save file found.[/color]")

func _cmd_new_game(parts : Array) -> void:
	if parts.size() >= 2 and parts[1].to_lower() == "game":
		saveManager.new_game()
		_print_output("[color=green]Save deleted. Starting new game.[/color]")
	else:
		_print_output("[color=red]Usage: /new game[/color]")

#endregion COMMANDS

#region PERMANENT EFFECTS

func _apply_upgrade_permanent_effects(item_id: String, qty_before: int, qty_after: int) -> void:
	var mir : MenuItemResource = ItemID.MENU_ITEM_RESOURCES.get(item_id)
	var upgrade := mir as MenuItemUpgradeResource
	if not upgrade or not upgrade.item_function or not upgrade.item_function.has_permanent_effects():
		if not upgrade:
			_print_output("[color=yellow]DEBUG: No MenuItemUpgradeResource found for '" + item_id + "' — permanent effects skipped.[/color]")
		return
	for effect in upgrade.item_function.permanent_effects:
		var sets_to_apply : int = 0
		if effect.timing == EffectEnums.PermanentEffectTiming.ON_COMPLETE:
			sets_to_apply = int(float(qty_after) / upgrade.num_parts) - int(float(qty_before) / upgrade.num_parts)
		else:
			sets_to_apply = qty_after - qty_before
		_print_output("[color=gray]Applying " + str(sets_to_apply) + " set(s) of " + EffectEnums.PermanentEffectTarget.keys()[effect.target] + " for " + item_id + ".[/color]")
		for _i in range(sets_to_apply):
			match effect.target:
				EffectEnums.PermanentEffectTarget.MAX_HEALTH:
					if _health:
						_health.increase_max(effect.amount)
				EffectEnums.PermanentEffectTarget.MAX_ENERGY:
					if _energy:
						_energy.increase_max(effect.amount)
				EffectEnums.PermanentEffectTarget.MAX_MAGIC:
					if _magic:
						_magic.collect_shards(effect.amount)
				EffectEnums.PermanentEffectTarget.SPELL_POWER:
					if _magic:
						_magic.increase_spell_power(effect.amount)

#endregion PERMANENT EFFECTS

#region VALIDATION

##Checks if the given string matches any constant value in ItemID.
func _validate_item_id(item_id : String) -> bool:
	var constants = _get_all_item_ids()
	return item_id in constants

##Reads all constant values from the ItemID class dynamically.
func _get_all_item_ids() -> Array[String]:
	var result : Array[String] = []
	var script = load("res://Scripts/Constants/const_itemIDs.gd") as GDScript
	if script:
		var constants = script.get_script_constant_map()
		for key in constants:
			if constants[key] is String:
				result.append(constants[key])
	return result

#endregion VALIDATION

func _cmd_set(parts : Array) -> void:
	if parts.size() < 3:
		_print_output("[color=red]Usage: /set <target> <value>[/color]")
		_print_output("[color=gray]  /set wallet pocket|wallet|big[/color]")
		_print_output("[color=gray]  /set currency <amount>[/color]")
		_print_output("[color=gray]  /set health <amount>[/color]")
		_print_output("[color=gray]  /set <item_id> <quantity>[/color]")
		_print_output("[color=gray]  /set all <category> <quantity>[/color]")
		return
	var target = parts[1].to_lower()
	var value = parts[2].to_lower()
	match target:
		"wallet":
			_cmd_set_wallet(value)
		"currency":
			_cmd_set_currency(int(parts[2]))
		"health":
			_cmd_set_health(int(parts[2]))
		"all":
			_cmd_set_all(parts)
		_:
			_cmd_set_item(target, int(parts[2]))

func _cmd_set_wallet(wallet_type : String) -> void:
	if not _currency:
		_print_output("[color=red]No currency component found on player.[/color]")
		return
	match wallet_type:
		"pocket":
			_currency.max_notes = 99
		"wallet":
			_currency.max_notes = 999
		"big":
			_currency.max_notes = 9999
		_:
			_print_output("[color=red]Unknown wallet type: '" + wallet_type + "'. Use: pocket, wallet, big[/color]")
			return
	if _currency.cur_notes > _currency.max_notes:
		_currency.cur_notes = _currency.max_notes
	_print_output("[color=green]Wallet set to '" + wallet_type + "' (max: " + str(_currency.max_notes) + ").[/color]")

func _cmd_set_currency(amount : int) -> void:
	if not _currency:
		_print_output("[color=red]No currency component found on player.[/color]")
		return
	amount = clampi(amount, 0, _currency.max_notes)
	_currency.cur_notes = amount
	_currency.notes_changed.emit(_currency.cur_notes, _currency.max_notes, 0)
	_print_output("[color=green]Currency set to " + str(amount) + " / " + str(_currency.max_notes) + ".[/color]")

func _cmd_set_health(amount : int) -> void:
	if not _health:
		_print_output("[color=red]No health component found on player.[/color]")
		return
	amount = clampi(amount, 0, _health.max_health)
	var change = amount - _health.cur_health
	_health.cur_health = amount
	_health.health_changed.emit(_health.cur_health, _health.max_health, change)
	_print_output("[color=green]Health set to " + str(amount) + " / " + str(_health.max_health) + ".[/color]")

func _cmd_set_item(item_id : String, quantity : int) -> void:
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	if not _validate_item_id(item_id):
		_print_output("[color=yellow]Warning: '" + item_id + "' not found in ItemID constants. Setting anyway.[/color]")
	quantity = maxi(quantity, 0)
	_inventory.set_quantity(item_id, quantity)
	_print_output("[color=green]Set " + item_id + " to " + str(quantity) + ".[/color]")

func _cmd_set_all(parts : Array) -> void:
	if not _inventory:
		_print_output("[color=red]No inventory found on player.[/color]")
		return
	if parts.size() < 4:
		_print_output("[color=red]Usage: /set all <category> <quantity>[/color]")
		return
	var category = parts[2].to_lower()
	var quantity = int(parts[3])
	quantity = maxi(quantity, 0)
	if ItemID.CATEGORIES.has(category):
		var items = ItemID.CATEGORIES[category]
		for item_id in items:
			_inventory.set_quantity(item_id, quantity)
		_print_output("[color=green]Set all " + str(items.size()) + " " + category + " items to " + str(quantity) + ".[/color]")
	else:
		var valid = ", ".join(ItemID.CATEGORIES.keys())
		_print_output("[color=red]Unknown category: '" + category + "'. Valid: " + valid + "[/color]")

#endregion SET COMMAND

#region HELP

func _cmd_help() -> void:
	var text = "[color=white]Available commands:[/color]\n"
	text += "  [color=gray]/give <item_id> [quantity][/color]; Add items\n"
	text += "  [color=gray]/give all [category] [quantity][/color]; Add all items\n"
	text += "  [color=gray]/remove <item_id> [quantity][/color]; Remove items\n"
	text += "  [color=gray]/remove all [category][/color]; Remove all items\n"
	text += "  [color=gray]/set wallet pocket|wallet|big[/color]; Set wallet size\n"
	text += "  [color=gray]/set currency <amount>[/color]; Set currency\n"
	text += "  [color=gray]/set health <amount>[/color]; Set health\n"
	text += "  [color=gray]/set <item_id> <quantity>[/color]; Set item quantity\n"
	text += "  [color=gray]/set all <category> <quantity>[/color]; Set all in category\n"
	text += "  [color=gray]/upgrade <item_id>[/color]; Replace item with its upgrade\n"
	text += "  [color=gray]/list[/color]; Show inventory\n"
	text += "  [color=gray]/items[/color]; Show valid item IDs\n"
	text += "  [color=gray]/save[/color]; Save current game\n"
	text += "  [color=gray]/load[/color]; Load last save\n"
	text += "  [color=gray]/new game[/color]; Delete save and restart\n"
	text += "  [color=gray]/help[/color]; Show this message\n"
	_print_output(text)

#endregion HELP

#region UI BUILDING

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_bottom = 200.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.set_content_margin_all(8.0)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var vbox = VBoxContainer.new()
	_panel.add_child(vbox)
	_output_label = RichTextLabel.new()
	_output_label.bbcode_enabled = true
	_output_label.scroll_following = true
	_output_label.custom_minimum_size = Vector2(0, 140)
	_output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_output_label)
	_input_field = LineEdit.new()
	_input_field.placeholder_text = "Type /help for a list of possible commands"
	_input_field.gui_input.connect(_on_input_gui_input)
	_input_field.focus_exited.connect(_on_input_focus_lost)
	vbox.add_child(_input_field)

func _on_input_focus_lost() -> void:
	print("CONSOLE: focus_exited fired. is_open=", _is_open, " panel_visible=", _panel.visible)
	if _is_open:
		print("CONSOLE: attempting deferred grab_focus")
		_input_field.call_deferred("grab_focus")

func log(text : String) -> void:
	_print_output(text)

func _print_output(text : String) -> void:
	_output_label.append_text(text + "\n")

#endregion UI BUILDING

#endregion FUNCTIONS
