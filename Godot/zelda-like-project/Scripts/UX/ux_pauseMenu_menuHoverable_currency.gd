##[b][color=red]MenuHoverableCurrency[/color][/b] extends [b]MenuHoverable[/b] for the currency display panel.[br]
##Shows the wallet sprite and "current / max" currency text.[br]
##Info box content is set via exports rather than read from a resource.
@tool
class_name MenuHoverableCurrency
extends MenuHoverable

#region VARIABLES

@export_category("Currency Display")
@export_group("Components")
##The TextureRect displaying the wallet sprite.
@export var wallet_rect : TextureRect
##The Label displaying the currency text (e.g., "42 / 99").
@export var currency_label : Label

@export_group("Info Box Content")
##The title displayed in the info box when hovered.
@export var info_title : String = "Currency"
##The description displayed in the info box when hovered.
@export var info_description : String = "Your current funds."
##The effect text displayed in the info box when hovered.
@export var info_effect : String = ""
##Font for the description text.
@export var description_font : Font
##Font for the effect text.
@export var effect_font : Font


##Reference to the player's currency component; set at runtime.
var _currency_component : CurrencyComponent
##The amount of padded zeroes to add to the text.
var digit_count : int = 2

#endregion VARIABLES

#region FUNCTIONS

func _on_hoverable_ready() -> void:
	_update_currency_display()

##Sets the currency component reference and updates the display.
func set_currency(currency_comp : CurrencyComponent) -> void:
	_currency_component = currency_comp
	_update_currency_display()

#region CURRENCY DISPLAY

##Updates the wallet sprite and currency label from the currency component.
func _update_currency_display() -> void:
	if not _currency_component:
		if currency_label:
			currency_label.text = "0 / 0"
		return
	if _currency_component:
		var max_notes = _currency_component.max_notes
		if max_notes <= 99:
			digit_count = 2
		elif max_notes <= 999:
			digit_count = 3
		else:
			digit_count = 4
		if debug_me:
			print(debug_name, ": Wallet size updated. Max: ", max_notes, " Digits: ", digit_count)
	if currency_label:
		currency_label.text = str(_currency_component.cur_notes).pad_zeros(digit_count) + " / " + str(_currency_component.max_notes).pad_zeros(digit_count)

#endregion CURRENCY DISPLAY

#region INFO BOX

func _populate_info_box() -> void:
	if not info_box:
		return
	var text = ""
	text += "[color=red][font_size=28]" + info_title + "[/font_size][/color]\n"
	var resolved_desc = textResolver.resolve(info_description) if textResolver else info_description
	text += "[color=gray][font_size=16]" + resolved_desc + "[/font_size][/color]"
	if not info_effect.is_empty():
		text += "\n"
		var resolved_effect = textResolver.resolve(info_effect) if textResolver else info_effect
		text += "[color=white][font_size=16]" + resolved_effect + "[/font_size][/color]"
	info_box.bbcode_enabled = true
	info_box.text = text

#endregion INFO BOX

#region HOVER OVERRIDES

func _on_hover() -> void:
	_update_currency_display()
	_populate_info_box()

func _on_unhover() -> void:
	pass

#endregion HOVER OVERRIDES

#endregion FUNCTIONS
