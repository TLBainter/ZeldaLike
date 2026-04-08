##[b][color=red]BatTravelRoute[/color][/b] is the editor tool that defines a bat travel path.[br]
##Drop [b]BatTravelRoute.tscn[/b] into a level, then draw the [Path2D] curve using Godot's
##built-in path editor. [b]BatTravelCircle_A[/b] and [b]BatTravelCircle_B[/b] auto-snap
##to the first and last points of the curve whenever it is edited.[br]
##[br]
##The player interacts with either circle to glide along the path to the other.[br]
##Travel speed is controlled by [member travel_speed].
@tool
class_name BatTravelRoute
extends Path2D

#region EXPORTS

##Pixels per second the player travels along the path.
@export var travel_speed: float = 200.0

#endregion EXPORTS

#region INTERNALS

@onready var _circle_a: BatTravelCircle = $BatTravelCircle_A
@onready var _circle_b: BatTravelCircle = $BatTravelCircle_B
var _smoothing: bool = false

#endregion INTERNALS

#region FUNCTIONS

func _ready() -> void:
	if curve:
		if not curve.changed.is_connected(_sync_circles):
			curve.changed.connect(_sync_circles)
	_sync_circles()
	if not Engine.is_editor_hint():
		# Tell each circle which end it is so the state knows direction.
		if _circle_a:
			_circle_a._is_start = true
		if _circle_b:
			_circle_b._is_start = false

##Repositions the two interact circles to match the current curve endpoints.[br]
##Called automatically whenever the [Curve2D] is modified in the editor.
func _sync_circles() -> void:
	if not _circle_a or not _circle_b:
		return
	if not curve or curve.point_count < 2:
		return
	_circle_a.position = curve.get_point_position(0)
	_circle_b.position = curve.get_point_position(curve.point_count - 1)
	_smooth_curve()

##Forces all curve points to use Catmull-Rom tangents so the path is always smooth.[br]
##Uses a re-entrance guard because [method set_point_in] / [method set_point_out] re-emit [signal Curve2D.changed].
func _smooth_curve() -> void:
	if _smoothing or not curve or curve.point_count < 2:
		return
	_smoothing = true
	var n := curve.point_count
	for i in range(n):
		var prev: Vector2 = curve.get_point_position(max(0, i - 1))
		var curr: Vector2 = curve.get_point_position(i)
		var next: Vector2 = curve.get_point_position(min(n - 1, i + 1))
		var tangent: Vector2 = (next - prev) * 0.5
		var t_len: float = tangent.length()
		if t_len > 0.0:
			var t_dir: Vector2 = tangent / t_len
			var in_len: float  = (curr - prev).length() / 3.0 if i > 0     else 0.0
			var out_len: float = (next - curr).length() / 3.0 if i < n - 1 else 0.0
			curve.set_point_in(i,  -t_dir * in_len)
			curve.set_point_out(i,  t_dir * out_len)
		else:
			curve.set_point_in(i,  Vector2.ZERO)
			curve.set_point_out(i, Vector2.ZERO)
	_smoothing = false

#endregion FUNCTIONS
