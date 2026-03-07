##[b][color=red]EnergyDisplay[/color][/b] controls the overall energy bolt display in the player UI.[br]
##Manages individual [b]EnergyBoltGUI[/b] elements, positions them relative to the player's body,[br]
##and handles visibility states, corner overlap detection, and flash effects.[br]
class_name EnergyDisplay
extends Control

#region VARIABLES

@export_category("Energy Display Components")
##A reference to the energy bolt GUI scene. Must have [b]EnergyBoltGUI[/b] as its root.
@export var bolt_gui_scene : PackedScene
##A reference to the main UI control node.
@export var root : PlayerUX
##The container node that holds the bolt GUI instances.
@export var bolt_container : Control

@export_category("Energy Display Settings")
@export_group("Positioning")
##The pixel offset from the player's screen position to the energy display.
@export var offset_distance : float = 40.0
##The vertical spacing between stacked bolts.[br]
##Should match the GridContainer's V Separation if using one.
@export var bolt_stack_spacing : float = 8.0

@export_group("Visibility")
##How long the energy display stays visible after energy is used (in seconds).
@export var visibility_duration : float = 3.0
##How fast the energy display fades in (higher = faster).
@export var fade_in_speed : float = 12.0
##How fast the energy display fades out (lower = slower).
@export var fade_out_speed : float = 2.0

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "EnergyDisplay"

#=======INTERNAL VARIABLES=======#

##The player's body reference for screen-space positioning.
var _player_body : CharacterBody2D
##The player's camera reference for coordinate conversion.
var _player_cam : CamClass
##The energy component reference.
var _energy_component : EnergyComponent

##Current target alpha for fade in/out.
var _target_alpha : float = 0.0
##Whether the display is currently forced visible (exhausted, zoom, etc.)
var _force_visible : bool = false
##Whether the player is currently exhausted (0 energy).
var _is_exhausted : bool = false
##Timer reference for visibility countdown.
var _visibility_timer : Timer

##The four corner offset directions, in priority order.[br]
##Top-right, top-left, bottom-left, bottom-right.
const CORNER_OFFSETS : Array[Vector2] = [
	Vector2(1, -1),   # top-right
	Vector2(-1, -1),  # top-left
	Vector2(-1, 1),   # bottom-left
	Vector2(1, 1),    # bottom-right
]

##The currently selected corner index.
var _current_corner : int = 0

##The active bolt in the UI
var _active_bolt_index : int = -1

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	###===STARTS HIDDEN===###
	modulate.a = 0.0
	_target_alpha = 0.0
	set_process(false)
	###===END STARTS HIDDEN===###
	_visibility_timer = Timer.new()
	_visibility_timer.one_shot = true
	_visibility_timer.wait_time = visibility_duration
	_visibility_timer.timeout.connect(_on_visibility_timeout)
	add_child(_visibility_timer)

##Initializes the energy display with references and creates bolt GUI instances.[br]
##Called by PlayerUX after all components are ready.
func initialize(energy_comp : EnergyComponent, player_body : CharacterBody2D, player_cam : CamClass) -> void:
	_energy_component = energy_comp
	_player_body = player_body
	_player_cam = player_cam
	if _energy_component and not _energy_component.energyChanged.is_connected(_on_energy_changed):
		_energy_component.energyChanged.connect(_on_energy_changed)
	_build_bolts(_energy_component.max_bolts)
	_update_bolts(_energy_component.cur_energy)
	if debug_me:
		print(debug_name, " initialized with ", _energy_component.max_bolts, " bolts.")

##Creates bolt GUI instances based on the number of max bolts.
func _build_bolts(max_bolts : int) -> void:
	if bolt_container:
		print("Building bolts. Container: ", bolt_container, " child count before: ", bolt_container.get_child_count())
		for child in bolt_container.get_children():
			child.queue_free()
	else:
		print("ERROR: bolt_container is null!")
		return
	for i in range(max_bolts):
		var bolt = bolt_gui_scene.instantiate()
		bolt_container.add_child(bolt)
		var reverse_i = max_bolts - 1 - i
		bolt.position = Vector2(reverse_i * bolt_stack_spacing, reverse_i * bolt_stack_spacing)
		print("Built bolt ", i, " at position ", bolt.position, " visible: ", bolt.visible)

##Updates all bolt displays based on current energy.
func _update_bolts(cur_energy : int) -> void:
	var bolts = bolt_container.get_children()
	var active_index = clampi(int(ceil(float(cur_energy) / 4.0)) - 1, 0, bolts.size() - 1)
	var prev_active = _active_bolt_index if _active_bolt_index >= 0 else active_index
	_active_bolt_index = active_index
	for i in range(bolts.size()):
		var bolt = bolts[i] as EnergyBoltGUI
		if bolt:
			var bolt_fill = clampi(cur_energy - (i * 4), 0, 4)
			bolt.update(bolt_fill)
			if bolt_fill > 0 and i == active_index:
				bolt.modulate = Color(1, 1, 1, 1)
				bolt.z_index = 1
				#play the active bolt animation
				bolt.play_active_anim()
			else:
				bolt.modulate = Color(0.5, 0.5, 0.5, 1)
				bolt.z_index = 0
				#stop the active bolt animation
				bolt.stop_active_anim()


#region ENERGY CHANGE HANDLER

##Called when the energy component emits energyChanged.
func _on_energy_changed(cur_energy : int, max_energy : int, change_amount : int):
	var was_exhausted = _is_exhausted
	_is_exhausted = _energy_component.is_exhausted_state
	if change_amount < 0:
		var bolts = bolt_container.get_children()
		var flash_index = clampi(int(ceil(float(cur_energy) / 4.0)) - 1, 0, bolts.size() -1)
		if flash_index >= 0 and flash_index < bolts.size():
			var bolt = bolts[flash_index] as EnergyBoltGUI
			if bolt:
				bolt.play_use_flash()
	_update_bolts(cur_energy)
#JUST HIT 0: start exhausted flash, force visible.
	if _is_exhausted and not was_exhausted:
		_start_exhausted_flash()
		force_show(true)
	#RECOVERED FROM EXHAUSTION TO FULL: stop flash, release force.
	elif was_exhausted and not _is_exhausted:
		_stop_exhausted_flash()
		force_show(false)
	#STILL EXHAUSTED: keep visible, keep flashing.
	elif _is_exhausted:
		show_energy()
	#NORMAL CHANGE: show briefly.
	else:
		show_energy()
	if debug_me:
		print(debug_name, ": Energy changed by ", change_amount, ". Now: ", cur_energy, "/", max_energy, " exhausted=", _is_exhausted)

#endregion ENERGY CHANGE HANDLER

#region VISIBILITY CONTROL

##Makes the energy display visible and starts the visibility countdown.
func show_energy() -> void:
	if debug_me:
		print("show_energy called! modulate.a before: ", modulate.a)
	_target_alpha = 1.0
	_visibility_timer.stop()
	_visibility_timer.start(visibility_duration)
	set_process(true)
	update_position()
	if debug_me:
		print("show_energy done! modulate.a after: ", modulate.a, " position: ", global_position)

##Called when the visibility timer expires. Begins fading out.[br]
##Does not fade if force_visible is active (exhausted, zoomed, etc.)
func _on_visibility_timeout() -> void:
	if _force_visible:
		return
	if _energy_component and _energy_component.is_full():
		_target_alpha = 0.0

##Forces the energy display to stay visible (e.g., during exhaustion or zoom).
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

#region FLASH EFFECTS

##Starts the red exhausted flash on all bolts with energy remaining.
func _start_exhausted_flash() -> void:
	var bolts = bolt_container.get_children()
	for bolt in bolts:
		if bolt is EnergyBoltGUI:
			bolt.start_exhausted_flash()
	if debug_me:
		print(debug_name, ": Exhausted flash started.")

##Stops the red exhausted flash on all bolts.
func _stop_exhausted_flash() -> void:
	var bolts = bolt_container.get_children()
	for bolt in bolts:
		if bolt is EnergyBoltGUI:
			bolt.stop_exhausted_flash()
	if debug_me:
		print(debug_name, ": Exhausted flash stopped.")

##Triggers a one-shot white flash on all bolts (recovery pickup/potion).
func do_recovery_flash() -> void:
	var bolts = bolt_container.get_children()
	for bolt in bolts:
		if bolt is EnergyBoltGUI:
			bolt.do_recovery_flash()
	show_energy()
	if debug_me:
		print(debug_name, ": Recovery flash triggered.")

#endregion FLASH EFFECTS

#region PROCESS AND POSITIONING

func _process(delta : float) -> void:
	#Update position every frame while visible.
	if modulate.a > 0.0:
		update_position()
	#Handle fade.
	if modulate.a != _target_alpha:
		var speed = fade_in_speed if _target_alpha > modulate.a else fade_out_speed
		modulate.a = move_toward(modulate.a, _target_alpha, speed * delta)
		if modulate.a <= 0.0:
			modulate.a = 0.0
			if not _force_visible:
				set_process(false)

##Updates the screen-space position of the energy display based on the player's body position.
func update_position() -> void:
	if not _player_body or not _player_cam:
		return
	var screen_pos = _player_body.get_global_transform_with_canvas().origin
	var corner_dir = CORNER_OFFSETS[_current_corner]
	var bolt_count = bolt_container.get_child_count() if bolt_container else 1
	var total_height = bolt_count * 16.0 + max(0, bolt_count - 1) * bolt_stack_spacing
	var offset = Vector2.ZERO
	#Horizontal offset.
	offset.x = corner_dir.x * offset_distance
	if corner_dir.x < 0:
		offset.x -= 16.0
	#Vertical offset.
	offset.y = corner_dir.y * offset_distance
	if corner_dir.y < 0:
		offset.y -= total_height
	global_position = screen_pos + offset

#endregion PROCESS AND POSITIONING

##Sets the maximum number of bolts and rebuilds the display.
func set_max_bolts(max_bolts : int) -> void:
	_build_bolts(max_bolts)
	if _energy_component:
		_update_bolts(_energy_component.cur_energy)

#endregion FUNCTIONS
