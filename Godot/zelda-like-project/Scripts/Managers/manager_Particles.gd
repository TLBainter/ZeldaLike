##Universal particle density scaler (particleManager autoload). Auto-registers every GPUParticles2D and CPUParticles2D that enters the tree and scales emission by settingsManager.get_particle_multiplier(). Opt out per node with meta "no_particle_scaling".
extends Node

#region VARIABLES
const GROUP : StringName = &"sogard_engine_particles"
const META_SKIP : StringName = &"no_particle_scaling"
const META_BASE_AMOUNT : StringName = &"sogard_base_amount"
const META_BASE_RATIO : StringName = &"sogard_base_ratio"
const META_WAS_EMITTING : StringName = &"sogard_was_emitting"
const MAX_MULT : float = 1.5
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	settingsManager.setting_changed.connect(_on_setting_changed)
	_register_tree(get_tree().root)

func _on_setting_changed(key : StringName) -> void:
	if key != &"particles":
		return
	for n in get_tree().get_nodes_in_group(GROUP):
		_apply(n)

func _register_tree(n : Node) -> void:
	_on_node_added(n)
	for c in n.get_children():
		_register_tree(c)

##Registers a particle node once: GPU emitters get their amount pre-sized to MAX_MULT so later changes only move amount_ratio and never restart emission.
func _on_node_added(n : Node) -> void:
	if not (n is GPUParticles2D or n is CPUParticles2D):
		return
	if n.has_meta(META_SKIP) or n.is_in_group(GROUP):
		return
	if not n.has_meta(META_BASE_AMOUNT):
		n.set_meta(META_BASE_AMOUNT, n.amount)
		if n is GPUParticles2D:
			n.set_meta(META_BASE_RATIO, n.amount_ratio)
			n.amount = maxi(int(ceilf(float(n.amount) * MAX_MULT)), 1)
	n.add_to_group(GROUP)
	_apply(n)

##GPU emitters scale through amount_ratio. CPU emitters scale amount directly and are stopped entirely at multiplier 0, then resumed when it rises.
func _apply(n : Node) -> void:
	var m : float = settingsManager.get_particle_multiplier()
	if n is GPUParticles2D:
		n.amount_ratio = float(n.get_meta(META_BASE_RATIO, 1.0)) * m / MAX_MULT
		return
	var base : int = int(n.get_meta(META_BASE_AMOUNT, n.amount))
	if m <= 0.0:
		if n.emitting:
			n.set_meta(META_WAS_EMITTING, true)
			n.emitting = false
		return
	n.amount = maxi(int(roundf(float(base) * m)), 1)
	if n.get_meta(META_WAS_EMITTING, false):
		n.emitting = true
		n.remove_meta(META_WAS_EMITTING)
#endregion FUNCTIONS
