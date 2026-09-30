##CPU-stepped falling blood drops for SogardBackground: a handful of TextureRects each looping a discrete vertical fall, no Tween.
class_name SogardBgDrops
extends Control

#region VARIABLES
const TEX_DROP : Texture2D = preload("res://Sprites/UX/Sogard/sogard_ui_drop.tres")
const DURATIONS : Array = [3.5, 4.5, 4.0, 5.0]
const DELAYS : Array = [0.0, -3.0, -5.5, -1.5]
const STEPS : int = 60
const Y_START : float = 12.0
const DROP_COUNT : int = 4
const DROP_SIZE : Vector2 = Vector2(4, 6)

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _drops : Array = []
var _elapsed : float = 0.0
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	resized.connect(_layout)
	_layout()

func _process(delta : float) -> void:
	_elapsed += delta
	for i in range(_drops.size()):
		var d : TextureRect = _drops[i]
		var dur : float = DURATIONS[i % DURATIONS.size()]
		var frac : float = fposmod(_elapsed + DELAYS[i % DELAYS.size()], dur) / dur
		var k : int = int(floor(frac * float(STEPS)))
		var prog : float = float(k) / float(STEPS)
		d.position.y = lerpf(Y_START, size.y, prog)
		d.modulate.a = 1.0 - prog

##Builds the drop TextureRects. Idempotent so it can be re-run after a scene reload.
func _build() -> void:
	for c in get_children():
		c.queue_free()
	_drops.clear()
	for i in range(DROP_COUNT):
		var d : TextureRect = TextureRect.new()
		d.texture = TEX_DROP
		d.size = DROP_SIZE
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		_drops.append(d)
	if debug_me_verbose:
		print_rich(debug_name, ": built ", _drops.size(), " drops")

func _layout() -> void:
	if _drops.is_empty():
		return
	var w : float = size.x
	for i in range(_drops.size()):
		_drops[i].position.x = w / 5.0 * float(i + 1)
#endregion FUNCTIONS
