##[b][color=red]SalvePanel[/color][/b] displays a single concoction/salve on the DPad HUD.[br]
##Shows the mini texture, quantity label, and plays a use animation when activated.[br]
##Desaturates and dims when the player has 0 of the salve.
class_name SalvePanel
extends Panel

#region ENUMS

enum SalveType {
	RESTORATIVE,  ## DPad 1 (Up)
	ARCANE,       ## DPad 2 (Right)
	ENERGIZING,   ## DPad 3 (Down)
	BLOOD,        ## DPad 4 (Left)
}

#endregion ENUMS

#region VARIABLES

@export_category("Salve Configuration")
@export_group("Identity")
##Which concoction this panel represents.
@export var salve_type : SalveType = SalveType.RESTORATIVE
##The MenuItemResource for this salve. Used to get the mini texture and item_id.
@export var item_resource : MenuItemResource

@export_group("Components")
##The TextureRect displaying the salve's mini icon.
@export var salve_rect : TextureRect
##The AnimationPlayer with the 'salveUse' animation.
@export var salve_anim_player : Node ## AnimationPlayer
##The Label showing the current quantity.
@export var quantity_label : Label

@export_group("Visual Config")
##Horizontal alignment of the quantity label.
@export_enum("Left:0", "Right:1") var label_alignment : int = 1:
	set(value):
		label_alignment = value
		_apply_label_alignment()

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

##Reference to the player's inventory. Set at runtime.
var _inventory : InventoryComponent = null
##The DPad index this salve responds to (1-4).
var _dpad_index : int = 1
##reference to the player's concoction item use component.
var _concoction_use : ConcoctionItemUse = null

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	_dpad_index = _get_dpad_index()
	_apply_label_alignment()
	_update_display()

##Initializes the panel with inventory and input references.
func initialize(inventory : InventoryComponent, input_comp : PlayerInputComponent, concoction_use : ConcoctionItemUse = null) -> void:
	_inventory = inventory
	_concoction_use = concoction_use
	if input_comp and not input_comp.dPadPressed.is_connected(_on_dpad_pressed):
		input_comp.dPadPressed.connect(_on_dpad_pressed)
	if _inventory and not _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.connect(_on_inventory_changed)
	_update_display()

#region DISPLAY

##Updates the texture, quantity, and visual state based on inventory.
func _update_display() -> void:
	_update_texture()
	_update_quantity()
	_update_availability()

##Sets the salve_rect texture from the item resource's mini icon.
func _update_texture() -> void:
	if not salve_rect or not item_resource:
		return
	if item_resource.mini_icon:
		salve_rect.texture = item_resource.mini_icon

##Updates the quantity label from inventory.
func _update_quantity() -> void:
	if not quantity_label:
		return
	if not _inventory or not item_resource or item_resource.item_id.is_empty():
		quantity_label.text = "0"
		return
	var qty = _inventory.get_quantity(item_resource.item_id)
	quantity_label.text = str(qty)

##Updates the visual state: desaturated + transparent if 0, normal if owned.
func _update_availability() -> void:
	var has_salve = _has_salve()
	if salve_rect:
		if has_salve:
			salve_rect.modulate = Color(1, 1, 1, 1)
		else:
			#Desaturated (gray) and 50% transparent.
			salve_rect.modulate = Color(0.5, 0.5, 0.5, 0.5)
	if quantity_label:
		if has_salve:
			quantity_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			quantity_label.add_theme_color_override("font_color", Color.RED)

##Returns whether the player has at least 1 of this salve.
func _has_salve() -> bool:
	if not _inventory or not item_resource or item_resource.item_id.is_empty():
		return false
	return _inventory.has_item(item_resource.item_id)

#endregion DISPLAY

#region LABEL ALIGNMENT

func _apply_label_alignment() -> void:
	if not quantity_label:
		return
	if label_alignment == 0:
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

#endregion LABEL ALIGNMENT

#region INPUT

##Called when a DPad button is pressed. Checks if it matches this salve's index.
func _on_dpad_pressed(index : int) -> void:
	if index != _dpad_index:
		return
	if not _has_salve():
		if debug_me:
			print(debug_name, ": No salve to use!")
		return
	_use_salve()

##Uses the salve: plays animation, decreases quantity.
func _use_salve() -> void:
	#Play use animation with flash color.
	if salve_anim_player and salve_anim_player.has_animation("salveUse"):
		var anim = salve_anim_player.get_animation("salveUse")
		var flash_color = item_resource.flash_color if item_resource.flash_color else Color.WHITE_SMOKE
		for track_idx in range(anim.get_track_count()):
			var path = anim.track_get_path(track_idx)
			if ":self_modulate" in str(path) and anim.track_get_key_count(track_idx) >= 2:
				anim.track_set_key_value(track_idx, 1, flash_color)
				break
		salve_anim_player.stop()
		salve_anim_player.play("salveUse")
	#Decrease quantity by 1.
	if _concoction_use and item_resource:
		_concoction_use.use_concoction(item_resource)
	elif _inventory and item_resource and not item_resource.item_id.is_empty():
		_inventory.remove_item(item_resource.item_id, 1)
	if debug_me:
		print(debug_name, ": Used salve! Type=", SalveType.keys()[salve_type])

#endregion INPUT

#region INVENTORY CALLBACK

##Called when any inventory item changes. Refreshes display if it's our item.
func _on_inventory_changed(item_id : String, _quantity : int) -> void:
	if item_resource and item_id == item_resource.item_id:
		_update_display()

#endregion INVENTORY CALLBACK

#region HELPERS

##Maps SalveType to DPad index (1-4).
func _get_dpad_index() -> int:
	match salve_type:
		SalveType.RESTORATIVE: return 1
		SalveType.ARCANE: return 2
		SalveType.ENERGIZING: return 3
		SalveType.BLOOD: return 4
	return 1

#endregion HELPERS

#endregion FUNCTIONS
