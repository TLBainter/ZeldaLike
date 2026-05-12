##Intercepts inspector properties for [b]CharacterAnimationDirectionEntry[/b] and [b]CharacterAnimationResource[/b].[br]
##- Replaces the [code]direction[/code] enum dropdown with the compass-rose grid widget.[br]
##- Replaces the [code]sprite_sheet_name[/code] string field with a dropdown of names from the owning character's sprite sheets.
@tool
class_name DirectionInspectorPlugin
extends EditorInspectorPlugin

## Holds button-press logic for Make 4/8-Direction buttons.
## Using a RefCounted object instead of a lambda avoids capturing the plugin's `self`,
## which causes "Lambda capture at index 0 was freed" errors on inspector refresh.
class _DirectionBuilder:
	extends RefCounted
	var _anim_ref: WeakRef
	var _dir_vals: Array

	func _init(ref: WeakRef, vals: Array) -> void:
		_anim_ref = ref
		_dir_vals = vals

	func execute() -> void:
		var res := _anim_ref.get_ref() as CharacterAnimationResource
		if not res:
			return
		var entries: Array[CharacterAnimationDirectionEntry] = []
		for i: int in _dir_vals.size():
			var e := CharacterAnimationDirectionEntry.new()
			e.row = i
			e.direction = _dir_vals[i] as int
			entries.append(e)
		res.directions = entries
		res.notify_property_list_changed()

const DirectionCompassProperty = preload("res://addons/character_visual_editor/direction_property.gd")
const SpriteSheetNameProperty  = preload("res://addons/character_visual_editor/sprite_sheet_name_property.gd")

## Tracks the most recently inspected Character node so sub-resource property editors
## can read its visual_sprite_sheets without needing a back-reference on the resource itself.
var _current_character: Character = null

func _can_handle(object: Object) -> bool:
	if object is Character:
		_current_character = object
		return false  # Capture the reference but don't intercept Character's own properties.
	return object is CharacterAnimationDirectionEntry or object is CharacterAnimationResource

func _parse_property(object: Object, type: Variant.Type, name: String,
		hint_type: PropertyHint, hint_string: String,
		usage_flags: int, wide: bool) -> bool:
	if object is CharacterAnimationResource and name == "sprite_sheet_name":
		add_property_editor(name, SpriteSheetNameProperty.new(_current_character))
		return true
	if object is CharacterAnimationResource and name == "directions":
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		var anim_ref := weakref(object)
		var btn4 := Button.new()
		btn4.text = "Make 4-Direction"
		btn4.tooltip_text = "Replaces directions with Down / Left / Up / Right entries (rows 0–3)."
		btn4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn4.pressed.connect(_DirectionBuilder.new(anim_ref, [0, 2, 4, 6]).execute)
		hbox.add_child(btn4)
		var btn8 := Button.new()
		btn8.text = "Make 8-Direction"
		btn8.tooltip_text = "Replaces directions with all 8 compass entries (rows 0–7)."
		btn8.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn8.pressed.connect(_DirectionBuilder.new(anim_ref, [0, 1, 2, 3, 4, 5, 6, 7]).execute)
		hbox.add_child(btn8)
		add_custom_control(hbox)
		return false  # Keep the default directions array editor below the buttons.
	if object is CharacterAnimationDirectionEntry and name == "direction":
		add_property_editor(name, DirectionCompassProperty.new())
		return true
	return false

