##[b][color=red]EnergyDisplay[/color][/b] extends [b]RecoverableResourceDisplay[/b] for the player's energy bolt display.[br]
##Manages bolt fill states, exhausted flashing, and positions relative to the player.
class_name EnergyDisplay
extends RecoverableResourceDisplay

#region VARIABLES

##Whether the player is currently exhausted (0 energy).
var _is_exhausted : bool = false

#endregion VARIABLES

#region VIRTUAL METHOD OVERRIDES

func _get_change_signal_name() -> String:
	return "energy_changed"

func _get_element_count() -> int:
	return _component.max_bolts if _component else 0

func _on_additional_initialization() -> void:
	if debug_me:
		print_rich(debug_name, ": [color=green][i]initialized[/i][/color] with [i]", _component.max_bolts, "[/i] bolts.")

#endregion VIRTUAL METHOD OVERRIDES

#region FUNCTIONS

#region BOLT MANAGEMENT

##Updates all bolt displays based on current energy.
func _update_bolts(cur_energy : int) -> void:
	var bolts = gui_container.get_children()
	var active_idx = clampi(int(ceil(float(cur_energy) / 4.0)) - 1, 0, bolts.size() - 1)
	for i in range(bolts.size()):
		var bolt = bolts[i] as EnergyBoltGUI
		if bolt:
			var bolt_fill = clampi(cur_energy - (i * 4), 0, 4)
			bolt.update(bolt_fill)
			if bolt_fill > 0 and i == active_idx:
				bolt.play_active_anim()
			else:
				bolt.stop_active_anim()
	_apply_active_styling(active_idx)

#endregion BOLT MANAGEMENT

#region ENERGY CHANGE HANDLER

func _on_component_changed(cur_energy : int, max_energy : int, change_amount : int) -> void:
	var was_exhausted = _is_exhausted
	_is_exhausted = _component.is_exhausted_state
	if change_amount < 0:
		var bolts = gui_container.get_children()
		var flash_idx = clampi(int(ceil(float(cur_energy) / 4.0)) - 1, 0, bolts.size() - 1)
		if flash_idx >= 0 and flash_idx < bolts.size():
			var bolt = bolts[flash_idx] as EnergyBoltGUI
			if bolt:
				bolt.play_use_flash()
	_update_bolts(cur_energy)
	if _is_exhausted and not was_exhausted:
		_start_exhausted_flash()
		force_show(true)
	elif was_exhausted and not _is_exhausted:
		_stop_exhausted_flash()
		force_show(false)
	elif _is_exhausted:
		show_element()
	else:
		show_element()
	if debug_me:
		print_rich(debug_name, ": [i]energy changed[/i] by [i]", change_amount, "[/i]. Now: [i]", cur_energy, "/", max_energy, "[/i] exhausted=[i]", _is_exhausted, "[/i]")

#endregion ENERGY CHANGE HANDLER

#region FLASH EFFECTS

func _start_exhausted_flash() -> void:
	for bolt in gui_container.get_children():
		if bolt is EnergyBoltGUI:
			bolt.start_exhausted_flash()
	if debug_me:
		print_rich(debug_name, ": [color=red][i]exhausted flash started[/i][/color].")

func _stop_exhausted_flash() -> void:
	for bolt in gui_container.get_children():
		if bolt is EnergyBoltGUI:
			bolt.stop_exhausted_flash()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]exhausted flash stopped[/i][/color].")

func do_recovery_flash() -> void:
	for bolt in gui_container.get_children():
		if bolt is EnergyBoltGUI:
			bolt.do_recovery_flash()
	show_element()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]recovery flash triggered[/i][/color].")

#endregion FLASH EFFECTS

#region POSITIONING

func update_position() -> void:
	if not _player_body:
		return
	var screen_pos = _get_player_screen_pos()
	var corner_dir = CORNER_OFFSETS[0]
	var bolt_count = gui_container.get_child_count() if gui_container else 1
	var total_height = bolt_count * 16.0 + max(0, bolt_count - 1) * stack_spacing
	var offset = Vector2.ZERO
	offset.x = corner_dir.x * offset_distance
	if corner_dir.x < 0:
		offset.x -= 16.0
	offset.y = corner_dir.y * offset_distance
	if corner_dir.y < 0:
		offset.y -= total_height
	global_position = screen_pos + offset

#endregion POSITIONING

##Sets the maximum number of bolts and rebuilds the display.
func set_max_bolts(max_bolts : int) -> void:
	_build_gui_elements(max_bolts)
	if _component:
		_update_bolts.call_deferred(_component.cur_energy)

#endregion FUNCTIONS
