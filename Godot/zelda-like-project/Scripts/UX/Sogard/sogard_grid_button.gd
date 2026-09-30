##SogardButton key for on-screen grids (name entry). Lifts 1 px while focused, supports a dimmed caption and forwards directions to a grid handler for wrap navigation.
class_name SogardGridButton
extends SogardButton

#region VARIABLES
const SCENE_PATH : String = "res://Scenes/UX/Sogard/sogard_button.tscn"
const SCRIPT_PATH : String = "res://Scripts/UX/Sogard/sogard_grid_button.gd"
const DIM_COLOR : Color = Color("#6a5559")
const DIM_FOCUSED_COLOR : Color = Color("#8a6a30")
const BONE_COLOR : Color = Color("#e9e0cf")
const GOLD_COLOR : Color = Color("#ffd21f")
const LIFT_PX : int = 1

##Cell in the owning grid: x is the column, y is the row.
@export var grid_pos : Vector2i = Vector2i.ZERO
##Resting position; the focused lift is applied on top of it.
@export var base_position : Vector2 = Vector2.ZERO:
	set(v):
		base_position = v
		_apply_lift()
##Dims the caption (#6a5559, #8a6a30 while focused) without disabling focus.
@export var dimmed : bool = false:
	set(v):
		dimmed = v
		color_normal = DIM_COLOR if v else BONE_COLOR
		color_focused = DIM_FOCUSED_COLOR if v else GOLD_COLOR

##Called as direction_handler.call(grid_pos, dir) and must return true when the direction was handled.
var direction_handler : Callable
#endregion VARIABLES

#region FUNCTIONS
##Instances sogard_button.tscn with this script, sized to the plate texture, with no pointer.
static func build(plate_n : StyleBox, plate_f : StyleBox, caption : String, cell : Vector2i) -> SogardGridButton:
	var node : Control = (load(SCENE_PATH) as PackedScene).instantiate()
	node.set_script(load(SCRIPT_PATH))
	var b : SogardGridButton = node as SogardGridButton
	b.name = "Key_%d_%d" % [cell.y, cell.x]
	b.grid_pos = cell
	b.pointer = SogardButton.PointerType.NONE
	b.plate_normal = plate_n
	b.plate_focused = plate_f
	b.text = caption
	var tex : StyleBoxTexture = plate_n as StyleBoxTexture
	if tex and tex.texture:
		b.size = tex.texture.get_size()
	return b

func _ready() -> void:
	_resolve_components()
	super._ready()
	_apply_lift()

##Focus visual plus the 1 px lift.
func set_focused_visual(on : bool) -> void:
	super.set_focused_visual(on)
	_apply_lift()

##Direction routed from SogardNavInput. Returns true when the grid handler moved focus.
func handle_direction(dir : Vector2i) -> bool:
	if not direction_handler.is_valid():
		return false
	return direction_handler.call(grid_pos, dir)

func _resolve_components() -> void:
	if not plate:
		plate = get_node_or_null(^"Plate") as Panel
	if not label:
		label = get_node_or_null(^"Label") as Label
	if not glyph_chip:
		glyph_chip = get_node_or_null(^"GlyphChip") as TextureRect
	if not pointer_left:
		pointer_left = get_node_or_null(^"Pointer") as TextureRect
	if not pointer_right:
		pointer_right = get_node_or_null(^"PointerRight") as TextureRect
	if not glow:
		glow = get_node_or_null(^"Glow") as TextureRect
	if not anim:
		anim = get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	if not glow_anim:
		glow_anim = get_node_or_null(^"GlowPlayer") as AnimationPlayer

func _apply_lift() -> void:
	position = base_position - Vector2(0, LIFT_PX if _focused else 0)
#endregion FUNCTIONS
