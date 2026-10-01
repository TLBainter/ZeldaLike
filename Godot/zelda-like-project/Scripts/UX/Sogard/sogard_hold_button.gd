##Hold-to-confirm Sogard button (danger Hold to Erase). Accept press ticks a tiled red fill; release before full cancels; a full fill emits hold_completed then activated.
@tool
class_name SogardHoldButton
extends SogardButton

#region VARIABLES
signal hold_started()
signal hold_progress(value : float)
signal hold_completed()
signal hold_cancelled()

const JIT_ANIM : StringName = &"jit"
const HOLD_EPSILON : float = 0.0001

@export_category("Hold Components")
@export var hold_fill : TextureRect
@export var hold_edge : ColorRect
@export var tick_timer : Timer
@export var jit_anim : AnimationPlayer

@export_category("Hold")
##Milliseconds between fill ticks. 40 ms x 25 ticks completes in 1000 ms.
@export var tick_ms : int = 40
##Fill added per tick, 0..1.
@export var tick_step : float = 0.04
##Fill inset from the plate edge on every side. Full fill width is size.x - 2 * fill_inset.
@export var fill_inset : int = 3:
	set(v):
		fill_inset = v
		_layout_fill()
##Played on every fill tick before completion.
@export var sound_tick : AudioStream

static var _tile_cache : Dictionary = {}

var hold : float = 0.0
var _holding : bool = false
var _ticks : int = 0
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	if hold_fill:
		hold_fill.texture = _tileable(hold_fill.texture)
	if plate and hold_fill:
		move_child(hold_fill, plate.get_index() + 1)
	if hold_fill and hold_edge:
		move_child(hold_edge, hold_fill.get_index() + 1)
	if tick_timer:
		tick_timer.one_shot = false
		tick_timer.timeout.connect(_on_tick)
	resized.connect(_layout_fill)
	_layout_fill()

##Accept press routed from SogardNavInput: starts the fill and the label jitter. Returns true unless disabled.
func handle_accept() -> bool:
	if Engine.is_editor_hint():
		return false
	if disabled:
		return false
	if _holding:
		return true
	_holding = true
	_ticks = 0
	hold = 0.0
	_layout_fill()
	if tick_timer:
		tick_timer.wait_time = maxf(float(tick_ms), 1.0) / 1000.0
		tick_timer.start()
	if jit_anim:
		jit_anim.play(JIT_ANIM)
	if debug_me:
		print_rich(debug_name, ": [color=orange]hold started[/color]")
	hold_started.emit()
	return true

##Accept release routed from SogardNavInput: cancels an unfinished hold; clears a completed fill.
func handle_accept_released() -> void:
	if _holding and hold < 1.0:
		_cancel_hold()
	elif not _holding and hold > 0.0:
		_reset_hold()

func _on_tick() -> void:
	if not _holding:
		return
	if disabled:
		_cancel_hold()
		return
	_ticks += 1
	hold = minf(float(_ticks) * tick_step, 1.0)
	if hold >= 1.0 - HOLD_EPSILON:
		hold = 1.0
	_layout_fill()
	if debug_me_verbose:
		print_rich(debug_name, ": hold ", hold)
	hold_progress.emit(hold)
	if hold >= 1.0:
		_complete_hold()
	else:
		_play(sound_tick)

func _complete_hold() -> void:
	_holding = false
	if tick_timer:
		tick_timer.stop()
	_stop_jit()
	if sound_accept:
		_play(sound_accept)
	else:
		menuSfx.play_confirm()
	if debug_me:
		print_rich(debug_name, ": [color=green]hold completed[/color] ", text)
	hold_completed.emit()
	activated.emit()

func _cancel_hold() -> void:
	_reset_hold()
	if debug_me:
		print_rich(debug_name, ": [color=yellow]hold cancelled[/color]")
	hold_cancelled.emit()

func _reset_hold() -> void:
	_holding = false
	_ticks = 0
	hold = 0.0
	if tick_timer:
		tick_timer.stop()
	_stop_jit()
	_layout_fill()

func _stop_jit() -> void:
	if jit_anim and jit_anim.is_playing():
		jit_anim.stop()
	label_nudge = Vector2.ZERO

func _on_focus_exited() -> void:
	if _holding:
		_cancel_hold()
	super._on_focus_exited()

##AtlasTexture ignores STRETCH_TILE, so the hold tile region is copied once into a shared ImageTexture.
static func _tileable(t : Texture2D) -> Texture2D:
	var at : AtlasTexture = t as AtlasTexture
	if not at:
		return t
	if _tile_cache.has(at):
		return _tile_cache[at]
	var img : Image = at.get_image()
	if not img:
		return t
	var tex : ImageTexture = ImageTexture.create_from_image(img)
	_tile_cache[at] = tex
	return tex

func _layout_fill() -> void:
	if not is_node_ready() or not hold_fill:
		return
	var inset : float = float(fill_inset)
	var h : float = maxf(size.y - 2.0 * inset, 0.0)
	var w : float = roundf(hold * maxf(size.x - 2.0 * inset, 0.0))
	hold_fill.position = Vector2(inset, inset)
	hold_fill.size = Vector2(w, h)
	hold_fill.visible = w > 0.0
	if hold_edge:
		hold_edge.position = Vector2(inset + w, inset)
		hold_edge.size = Vector2(1.0, h)
		hold_edge.visible = w > 0.0
#endregion FUNCTIONS
