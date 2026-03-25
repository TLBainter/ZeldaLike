##[b][color=red]DebugConsole[/color][/b] is a simple in-game text prompt for debug commands.[br]
##Press TAB to open/close. Type commands and press Enter to execute.[br]
##[br]
##[b]Commands:[/b][br]
##[code]/give item_id quantity[/code] — Adds items to player inventory. Quantity defaults to 1.[br]
##[code]/remove item_id quantity[/code] — Removes items from player inventory. Quantity defaults to 1.[br]
##[code]/list[/code] — Prints all current inventory contents.[br]
##[code]/items[/code] — Prints all valid ItemID constants.[br]
class_name DebugCommandLine
extends CanvasLayer

#region VARIABLES

var _input_field : LineEdit
var _output_label : RichTextLabel
var _panel : PanelContainer
var _is_open : bool = false
var _inventory : InventoryComponent = null

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
	_is_open = true
	_panel.visible = true
	_input_field.text = ""
	_input_field.grab_focus()
	#Find inventory if we don't have it yet.
	if not _inventory:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty() and "inventory" in players[0]:
			_inventory = players[0].inventory

func _close() -> void:
	_is_open = false
	_panel.visible = false
	_input_field.release_focus()

func _on_text_submitted(text : String) -> void:
	_input_field.text = ""
	text = text.strip_edges()
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
		"/list":
			_cmd_list()
		"/items":
			_cmd_items()
		_:
			_print_output("[color=red]Unknown command: " + command + "[/color]")

#region COMMANDS

func _cmd_give(parts : Array) -> void:
	if parts.size() < 2:
		_print_output("[color=red]Usage: /give item_id [quantity][/color]")
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
	_inventory.add_item(item_id, quantity)
	_print_output("[color=green]Gave " + str(quantity) + "x " + item_id + ". Total: " + str(_inventory.get_quantity(item_id)) + "[/color]")

func _cmd_remove(parts : Array) -> void:
	if parts.size() < 2:
		_print_output("[color=red]Usage: /remove item_id [quantity][/color]")
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

#endregion COMMANDS

#region VALIDATION

##Checks if the given string matches any constant value in ItemID.
func _validate_item_id(item_id : String) -> bool:
	var constants = _get_all_item_ids()
	return item_id in constants

##Reads all constant values from the ItemID class dynamically.
func _get_all_item_ids() -> Array[String]:
	var result : Array[String] = []
	var props = ItemID.new().get_property_list()
	#ItemID uses const, which won't show in property list.
	#Instead, we use the script's get_script_constant_map.
	var script = load("res://Scripts/Constants/const_itemIDs.gd") as GDScript
	if script:
		var constants = script.get_script_constant_map()
		for key in constants:
			if constants[key] is String:
				result.append(constants[key])
	return result

#endregion VALIDATION

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
	_input_field.placeholder_text = "Type a command... (/give, /remove, /list, /items)"
	_input_field.text_submitted.connect(_on_text_submitted)
	vbox.add_child(_input_field)

func _print_output(text : String) -> void:
	_output_label.append_text(text + "\n")

#endregion UI BUILDING

#endregion FUNCTIONS
