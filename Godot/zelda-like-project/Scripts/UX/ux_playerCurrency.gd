##[b][color=red]CurrencyDisplay[/color][/b] controls the visual display of the player's currency (notes).[br]
##Manages wallet size sprites, leading-zero label formatting, tick-up/down animation,[br]
##sound effects, and visibility rules.[br]
class_name CurrencyDisplay
extends Panel

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
##The maximum duration for the full tick animation (in seconds).[br]
##If the change would take longer, tick speed increases.
@export var max_tick_duration : float = 3.0
##The minimum delay between ticks (in seconds). Prevents going too fast.
@export var min_tick_interval : float = 0.02
##The default delay between ticks (in seconds).
@export var default_tick_interval : float = 0.05

@export_group("Visibility")
##How long the display stays visible after changes finish (in seconds).
@export var visibility_duration : float = 3.0
##How fast the display fades in.
@export var fade_in_speed : float = 12.0
##How fast the display fades out.
@export var fade_out_speed : float = 2.0

@export_group("Colors")
##The normal color of the currency label.
@export var normal_color : Color = Color.WHITE
##The color when currency is at maximum.
@export var max_color : Color = Color.YELLOW

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "CurrencyDisplay"

#=======INTERNAL VARIABLES=======#

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
##Current target alpha for fade.
var _target_alpha : float = 0.0
##Whether the display is forced visible (zoom, etc).
var _force_visible : bool = false
##Timer for visibility countdown after ticking finishes.
var _visibility_timer : Timer
##The number of digits for leading zeroes (based on max currency).
var _digit_count : int = 2

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

##Initializes the currency display with references.[br]
##Called by PlayerUX after all components are ready.
func initialize(currency_comp : CurrencyComponent) -> void:
	_currency_component = currency_comp
	if _currency_component:
		if not _currency_component.notesChanged.is_connected(_on_notes_changed):
			_currency_component.notesChanged.connect(_on_notes_changed)
		_display_value = _currency_component.cur_notes
		_target_value = _display_value
		_update_wallet_size()
		_update_label()
	if debug_me:
		print(debug_name, " initialized.")

#region WALLET SIZE

##Updates the wallet sprite and digit count based on current max notes.
func _update_wallet_size() -> void:
	if not _currency_component:
		return
	var max_notes = _currency_component.max_notes
	if max_notes <= 99:
		_digit_count = 2
		if wallet_sprite and sprite_pocket:
			wallet_sprite.texture = sprite_pocket
	elif max_notes <= 999:
		_digit_count = 3
		if wallet_sprite and sprite_wallet:
			wallet_sprite.texture = sprite_wallet
	else:
		_digit_count = 4
		if wallet_sprite and sprite_big_wallet:
			wallet_sprite.texture = sprite_big_wallet
	if debug_me:
		print(debug_name, ": Wallet size updated. Max: ", max_notes, " Digits: ", _digit_count)

#endregion WALLET SIZE

#region LABEL

##Updates the currency label with leading zeroes and max color.
func _update_label() -> void:
	if not currency_label:
		return
	var text = str(_display_value).pad_zeros(_digit_count)
	currency_label.text = text
	if _currency_component and _display_value >= _currency_component.max_notes:
		currency_label.add_theme_color_override("font_color", max_color)
	else:
		currency_label.add_theme_color_override("font_color", normal_color)

#endregion LABEL

#region CURRENCY CHANGE HANDLER

##Called when the currency component emits notesChanged.
func _on_notes_changed(cur_notes : int, max_notes : int, change_amount : int) -> void:
	_target_value = cur_notes
	var change_size : int = absi(_target_value - _display_value)
	if change_size > 0:
		var calculated_interval = max_tick_duration / float(change_size)
		_tick_interval = clampf(calculated_interval, min_tick_interval, default_tick_interval)
	_is_ticking = true
	_tick_time = 0.0
	_show()
	_play_change_anim()
	set_process(true)
	if debug_me:
		print(debug_name, ": Notes changed by ", change_amount, ". Ticking from ", _display_value, " to ", _target_value, " interval=", _tick_interval)

#endregion CURRENCY CHANGE HANDLER

#region TICK ANIMATION

func _process(delta : float) -> void:
	if _is_ticking:
		_tick_time += delta
		if _tick_time >= _tick_interval:
			_tick_time = 0.0
			_perform_tick()
	if modulate.a != _target_alpha:
		var speed = fade_in_speed if _target_alpha > modulate.a else fade_out_speed
		modulate.a = move_toward(modulate.a, _target_alpha, speed * delta)
		if modulate.a <= 0.0:
			modulate.a = 0.0
			if not _force_visible and not _is_ticking:
				set_process(false)

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
			var player_node = audioManager.play(clip, "World Items")
			if player_node and player_node is AudioStreamPlayer:
				player_node.pitch_scale = randf_range(0.8, 1.25)
	if _display_value == _target_value:
		_is_ticking = false
		_play_change_anim()
		_visibility_timer.stop()
		_visibility_timer.start(visibility_duration)
		if debug_me:
			print(debug_name, ": Tick complete at ", _display_value)

##Plays the 'Currency Changed' stretch animation.
func _play_change_anim() -> void:
	if change_anim and change_anim.has_animation("CurrencyChanged"):
		change_anim.stop()
		change_anim.play("CurrencyChanged")

#endregion TICK ANIMATION

#region VISIBILITY

##Shows the currency display with fade in.
func _show() -> void:
	_target_alpha = 1.0
	_visibility_timer.stop()
	set_process(true)

##Called when the visibility timer expires. Begins fading out.
func _on_visibility_timeout() -> void:
	if _force_visible:
		return
	if not _is_ticking:
		_target_alpha = 0.0

##Forces the display to stay visible (e.g., during camera zoom).
func force_show(should_force : bool) -> void:
	_force_visible = should_force
	if should_force:
		_target_alpha = 1.0
		_visibility_timer.stop()
		set_process(true)
	else:
		if not _is_ticking:
			_visibility_timer.start(visibility_duration)

#endregion VISIBILITY

##Called when the wallet is upgraded. Updates sprite and digit count.
func on_wallet_upgraded() -> void:
	_update_wallet_size()
	_update_label()

#endregion FUNCTIONS
