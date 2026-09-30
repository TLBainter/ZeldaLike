##Layered Sogard menu backdrop: base color, brick wall, vignette, fog, candle flicker, blood band, falling drops, embers, rising motes, optional desaturation. Never handles input.
class_name SogardBackground
extends Control

#region VARIABLES
const PARTICLE_COUNTS : Array = [0, 10, 24, 64]
const EMBER_COUNT : int = 20

@export_category("Components")
@export var vignette : Control
@export var fog : Control
@export var candle : Control
@export var blood_top : Control
@export var drops : SogardBgDrops
@export var embers : SogardBgParticles
@export var rise : SogardBgParticles
@export var desat : Control
@export var bricks : Control

@export_category("Layers")
@export var show_bricks : bool = true:
	set(v):
		show_bricks = v
		if is_node_ready() and bricks:
			bricks.visible = v
@export var show_vignette : bool = true:
	set(v):
		show_vignette = v
		if is_node_ready() and vignette:
			vignette.visible = v
@export var show_fog : bool = true:
	set(v):
		show_fog = v
		if is_node_ready() and fog:
			fog.visible = v
@export var show_candle : bool = true:
	set(v):
		show_candle = v
		if is_node_ready() and candle:
			candle.visible = v
@export var show_blood_top : bool = true:
	set(v):
		show_blood_top = v
		if is_node_ready() and blood_top:
			blood_top.visible = v
@export var show_drops : bool = true:
	set(v):
		show_drops = v
		if is_node_ready() and drops:
			drops.visible = v
@export var show_embers : bool = true:
	set(v):
		show_embers = v
		if is_node_ready() and embers:
			embers.visible = v
@export var show_rise : bool = true:
	set(v):
		show_rise = v
		if is_node_ready() and rise:
			rise.visible = v
##Enables the desaturation/darken shader overlay (pause or defeat states).
@export var desaturated : bool = false:
	set(v):
		desaturated = v
		if is_node_ready() and desat:
			desat.visible = v

@export_category("Settings")
##Particle density for the RISE layer only. 0=Off 1=Minimal(10) 2=Standard(24) 3=Excessive(64). Plain int, no custom setter; use set_particle_level().
@export_range(0, 3, 1) var particle_level : int = 2

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("sogard_particles")
	if embers:
		embers.count = EMBER_COUNT
	_apply_all()
	set_particle_level(settingsManager.get_value(&"particles") if settingsManager else particle_level)

##Settings hook: sets the RISE layer's particle count from a 0-3 density level. EMBER stays fixed at EMBER_COUNT.
func set_particle_level(l : int) -> void:
	particle_level = clampi(l, 0, PARTICLE_COUNTS.size() - 1)
	if rise:
		rise.count = PARTICLE_COUNTS[particle_level]
	if debug_me:
		print_rich(debug_name, ": particle_level ", particle_level, " -> ", PARTICLE_COUNTS[particle_level])

##Bulk layer-visibility setter. Keys match the show_* / desaturated export names.
func set_layers(layers : Dictionary) -> void:
	for key in layers:
		if key in self:
			set(key, layers[key])

func _apply_all() -> void:
	if not is_node_ready():
		return
	if bricks:
		bricks.visible = show_bricks
	if vignette:
		vignette.visible = show_vignette
	if fog:
		fog.visible = show_fog
	if candle:
		candle.visible = show_candle
	if blood_top:
		blood_top.visible = show_blood_top
	if drops:
		drops.visible = show_drops
	if embers:
		embers.visible = show_embers
	if rise:
		rise.visible = show_rise
	if desat:
		desat.visible = desaturated
#endregion FUNCTIONS
