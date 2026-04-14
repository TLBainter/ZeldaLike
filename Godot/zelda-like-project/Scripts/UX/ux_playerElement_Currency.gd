##[b][color=red]CurrencyDisplay[/color][/b] extends [b]UXElement[/b] for the player's currency (notes) display.[br]
##Manages wallet size sprites, leading-zero label formatting, tick-up/down animation,[br]
##sound effects, and max-value color change.[br]
##[br]
##[b]Wallet Sizes[/b]: Pocket (99), Wallet (999), Big Wallet (9999).
class_name CurrencyDisplay
extends UXElement

#region VARIABLES

@export_category("Currency Display Components")
##The sprite that changes based on wallet size.
@export var wallet_sprite : TextureRect
##The label displaying the currency value with leading zeroes.
@export var currency_label : Label
##The animation player for the 'currency changed' stretch animation.
@export var change_anim : AnimationPlayer
##A reference to the main UI control node.
@export var root : PlayerUX

@export_category("Wallet Sprites")
##The atlas texture for the Pocket wallet (max 99).
@export var sprite_pocket : AtlasTexture
##The atlas texture for the Wallet (max 999).
@export var sprite_wallet : AtlasTexture
##The atlas texture for the Big Wallet (max 9999).
@export var sprite_big_wallet : AtlasTexture

@export_category("Currency Settings")
@export_group("Sounds")
##Sounds that play on each tick of currency change.
@export var change_sounds : SoundLibrary

@export_group("Tick Speed")
##The maximum duration for the full tick animation (in seconds).
@export var max_tick_duration : float = 3.0
##The minimum delay between ticks (in seconds). Prevents going too fast.
@export var min_tick_interval : float = 0.02
##The default delay between ticks (in seconds).
@export var default_tick_interval : float = 0.05

@export_group("Colors")
##The normal color of the currency label.
@export var normal_color : Color = Color.WHITE
##The color when currency is at maximum.
@export var max_color : Color = Color.YELLOW

##The currency component reference.
var _currency_component : CurrencyComponent
##The value currently being displayed (ticks toward the actual value).
var _display_value : int = 0
##The target value we're ticking toward.
var _target_value : int = 0
##Whether the display is currently ticking.
var _is_ticking : bool = false
##Time since last tick.
var _tick_time : float = 0.0
##Current interval between ticks (adjusted for large changes).
var _tick_interval : float = 0.05
##The number of digits for leading zeroes (based on max currency).
var digit_count : int = 2

#endregion VARIABLES

#region FUNCTIONS

##Initializes the currency display with the currency component reference.
func initialize(currency_comp : CurrencyComponent) -> void:
	_currency_component = currency_comp
	if _currency_component:
		if not _currency_component.notes_changed.is_connected(_on_notes_changed):
			_currency_component.notes_changed.connect(_on_notes_changed)

		_display_value = _currency_component.cur_notes
		_target_value = _display_value
		_update_wallet_size()
		_update_label()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]initialized[/i][/color].")

func _can_fade_out() -> bool:
	return not _is_ticking

func _should_start_fade_timer() -> bool:
	return not _is_ticking

func _on_element_process(delta : float) -> void:
	if _is_ticking:
		_tick_time += delta
		if _tick_time >= _tick_interval:
			_tick_time = 0.0
			_perform_tick()

#region WALLET SIZE

##Updates the wallet sprite and digit count based on current max notes.
func _update_wallet_size() -> void:
	if not _currency_component:
		return
	var max_notes = _currency_component.max_notes
	if max_notes <= 99:
		digit_count = 2
		if wallet_sprite and sprite_pocket:
			wallet_sprite.texture = sprite_pocket
	elif max_notes <= 999:
		digit_count = 3
		if wallet_sprite and sprite_wallet:
			wallet_sprite.texture = sprite_wallet
	else:
		digit_count = 4
		if wallet_sprite and sprite_big_wallet:
			wallet_sprite.texture = sprite_big_wallet
	if debug_me:
		print_rich(debug_name, ": [color=green][i]wallet size updated[/i][/color]. Max: [i]", max_notes, "[/i] Digits: [i]", digit_count, "[/i]")

#endregion WALLET SIZE

#region LABEL

##Updates the currency label with leading zeroes and max color.
func _update_label() -> void:
	if not currency_label:
		return
	var text = str(_display_value).pad_zeros(digit_count)
	currency_label.text = text
	if _currency_component and _display_value >= _currency_component.max_notes:
		currency_label.add_theme_color_override("font_color", max_color)
	else:
		currency_label.add_theme_color_override("font_color", normal_color)

#endregion LABEL

#region CURRENCY CHANGE HANDLER

func _on_notes_changed(cur_notes : int, max_notes : int, change_amount : int):
	if debug_me:
		print_rich(debug_name, ": [color=green][i]notes changed[/i][/color]. cur=[i]", cur_notes, "/", max_notes, "[/i] change=[i]", change_amount, "[/i]")

	_target_value = cur_notes

	# Snap instantly during save-load restore — no tick animation or sounds.
	if saveManager and saveManager.is_loading():
		_display_value = cur_notes
		_is_ticking = false
		_update_label()
		return

	var change_size : int = absi(_target_value - _display_value)
	if change_size > 0:
		var calculated_interval = max_tick_duration / float(change_size)
		_tick_interval = clampf(calculated_interval, min_tick_interval, default_tick_interval)
	_is_ticking = true
	_tick_time = 0.0
	show_element()
	_play_change_anim()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]ticking[/i][/color] from [i]", _display_value, "[/i] to [i]", _target_value, "[/i] interval=[i]", _tick_interval, "[/i]")

#endregion CURRENCY CHANGE HANDLER

#region TICK ANIMATION

##Advances the displayed value by 1 toward the target.
func _perform_tick() -> void:
	if _display_value < _target_value:
		_display_value += 1
	elif _display_value > _target_value:
		_display_value -= 1
	_update_label()
	if change_sounds and not change_sounds.sl.is_empty():
		var clip = change_sounds.sl.pick_random()
		if audioManager:
			var player_node = audioManager.play(clip, "UI")
			if player_node and player_node is AudioStreamPlayer:
				player_node.pitch_scale = randf_range(0.9, 1.15)
	if _display_value == _target_value:
		_is_ticking = false
		_play_change_anim()
		_visibility_timer.stop()
		_visibility_timer.start(visibility_duration)
		if debug_me:
			print_rich(debug_name, ": [color=green][i]tick complete[/i][/color] at [i]", _display_value, "[/i]")

##Plays the 'Currency Changed' stretch animation.
func _play_change_anim() -> void:
	if change_anim and change_anim.has_animation("CurrencyChanged"):
		change_anim.stop()
		change_anim.play("CurrencyChanged")

#endregion TICK ANIMATION

##Called when the wallet is upgraded. Updates sprite and digit count.
func on_wallet_upgraded() -> void:
	_update_wallet_size()
	_update_label()

#endregion FUNCTIONS
