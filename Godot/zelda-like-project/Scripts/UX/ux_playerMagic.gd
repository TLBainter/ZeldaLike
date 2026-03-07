##[b][color=red]MagicDisplay[/color][/b] controls the overall magic medallion display in the player UI.[br]
##Manages individual [b]MagicMedallionGUI[/b] elements, positions them relative to the energy display,[br]
##and handles visibility states.[br]
##[br]
##[b]Positioning[/b]: Appears 16px below the energy display (upper corner) or 16px above (lower corner).[br]
##Medallions are stacked vertically, with the active/partial medallion on top.[br]
##[br]
##[b]Visibility Rules[/b]:[br]
##- Starts hidden.[br]
##- Shows when magic changes. Fades after 3 seconds if magic is full.[br]
##- No exhaustion mechanic for magic.
class_name MagicDisplay
extends Control

#region VARIABLES

@export_category("Magic Display Components")
##A reference to the magic medallion GUI scene. Must have [b]MagicMedallionGUI[/b] as its root.
@export var medallion_gui_scene : PackedScene
##A reference to the main UI control node.
@export var root : PlayerUX
##The container node that holds the medallion GUI instances.
@export var medallion_container : Control
##Reference to the energy display for positioning relative to it.
@export var energy_display : EnergyDisplay

@export_category("Magic Display Settings")
@export_group("Positioning")
##The vertical gap between the energy display and the magic display.
@export var energy_offset : float = 16.0
##The pixel offset from the player's screen position (used if energy display is not available).
@export var fallback_offset_distance : float = 56.0
##The vertical spacing between stacked medallions.
@export var medallion_stack_spacing : float = 8.0

@export_group("Visibility")
##How long the magic display stays visible after magic changes (in seconds).
@export var visibility_duration : float = 3.0
@export var fade_in_speed : float = 12.0
@export var fade_out_speed : float = 2.0

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "MagicDisplay"

#=======INTERNAL VARIABLES=======#

##The player's body reference for fallback positioning.
var _player_body : CharacterBody2D
##The player's camera reference.
var _player_cam : CamClass
##The magic component reference.
var _magic_component : MagicComponent

##Current target alpha for fade in/out.
var _target_alpha : float = 0.0
##Whether the display is currently forced visible.
var _force_visible : bool = false
##Timer reference for visibility countdown.
var _visibility_timer : Timer

##The active magic medallion in the index
var _active_medallion_index : int = -1

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	modulate.a = 0.0
	_target_alpha = 0.0
	set_process(false)
	_visibility_timer = Timer.new()
	_visibility_timer.one_shot = true
	_visibility_timer.wait_time = visibility_duration
	_visibility_timer.timeout.connect(_on_visibility_timeout)
	add_child(_visibility_timer)

##Initializes the magic display with references and creates medallion GUI instances.[br]
##Called by PlayerUX after all components are ready.
func initialize(magic_comp : MagicComponent, player_body : CharacterBody2D, player_cam : CamClass) -> void:
	_magic_component = magic_comp
	_player_body = player_body
	_player_cam = player_cam
	if _magic_component:
		if not _magic_component.magicChanged.is_connected(_on_magic_changed):
			_magic_component.magicChanged.connect(_on_magic_changed)
		if not _magic_component.shardCollected.is_connected(_on_shard_collected):
			_magic_component.shardCollected.connect(_on_shard_collected)
	_rebuild_medallions()
	_update_medallions()
	if debug_me:
		print(debug_name, " initialized with ", _magic_component.get_medallion_count(), " medallions.")

#region MEDALLION MANAGEMENT

##Rebuilds the medallion GUI instances based on current shard count.
func _rebuild_medallions() -> void:
	if not medallion_container:
		print("ERROR: medallion_container is null!")
		return
	if not _magic_component:
		print("ERROR: _magic_component is null!")
		return
	print("Building medallions. Container: ", medallion_container, " child count before: ", medallion_container.get_child_count())
	for child in medallion_container.get_children():
		child.queue_free()
	var medallion_count = _magic_component.get_medallion_count()
	for i in range(medallion_count):
		var medallion = medallion_gui_scene.instantiate()
		medallion_container.add_child(medallion)
		var reverse_i = medallion_count - 1 - i
		medallion.position = Vector2(reverse_i * medallion_stack_spacing, reverse_i * medallion_stack_spacing)
		print("Built medallion ", i, " at position ", medallion.position, " visible: ", medallion.visible)

##Updates all medallion displays based on current magic.[br]
##Fills from bottom to top (first complete medallion fills first),[br]
##but displays top to bottom (active/partial on top).
func _update_medallions() -> void:
	if not medallion_container or not _magic_component:
		return
	var medallions_data : Array = _calculate_medallion_data()
	var gui_children = medallion_container.get_children()
	var active_index = -1
	for i in range(medallions_data.size()):
		if medallions_data[i]["fill"] > 0:
			active_index = i
	var prev_active = _active_medallion_index if _active_medallion_index >= 0 else active_index
	_active_medallion_index = active_index
	#Display order is reversed: index 0 in gui = top = last medallion (partial/active).
	for i in range(gui_children.size()):
		var gui = gui_children[i] as MagicMedallionGUI
		if gui and i < medallions_data.size():
			var data = medallions_data[i]
			gui.update(data["shards"], data["fill"])
			if data["fill"] > 0 and i == active_index:
				gui.modulate = Color(1, 1, 1, 1)
				gui.z_index = 1
				gui.play_active_anim()
			else:
				gui.modulate = Color(0.5, 0.5, 0.5, 1)
				gui.z_index = 0
				gui.stop_active_anim()

##Calculates the shard count and fill for each medallion in fill order (bottom to top).[br]
##Returns an array of dictionaries: [{ "shards": int, "fill": int }, ...]
func _calculate_medallion_data() -> Array:
	var result : Array = []
	var total_shards = _magic_component.total_shards
	var cur_magic = _magic_component.cur_magic
	var complete_count = _magic_component.get_complete_medallion_count()
	var partial_shards = _magic_component.get_partial_medallion_shards()
	var remaining_magic = cur_magic
	#Complete medallions first (fill order: first to last).
	for i in range(complete_count):
		var fill = clampi(remaining_magic, 0, 6)
		result.append({ "shards": 6, "fill": fill })
		remaining_magic -= fill
	#Partial medallion last (if any).
	if partial_shards > 0:
		var fill = clampi(remaining_magic, 0, partial_shards)
		result.append({ "shards": partial_shards, "fill": fill })
	return result

#endregion MEDALLION MANAGEMENT

#region MAGIC CHANGE HANDLER

##Called when the magic component emits magicChanged.
func _on_magic_changed(cur_magic : int, max_magic : int, change_amount : int) -> void:
	if change_amount < 0:
		var gui_children = medallion_container.get_children()
		var medallions_data = _calculate_medallion_data()
		var flash_index = -1
		for i in range(medallions_data.size()):
			if medallions_data[i]["fill"] > 0:
				flash_index = i
		if flash_index >= 0 and flash_index < gui_children.size():
			var gui = gui_children[flash_index] as MagicMedallionGUI
			if gui:
				gui.play_use_flash()
	_update_medallions()
	show_magic()
	if debug_me:
		print(debug_name, ": Magic changed by ", change_amount, ". Now: ", cur_magic, "/", max_magic)

##Called when a new shard is collected. Rebuilds the display.
func _on_shard_collected(total_shards : int) -> void:
	_rebuild_medallions()
	_update_medallions()
	show_magic()
	if debug_me:
		print(debug_name, ": Shard collected! Total: ", total_shards, ". Rebuilding display.")

#endregion MAGIC CHANGE HANDLER

#region VISIBILITY CONTROL

##Makes the magic display visible and starts the visibility countdown.
func show_magic() -> void:
	if debug_me:
		print("show_magic called! modulate.a before: ", modulate.a)
	_target_alpha = 1.0
	_visibility_timer.stop()
	_visibility_timer.start(visibility_duration)
	set_process(true)
	update_position()
	if debug_me:
		print("show_magic done! modulate.a after: ", modulate.a, " position: ", global_position)


##Called when the visibility timer expires. Begins fading out.
func _on_visibility_timeout() -> void:
	if _force_visible:
		return
	if _magic_component and _magic_component.is_full():
		_target_alpha = 0.0

##Forces the magic display to stay visible.
func force_show(should_force : bool) -> void:
	_force_visible = should_force
	if should_force:
		_target_alpha = 1.0
		_visibility_timer.stop()
		set_process(true)
		update_position()
	else:
		_visibility_timer.start(visibility_duration)

#endregion VISIBILITY CONTROL

#region PROCESS AND POSITIONING

func _process(delta : float) -> void:
	if modulate.a > 0.0:
		update_position()
	if modulate.a != _target_alpha:
		var speed = fade_in_speed if _target_alpha > modulate.a else fade_out_speed
		modulate.a = move_toward(modulate.a, _target_alpha, speed * delta)
		if modulate.a <= 0.0:
			modulate.a = 0.0
			if not _force_visible:
				set_process(false)

##Updates the screen-space position of the magic display.[br]
##Positions 16px below the energy display if it exists, otherwise falls back to player offset.
func update_position():
	if _player_body and energy_display:
		#Calculate where energy would be positioned, regardless of whether it's visible.
		var screen_pos = _player_body.get_global_transform_with_canvas().origin
		var corner_dir = energy_display.CORNER_OFFSETS[energy_display._current_corner]
		var bolt_count = energy_display.bolt_container.get_child_count() if energy_display.bolt_container else 1
		var total_height = bolt_count * 16.0 + max(0, bolt_count - 1) * energy_display.bolt_stack_spacing
		var energy_offset_calc = Vector2.ZERO
		energy_offset_calc.x = corner_dir.x * energy_display.offset_distance
		if corner_dir.x < 0:
			energy_offset_calc.x -= 16.0
		energy_offset_calc.y = corner_dir.y * energy_display.offset_distance
		if corner_dir.y < 0:
			energy_offset_calc.y -= total_height
		var energy_pos = screen_pos + energy_offset_calc
		var energy_diagonal_end = bolt_count * energy_display.bolt_stack_spacing
		global_position = Vector2(energy_pos.x + energy_diagonal_end, energy_pos.y + energy_diagonal_end + energy_offset)
		#Fallback: position relative to player.
	elif _player_body:
		var screen_pos = _player_body.get_global_transform_with_canvas().origin
		global_position = screen_pos + Vector2(fallback_offset_distance, -fallback_offset_distance + energy_offset)

#endregion PROCESS AND POSITIONING

##Sets the maximum shards and rebuilds the display.
func set_total_shards(shards : int) -> void:
	if _magic_component:
		_magic_component.total_shards = shards
		_magic_component.max_magic = shards
	_rebuild_medallions()
	_update_medallions()

#endregion FUNCTIONS
