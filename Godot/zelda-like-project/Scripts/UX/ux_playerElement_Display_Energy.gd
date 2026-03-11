##[b][color=red]EnergyDisplay[/color][/b] extends [b]UXDisplayElement[/b] for the player's energy bolt display.[br]
##Manages bolt fill states, exhausted flashing, and positions relative to the player.
class_name EnergyDisplay
extends UXDisplayElement

#region VARIABLES

@export_category("Energy Components")
##The maximum number of bolts. Each bolt holds 4 energy.
var _energy_component : EnergyComponent

#=======INTERNAL VARIABLES=======#

##Whether the player is currently exhausted (0 energy).
var _is_exhausted : bool = false

#endregion VARIABLES

#region FUNCTIONS

##Initializes the energy display with the energy component and player references.
func initialize(energy_comp : EnergyComponent, player_body : CharacterBody2D, player_cam : CamClass) -> void:
	_energy_component = energy_comp
	if _energy_component and not _energy_component.energyChanged.is_connected(_on_energy_changed):
		_energy_component.energyChanged.connect(_on_energy_changed)
	initialize_display(player_body, player_cam)

func _on_display_initialized() -> void:
	_build_gui_elements(_energy_component.max_bolts)
	_update_bolts(_energy_component.cur_energy)
	if debug_me:
		print(debug_name, " initialized with ", _energy_component.max_bolts, " bolts.")

func _can_fade_out() -> bool:
	return _energy_component and _energy_component.is_full()

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

func _on_energy_changed(cur_energy : int, max_energy : int, change_amount : int) -> void:
	var was_exhausted = _is_exhausted
	_is_exhausted = _energy_component.is_exhausted_state
	#Trigger use flash on decrease.
	if change_amount < 0:
		var bolts = gui_container.get_children()
		var flash_idx = clampi(int(ceil(float(cur_energy) / 4.0)) - 1, 0, bolts.size() - 1)
		if flash_idx >= 0 and flash_idx < bolts.size():
			var bolt = bolts[flash_idx] as EnergyBoltGUI
			if bolt:
				bolt.play_use_flash()
	_update_bolts(cur_energy)
	#Exhaustion state changes.
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
		print(debug_name, ": Energy changed by ", change_amount, ". Now: ", cur_energy, "/", max_energy, " exhausted=", _is_exhausted)

#endregion ENERGY CHANGE HANDLER

#region FLASH EFFECTS

func _start_exhausted_flash() -> void:
	for bolt in gui_container.get_children():
		if bolt is EnergyBoltGUI:
			bolt.start_exhausted_flash()
	if debug_me:
		print(debug_name, ": Exhausted flash started.")

func _stop_exhausted_flash() -> void:
	for bolt in gui_container.get_children():
		if bolt is EnergyBoltGUI:
			bolt.stop_exhausted_flash()
	if debug_me:
		print(debug_name, ": Exhausted flash stopped.")

func do_recovery_flash() -> void:
	for bolt in gui_container.get_children():
		if bolt is EnergyBoltGUI:
			bolt.do_recovery_flash()
	show_element()
	if debug_me:
		print(debug_name, ": Recovery flash triggered.")

#endregion FLASH EFFECTS

#region POSITIONING

func update_position() -> void:
	if not _player_body:
		return
	var screen_pos = _get_player_screen_pos()
	var corner_dir = CORNER_OFFSETS[_current_corner]
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
	if _energy_component:
		_update_bolts(_energy_component.cur_energy)

#endregion FUNCTIONS
