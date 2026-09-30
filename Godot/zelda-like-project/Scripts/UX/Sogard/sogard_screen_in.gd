##Screen-enter wrapper: steps the parent CanvasItem modulate.a 0 -> 1 and position.y +offset -> rest via SogardStepper.
class_name SogardScreenIn
extends Node

#region VARIABLES
signal finished()

@export_category("Settings")
##Total enter time in milliseconds.
@export var duration_ms : int = 200
##Number of discrete steps.
@export var steps : int = 4
##Starting downward offset in pixels; steps back to the rest position.
@export var y_offset_px : int = 4
##Plays automatically when the parent enters the tree.
@export var play_on_ready : bool = true

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

var _running : bool = false
var _rest_y : float = 0.0
var _run_id : int = 0
#endregion VARIABLES

#region FUNCTIONS
func _ready() -> void:
	var p : CanvasItem = get_parent() as CanvasItem
	if not p:
		push_warning("SogardScreenIn: parent is not a CanvasItem")
		return
	if play_on_ready:
		p.set_indexed(^"modulate:a", 0.0)
		play.call_deferred()

##Runs the enter animation on the parent. Restarting mid-run keeps the original rest position.
func play() -> void:
	var p : CanvasItem = get_parent() as CanvasItem
	if not p:
		return
	if not _running:
		_rest_y = p.get_indexed(^"position:y")
	_running = true
	_run_id += 1
	var id : int = _run_id
	SogardStepper.run(self, p, ^"position:y", _rest_y + float(y_offset_px), _rest_y, duration_ms, steps)
	var done : Signal = SogardStepper.run(self, p, ^"modulate:a", 0.0, 1.0, duration_ms, steps)
	done.connect(_on_done.bind(id), CONNECT_ONE_SHOT)
	if debug_me:
		print_rich(debug_name, ": [color=cyan]screen in[/color] ", p.name)

func _on_done(id : int) -> void:
	if id != _run_id:
		return
	_running = false
	var p : CanvasItem = get_parent() as CanvasItem
	if p:
		p.set_indexed(^"position:y", _rest_y)
	finished.emit()
#endregion FUNCTIONS
