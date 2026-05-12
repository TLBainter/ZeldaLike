##OptionButton-based [EditorProperty] for [b]CharacterAnimationResource.sprite_sheet_name[/b].[br]
##Populates its dropdown from the sheet names defined in the owning Character's [b]visual_sprite_sheets[/b] array.
@tool
class_name SpriteSheetNameProperty
extends EditorProperty

var _option: OptionButton
var _character: Character  # May be null if editing the resource outside a character context.

func _init(character: Character) -> void:
	_character = character
	_option = OptionButton.new()
	_option.fit_to_longest_item = false
	_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option.item_selected.connect(_on_item_selected)
	add_child(_option)
	add_focusable(_option)

func _update_property() -> void:
	var sheets := _get_sheet_names()
	var current: String = get_edited_object().get("sprite_sheet_name")

	_option.clear()
	if sheets.is_empty():
		_option.add_item("(add sprite sheets above first)")
		_option.disabled = true
		return

	_option.disabled = false
	if current not in sheets:
		_option.add_item("(select a sheet...)")
		_option.set_item_metadata(0, "")
	for s: String in sheets:
		var idx := _option.item_count
		_option.add_item(s)
		_option.set_item_metadata(idx, s)
	for i: int in _option.item_count:
		if _option.get_item_metadata(i) == current:
			_option.select(i)
			return
	_option.select(0)

func _get_sheet_names() -> Array[String]:
	var char_node: Character = _character
	if not char_node:
		var inspected: Object = EditorInterface.get_inspector().get_edited_object()
		if inspected is Character:
			char_node = inspected as Character
	if not char_node:
		return []
	var names: Array[String] = []
	for sheet: CharacterSpriteResource in char_node.visual_sprite_sheets:
		if sheet and sheet.sheet_name != "":
			names.append(sheet.sheet_name)
	return names

func _on_item_selected(index: int) -> void:
	var meta = _option.get_item_metadata(index)
	if meta is String and meta != "":
		emit_changed("sprite_sheet_name", meta)
