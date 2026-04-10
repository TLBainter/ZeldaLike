##[b][color=red]BatTravelRoute[/color][/b] is the editor tool that defines a bat travel path.[br]
##Drop [b]BatTravelRoute.tscn[/b] into a level.[br]
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
var _updating_curve: bool = false

var _last_pos_a: Vector2 = Vector2(INF, INF)
var _last_pos_b: Vector2 = Vector2(INF, INF)

#endregion INTERNALS

#region FUNCTIONS

func _ready() -> void:
	if curve:
		if not curve.changed.is_connected(_on_curve_changed):
			curve.changed.connect(_on_curve_changed)
	if Engine.is_editor_hint():
		
		if _circle_a:
			_last_pos_a = _circle_a.position
		if _circle_b:
			_last_pos_b = _circle_b.position
		
		_smooth_curve()
		set_process(true)
	else:
		
		_sync_circles()
		
		if _circle_a:
			_circle_a._is_start = true
		if _circle_b:
			_circle_b._is_start = false
		set_process(false)

##Editor tick: detect when a circle node has been dragged and move the matching curve endpoint.
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not _circle_a or not _circle_b:
		return
	if _circle_a.position != _last_pos_a:
		_last_pos_a = _circle_a.position
		_move_endpoint(0, _circle_a.position)
	if _circle_b.position != _last_pos_b:
		_last_pos_b = _circle_b.position
		var last_idx: int = curve.point_count - 1 if curve else 1
		_move_endpoint(last_idx, _circle_b.position)

##Moves the curve point at [param idx] to [param pos] and re-smooths.
func _move_endpoint(idx: int, pos: Vector2) -> void:
	if not curve or curve.point_count < 2:
		return
	_updating_curve = true
	curve.set_point_position(idx, pos)
	_smooth_curve()
	_updating_curve = false

##Called when the curve is modified externally (e.g. adding interior points via Path2D tool).
func _on_curve_changed() -> void:
	if _updating_curve or _smoothing:
		return
	_sync_circles()
	_smooth_curve()

##Repositions the two interact circles to match the current curve endpoints.[br]
func _sync_circles() -> void:
	if not _circle_a or not _circle_b:
		return
	if not curve or curve.point_count < 2:
		return
	_circle_a.position = curve.get_point_position(0)
	_circle_b.position = curve.get_point_position(curve.point_count - 1)
	_last_pos_a = _circle_a.position
	_last_pos_b = _circle_b.position

##Forces all curve points to use Catmull-Rom tangents so the path is always smooth.[br]
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
