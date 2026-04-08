##[b][color=red]MagicDisplay[/color][/b] extends [b]UXDisplayElement[/b] for the player's magic medallion display.[br]
##Manages medallion shard/fill states and positions relative to the energy display.
class_name MagicDisplay
extends UXDisplayElement

#region VARIABLES

@export_category("Magic Components")
##Reference to the energy display for positioning relative to it.
@export var energy_display : EnergyDisplay

@export_category("Magic Positioning")
##The vertical gap between the energy display and the magic display.
@export var energy_offset : float = 16.0
##The pixel offset from the player's screen position (used if energy display is not available).
@export var fallback_offset_distance : float = 56.0

var _magic_component : MagicComponent

#endregion VARIABLES

#region FUNCTIONS

##Initializes the magic display with the magic component and player references.
func initialize(magic_comp : MagicComponent, player_body : CharacterBody2D, player_cam : CamClass) -> void:
	_magic_component = magic_comp
	if _magic_component:
		if not _magic_component.magic_changed.is_connected(_on_magic_changed):
			_magic_component.magic_changed.connect(_on_magic_changed)
		if not _magic_component.shard_collected.is_connected(_on_shard_collected):
			_magic_component.shard_collected.connect(_on_shard_collected)
	initialize_display(player_body, player_cam)

func _on_display_initialized() -> void:
	_rebuild_medallions()
	_update_medallions()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]initialized[/i][/color] with [i]", _magic_component.get_medallion_count(), "[/i] medallions.")

func _can_fade_out() -> bool:
	return _magic_component and _magic_component.is_full()

#region MEDALLION MANAGEMENT

##Rebuilds the medallion GUI instances based on current shard count.
func _rebuild_medallions() -> void:
	if not _magic_component:
		return
	_build_gui_elements(_magic_component.get_medallion_count())

##Updates all medallion displays based on current magic.
func _update_medallions() -> void:
	if not gui_container or not _magic_component:
		return
	var medallions_data : Array = _calculate_medallion_data()
	var gui_children = gui_container.get_children()
	var active_idx = -1
	for i in range(medallions_data.size()):
		if medallions_data[i]["fill"] > 0:
			active_idx = i
	for i in range(gui_children.size()):
		var gui = gui_children[i] as MagicMedallionGUI
		if gui and i < medallions_data.size():
			var data = medallions_data[i]
			gui.update(data["shards"], data["fill"])
			if data["fill"] > 0 and i == active_idx:
				gui.play_active_anim()
			else:
				gui.stop_active_anim()
	_apply_active_styling(active_idx)

##Calculates the shard count and fill for each medallion in fill order.
func _calculate_medallion_data() -> Array:
	var result : Array = []
	var cur_magic = _magic_component.cur_magic
	var complete_count = _magic_component.get_complete_medallion_count()
	var partial_shards = _magic_component.get_partial_medallion_shards()
	var remaining_magic = cur_magic
	for i in range(complete_count):
		var fill = clampi(remaining_magic, 0, 6)
		result.append({ "shards": 6, "fill": fill })
		remaining_magic -= fill
	if partial_shards > 0:
		var fill = clampi(remaining_magic, 0, partial_shards)
		result.append({ "shards": partial_shards, "fill": fill })
	return result

#endregion MEDALLION MANAGEMENT

#region MAGIC CHANGE HANDLER

func _on_magic_changed(cur_magic : int, max_magic : int, change_amount : int) -> void:
	if change_amount < 0:
		var gui_children = gui_container.get_children()
		var medallions_data = _calculate_medallion_data()
		var flash_idx = -1
		for i in range(medallions_data.size()):
			if medallions_data[i]["fill"] > 0:
				flash_idx = i
		if flash_idx >= 0 and flash_idx < gui_children.size():
			var gui = gui_children[flash_idx] as MagicMedallionGUI
			if gui:
				gui.play_use_flash()
	_update_medallions()
	show_element()
	if debug_me:
		print_rich(debug_name, ": [i]magic changed[/i] by [i]", change_amount, "[/i]. Now: [i]", cur_magic, "/", max_magic, "[/i]")

func _on_shard_collected(total_shards : int) -> void:
	_rebuild_medallions()
	_update_medallions()
	show_element()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]shard collected[/i][/color]! Total: [i]", total_shards, "[/i]. Rebuilding display.")

#endregion MAGIC CHANGE HANDLER

#region POSITIONING

func update_position() -> void:
	if _player_body and energy_display:
		var screen_pos = _get_player_screen_pos()
		var corner_dir = energy_display.CORNER_OFFSETS[0]
		var bolt_count = energy_display.gui_container.get_child_count() if energy_display.gui_container else 1
		var total_height = bolt_count * 16.0 + max(0, bolt_count - 1) * energy_display.stack_spacing
		var energy_offset_calc = Vector2.ZERO
		energy_offset_calc.x = corner_dir.x * energy_display.offset_distance
		if corner_dir.x < 0:
			energy_offset_calc.x -= 16.0
		energy_offset_calc.y = corner_dir.y * energy_display.offset_distance
		if corner_dir.y < 0:
			energy_offset_calc.y -= total_height
		var energy_pos = screen_pos + energy_offset_calc
		var energy_diagonal_end = bolt_count * energy_display.stack_spacing
		global_position = Vector2(energy_pos.x + energy_diagonal_end, energy_pos.y + energy_diagonal_end + energy_offset)
	elif _player_body:
		var screen_pos = _get_player_screen_pos()
		global_position = screen_pos + Vector2(fallback_offset_distance, -fallback_offset_distance + energy_offset)

#endregion POSITIONING

##Sets the maximum shards and rebuilds the display.
func set_total_shards(shards : int) -> void:
	if _magic_component:
		_magic_component.total_shards = shards
		_magic_component.max_magic = shards
	_rebuild_medallions()
	_update_medallions()

#endregion FUNCTIONS
