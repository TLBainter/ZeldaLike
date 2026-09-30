##Real particle layer for SogardBackground: upward-drifting embers with true randomness (CPUParticles2D), no shader, no Tween.
class_name SogardBgParticles
extends Control

#region VARIABLES
enum Mode { RISE, EMBER }

const COLORS : Array = [Color("#ff5a2a"), Color("#ff8a30"), Color("#ffd21f"), Color("#c4122a")]
const PARTICLE_TEXTURE_SIZE : int = 2
const RISE_DISTANCE : float = 380.0
const RISE_SPEED_MIN : float = 26.0
const RISE_SPEED_MAX : float = 60.0
const EMBER_DISTANCE : float = 140.0
const EMBER_SPEED_MIN : float = 18.0
const EMBER_SPEED_MAX : float = 40.0

@export_category("Motion")
##RISE drifts particles the full background height; EMBER is a shorter, sparser drift.
@export var mode : Mode = Mode.RISE:
	set(v):
		mode = v
		if is_node_ready():
			_configure_emitters()
##Particle count. Driven by SogardBackground.set_particle_level for the RISE layer; fixed for EMBER. 0 hides all particles.
@export var count : int = 24:
	set(v):
		count = maxi(v, 0)
		if is_node_ready():
			_configure_emitters()

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _emitters : Array = []
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_emitters()
	resized.connect(_configure_emitters)
	_configure_emitters()

##Creates one CPUParticles2D per palette color so every particle's color is an exact palette entry, not a blend.
func _build_emitters() -> void:
	var tex : ImageTexture = _make_particle_texture()
	for i in range(COLORS.size()):
		var p : CPUParticles2D = CPUParticles2D.new()
		p.texture = tex
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.gravity = Vector2.ZERO
		p.direction = Vector2.UP
		p.one_shot = false
		p.color_ramp = _make_flicker_ramp(COLORS[i])
		add_child(p)
		_emitters.append(p)

##Builds a small opaque square texture so particles read as hard pixel embers, never a soft glow.
func _make_particle_texture() -> ImageTexture:
	var img : Image = Image.create_empty(PARTICLE_TEXTURE_SIZE, PARTICLE_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)

##Builds a per-emitter gradient that holds one palette color fixed while its alpha flickers across each particle's lifetime.
func _make_flicker_ramp(base : Color) -> Gradient:
	var offsets : PackedFloat32Array = PackedFloat32Array([0.0, 0.12, 0.25, 0.4, 0.55, 0.72, 0.88, 1.0])
	var alphas : PackedFloat32Array = PackedFloat32Array([0.0, 1.0, 0.55, 1.0, 0.4, 1.0, 0.5, 0.0])
	var colors : PackedColorArray = PackedColorArray()
	for a in alphas:
		var c : Color = base
		c.a = a
		colors.append(c)
	var g : Gradient = Gradient.new()
	g.offsets = offsets
	g.colors = colors
	return g

##Splits count evenly across the palette emitters and applies mode-driven speed, spread and lifetime to each.
func _configure_emitters() -> void:
	if _emitters.is_empty():
		return
	var travel : float = RISE_DISTANCE if mode == Mode.RISE else EMBER_DISTANCE
	var speed_min : float = RISE_SPEED_MIN if mode == Mode.RISE else EMBER_SPEED_MIN
	var speed_max : float = RISE_SPEED_MAX if mode == Mode.RISE else EMBER_SPEED_MAX
	var lifetime : float = travel / ((speed_min + speed_max) * 0.5)
	var per_emitter : Array = _split_count(count, _emitters.size())
	for i in range(_emitters.size()):
		var p : CPUParticles2D = _emitters[i]
		var amt : int = per_emitter[i]
		p.position = Vector2(size.x * 0.5, size.y)
		p.emission_rect_extents = Vector2(maxf(size.x * 0.5, 1.0), 2.0)
		p.spread = 10.0 if mode == Mode.RISE else 16.0
		p.initial_velocity_min = speed_min
		p.initial_velocity_max = speed_max
		p.scale_amount_min = 0.85
		p.scale_amount_max = 1.25
		p.lifetime = lifetime
		p.lifetime_randomness = 0.6
		p.preprocess = lifetime
		p.amount = maxi(amt, 1)
		p.emitting = amt > 0
	if debug_me_verbose:
		print_rich(debug_name, ": configured ", count, " particles across ", _emitters.size(), " emitters, mode ", mode)

##Distributes total particles as evenly as possible across the given number of emitter groups.
func _split_count(total : int, groups : int) -> Array:
	var result : Array = []
	var base : int = total / groups
	var extra : int = total % groups
	for i in range(groups):
		result.append(base + (1 if i < extra else 0))
	return result
#endregion FUNCTIONS
