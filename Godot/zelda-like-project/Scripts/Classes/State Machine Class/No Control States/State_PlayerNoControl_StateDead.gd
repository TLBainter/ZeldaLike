##[b][color=red]StatePlayerDead[/color][/b] — player has died.[br]
##Freezes all input and enemies, fades the screen to black, then loads the last save.[br]
##[br]
##[b]LAYER[/b]: No Control
class_name StatePlayerDead
extends State

const FADE_DURATION : float = 1.5

func enter() -> void:
	print("[DBG] StatePlayerDead.enter called")
	super()
	coordinator.freeze_all()
	root.freeze_input(true)
	_start_death_sequence()

func _start_death_sequence() -> void:
	print("[DBG] StatePlayerDead._start_death_sequence begin")
	var canvas := CanvasLayer.new()
	canvas.layer = 128
	var rect := ColorRect.new()
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	get_tree().current_scene.add_child(canvas)

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	print("[DBG] StatePlayerDead: tween done, calling load_game")
	# TODO: Add Game Over Screen
	# This is Temporary
	saveManager.load_game()
