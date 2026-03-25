##[b][color=red]MenuController[/color][/b] handles navigation input for a menu full of [b]MenuHoverable[/b] panels.[br]
##Routes D-pad/stick input to move between hoverables.
class_name MenuController
extends Node

#region VARIABLES

@export_category("Menu Controller")
##The hoverable that starts with the cursor on menu open.
@export var default_hoverable : MenuHoverable
##Input repeat delay: how long to hold a direction before it starts repeating (seconds).
@export var input_repeat_delay : float = 0.4
##Input repeat rate: how fast navigation repeats while held (seconds).
@export var input_repeat_rate : float = 0.12

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "MenuController"

#=======INTERNAL VARIABLES=======#

##The currently hovered panel.
var _current : MenuHoverable = null
##The direction currently held (or "" if none).
var _held_direction : String = ""
##Time the current direction has been held.
var _held_time : float = 0.0
##Whether the initial repeat delay has passed.
var _repeat_started : bool = false
##A reference to the player's inventory component.
var _inventory : InventoryComponent = null

#endregion VARIABLES

#region FUNCTIONS

#region INITIALIZE
func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_process(false)

##Call this when the menu opens to set the starting hover state.
func activate() -> void:
	if default_hoverable:
		_navigate_to(default_hoverable)
	_held_direction = ""
	_held_time = 0.0
	_repeat_started = false
	set_process(true)
	if debug_me:
		print(debug_name, ": Activated. Starting at ", default_hoverable.debug_name if default_hoverable else "null")
		
##Sets the inventory reference on all hoverables in the tree.
func set_inventory(inv : InventoryComponent) -> void:
	_inventory = inv
	var hoverables = _get_all_hoverables(get_parent())
	for h in hoverables:
		h.inventory = inv
	if debug_me:
		print(debug_name, ": Inventory set on ", hoverables.size(), " hoverables.")

##Finds all MenuHoverable nodes under the given root.
func _get_all_hoverables(node : Node) -> Array[MenuHoverable]:
	var result : Array[MenuHoverable] = []
	if node is MenuHoverable:
		result.append(node)
	for child in node.get_children():
		result.append_array(_get_all_hoverables(child))
	return result
#endregion INITIALIZE

##Call this when the menu closes to clean up.
func deactivate() -> void:
	if _current:
		_current.unhover()
		_current = null
	_held_direction = ""
	set_process(false)
	if debug_me:
		print(debug_name, ": Deactivated.")

func _process(delta : float) -> void:
	var direction = _get_input_direction()
	if direction != "":
		if direction != _held_direction:
			#New direction pressed — navigate immediately.
			_held_direction = direction
			_held_time = 0.0
			_repeat_started = false
			_try_navigate(direction)
		else:
			#Same direction held — handle repeat.
			_held_time += delta
			if not _repeat_started:
				if _held_time >= input_repeat_delay:
					_repeat_started = true
					_held_time = 0.0
					_try_navigate(direction)
			else:
				if _held_time >= input_repeat_rate:
					_held_time = 0.0
					_try_navigate(direction)
	else:
		#No direction held — reset.
		_held_direction = ""
		_held_time = 0.0
		_repeat_started = false

#region NAVIGATION

##Attempts to navigate from the current hoverable in the given direction.
func _try_navigate(direction : String) -> void:
	if not _current:
		return
	var target = _current.get_nav(direction)
	if target:
		_navigate_to(target)

##Moves the cursor from the current hoverable to the target.
func _navigate_to(target : MenuHoverable) -> void:
	if _current:
		_current.unhover()
	_current = target
	_current.hover()
	if debug_me:
		print(debug_name, ": Navigated to ", _current.debug_name)

#endregion NAVIGATION

#region INPUT

##Returns the current directional input as a string, or "" if none.
func _get_input_direction() -> String:
	#Check D-pad first (menu-only).
	if Input.is_action_pressed("dPadUp"):
		return "up"
	if Input.is_action_pressed("dPadDown"):
		return "down"
	if Input.is_action_pressed("dPadLeft"):
		return "left"
	if Input.is_action_pressed("dPadRight"):
		return "right"
	#Also check left stick for menu navigation.
	var move = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	if move.length() < 0.4:
		return ""
	if abs(move.x) > abs(move.y):
		return "right" if move.x > 0 else "left"
	else:
		return "down" if move.y > 0 else "up"

#endregion INPUT

#region PUBLIC

##Returns the currently hovered MenuHoverable.
func get_current() -> MenuHoverable:
	return _current

#endregion PUBLIC

#endregion FUNCTIONS
