class_name FileSelectPanel
extends Panel

signal panel_selected(slot_index: int)

const _SPELL_ORDER : Array[String] = [
	ItemID.SPELL_GRAPPLE,
	ItemID.SPELL_HAMMER,
	ItemID.SPELL_HASTE,
	ItemID.SPELL_IGNITE,
	ItemID.SPELL_SUMMON,
]

const _MOBILITY_ORDER : Array[String] = [
	ItemID.BAT_FORM,
	ItemID.WAVEWALK_BOOTS,
	ItemID.ALBEDO_HOOD,
]

const _EMPTY_SKULLS  : int = 3
const _EMPTY_ENERGY  : int = 2
const _EMPTY_MAGIC   : int = 1

@onready var _file_name  : RichTextLabel = $"Header Panel/File Name"
@onready var _play_time  : RichTextLabel = $"Time n Place/Play Time"
@onready var _location   : RichTextLabel = $"Time n Place/Location"
@onready var _skulls     : Node          = $"Resources/Skulls"
@onready var _bones      : TextureRect   = $"Resources/Bones"
@onready var _arcane     : TextureRect   = $"Resources/Medallion"
@onready var _glands     : TextureRect   = $"Resources/Glands"
@onready var _energy_row : HBoxContainer = $"Collection/HBoxContainer"
@onready var _magic_row  : HBoxContainer = $"Collection/HBoxContainer2"
@onready var _spell_row  : HBoxContainer = $"Collection/Progression"
@onready var _mob_row    : HBoxContainer = $HBoxContainer

var _slot_index            : int              = -1
var _is_selectable         : bool             = false
var _mob_initial_textures  : Array[Texture2D] = []

func _ready() -> void:
	_file_name.scroll_active = false
	_play_time.scroll_active = false
	_location.scroll_active  = false
	for i in _MOBILITY_ORDER.size():
		var node := _mob_row.get_child(i) as TextureRect
		_mob_initial_textures.append(node.texture if node else null)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(func(): pivot_offset = size / 2.0)
	pivot_offset = custom_minimum_size / 2.0

func setup(slot: int, save_data: Dictionary, selectable: bool) -> void:
	_slot_index    = slot
	_is_selectable = selectable
	if not selectable:
		self_modulate = Color(0.5, 0.5, 0.5, 1.0)
		mouse_filter  = MOUSE_FILTER_IGNORE
	else:
		self_modulate = Color.WHITE
		mouse_filter  = MOUSE_FILTER_STOP
	if save_data.is_empty():
		_populate_empty()
	else:
		_populate(save_data)

func _gui_input(event: InputEvent) -> void:
	if not _is_selectable:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		panel_selected.emit(_slot_index)

func _on_mouse_entered() -> void:
	if not _is_selectable:
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)

func _populate_empty() -> void:
	_file_name.text = "No Data"
	_play_time.text = "--:--:--"
	_location.text  = "?"
	_show_skulls(_EMPTY_SKULLS)
	_show_children(_energy_row, _EMPTY_ENERGY)
	_show_children(_magic_row, _EMPTY_MAGIC)
	_set_upgrade_texture(_bones,  ItemID.BONE_SHARD,   0)
	_set_upgrade_texture(_arcane, ItemID.ARCANE_SHARD, 0)
	_set_upgrade_texture(_glands, ItemID.GLAND,        0)
	for i in _spell_row.get_child_count():
		_spell_row.get_child(i).self_modulate.a = 0.0
	for i in _MOBILITY_ORDER.size():
		var node := _mob_row.get_child(i) as TextureRect
		if node:
			node.texture = (ItemID.MENU_ITEM_RESOURCES[_MOBILITY_ORDER[i]] as MenuItemResource).outline

func _populate(save_data: Dictionary) -> void:
	var meta : Dictionary = save_data.get("metadata", {})
	var inv  : Dictionary = meta.get("inventory", {})

	_file_name.text = str(meta.get("character_name", "?"))
	_play_time.text = _format_time(float(meta.get("play_time", 0.0)))
	_location.text  = str(meta.get("location_name", "?"))

	var skull_count : int = floori(float(int(meta.get("max_health", 12))) / 4.0)
	_show_skulls(clampi(skull_count, 0, 20))

	var energy_count : int = floori(float(int(meta.get("max_energy", 8))) / 4.0)
	_show_children(_energy_row, clampi(energy_count, 0, _energy_row.get_child_count()))

	var magic_count : int = floori(float(int(meta.get("total_shards", 6))) / 6.0)
	_show_children(_magic_row, clampi(magic_count, 0, _magic_row.get_child_count()))

	_set_upgrade_texture(_bones,  ItemID.BONE_SHARD,   int(inv.get(ItemID.BONE_SHARD,   0)))
	_set_upgrade_texture(_arcane, ItemID.ARCANE_SHARD, int(inv.get(ItemID.ARCANE_SHARD, 0)))
	_set_upgrade_texture(_glands, ItemID.GLAND,        int(inv.get(ItemID.GLAND,        0)))

	for i in _spell_row.get_child_count():
		var child := _spell_row.get_child(i) as TextureRect
		if child and i < _SPELL_ORDER.size():
			child.self_modulate.a = 1.0 if _SPELL_ORDER[i] in inv else 0.0

	for i in _MOBILITY_ORDER.size():
		var node := _mob_row.get_child(i) as TextureRect
		if not node:
			continue
		var base_id : String = _MOBILITY_ORDER[i]
		var upg_id  : String = ItemID.MOBILITY_UPGRADES.get(base_id, "")
		var owned   : bool   = base_id in inv or (not upg_id.is_empty() and upg_id in inv)
		var res     : MenuItemResource = ItemID.MENU_ITEM_RESOURCES[base_id]
		node.texture = _mob_initial_textures[i] if owned else res.outline

func _show_skulls(count: int) -> void:
	var children := _skulls.get_children()
	for i in children.size():
		children[i].visible = i < count

func _show_children(container: Node, count: int) -> void:
	var children := container.get_children()
	for i in children.size():
		children[i].self_modulate.a = 1.0 if i < count else 0.0

func _set_upgrade_texture(node: TextureRect, item_id: String, qty: int) -> void:
	var res := ItemID.MENU_ITEM_RESOURCES.get(item_id) as MenuItemUpgradeResource
	if res == null or qty == 0:
		var base := ItemID.MENU_ITEM_RESOURCES.get(item_id) as MenuItemResource
		node.texture = base.outline if base else null
		return
	var current  : int = res.get_current_parts(qty)
	var part_num : int = current if current > 0 else res.num_parts
	var part := res.get_part_data(part_num)
	node.texture = part.part_static_sprite if part else res.outline

func _format_time(seconds: float) -> String:
	var total : int = int(seconds)
	var h : int = floori(float(total) / 3600.0)
	var m : int = floori(float(total % 3600) / 60.0)
	var s : int = total % 60
	return "%d:%02d:%02d" % [h, m, s]
