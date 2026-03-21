##[b][color=red]PauseMenu[/color][/b] controls the pause menu overlay.[br]
##Instantiated when the player pauses. Fades in a dark overlay, displays the menu,[br]
##and handles unpause input. Runs while the game is paused.[br]
class_name PauseMenu
extends Node

#region VARIABLES

@export_category("Pause Menu Components")
##The CanvasLayer containing the pause menu UI.
@export var canvas : CanvasLayer
##The MarginContainer or root control of the menu content.
@export var menu_container : Control
##The input controller for the menu.
@export var menu_controller : MenuController

@export_category("Fade Settings")
##How fast the dark overlay fades in (seconds).
@export var fade_in_duration : float = 0.3
##How fast the dark overlay fades out (seconds).
@export var fade_out_duration : float = 0.3
##The target darkness of the overlay (0.0 = transparent, 1.0 = fully black).
@export var overlay_darkness : float = 0.5

@export_category("Sounds")
##The sound library for random sounds to play when the player navigates a menu.
@export var nav_move_sounds : SoundLibrary

@export_category("Debug")
@export var debug_me : bool = false
@export var debug_name : String = "PauseMenu"

#=======INTERNAL VARIABLES=======#

##The dark overlay ColorRect.
var _overlay : ColorRect
##The canvas overlay layer.
var _overlay_layer : CanvasLayer
##Whether the menu is currently closing (fading out).
var _is_closing : bool = false
###===CHANGE #1: replace tween with process-based fade===###
##Whether we are currently fading in.
var _fading_in : bool = false
##Whether we are currently fading out.
var _fading_out : bool = false

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#This node must process while paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	#Create the dark overlay on a separate CanvasLayer below the menu.
	_create_overlay()
	#configure the menu controller
	if menu_controller:
		menu_controller.activate()
	#Hide menu content initially, fade it in.
	if menu_container:
		menu_container.modulate.a = 0.0
	#Pause the game.
	get_tree().paused = true
	#Start fade in.
	_fading_in = true
	set_process(true)
	if debug_me:
		print(debug_name, ": Pause menu opened.")

##Open the pause menu; used in place of [color=blue]_ready()[/color] once the menu has been instantiated.
func open() -> void:
	_is_closing = false
	_fading_out = false
	if canvas:
		canvas.visible = true
	if _overlay_layer:
		_overlay_layer.visible = true
	if _overlay:
		_overlay.color.a = 0.0
	if menu_container:
		menu_container.modulate.a = 0.0
	get_tree().paused = true
	_fading_in = true
	set_process(true)
	if debug_me:
		print(debug_name, ": Pause menu reopened.")

func _unhandled_input(event : InputEvent) -> void:
	if _is_closing:
		return
	#Close on pause or actionButton1.
	if event.is_action_pressed("pause") or event.is_action_pressed("actionButton1"):
		get_viewport().set_input_as_handled()
		_close()

#region OVERLAY

##Creates a full-screen dark overlay on a CanvasLayer below the menu canvas.
func _create_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 99
	_overlay_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(_overlay_layer)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_overlay_layer.add_child(_overlay)
	#Make sure the menu canvas renders above the overlay.
	if canvas:
		canvas.layer = 100

#endregion OVERLAY

#region FADE

##Fades out the overlay and menu, then unpauses and frees.
func _process(delta : float) -> void:
	if _fading_in:
		if _overlay:
			_overlay.color.a = move_toward(_overlay.color.a, overlay_darkness, delta / fade_in_duration)
		if menu_container:
			menu_container.modulate.a = move_toward(menu_container.modulate.a, 1.0, delta / fade_in_duration)
		#Check if fade in is complete.
		var overlay_done = _overlay.color.a >= overlay_darkness if _overlay else true
		var menu_done = menu_container.modulate.a >= 1.0 if menu_container else true
		if overlay_done and menu_done:
			_fading_in = false
			set_process(false)
	elif _fading_out:
		if _overlay:
			_overlay.color.a = move_toward(_overlay.color.a, 0.0, delta / fade_out_duration)
		if menu_container:
			menu_container.modulate.a = move_toward(menu_container.modulate.a, 0.0, delta / fade_out_duration)
		#Check if fade out is complete.
		var overlay_done = _overlay.color.a <= 0.0 if _overlay else true
		var menu_done = menu_container.modulate.a <= 0.0 if menu_container else true
		if overlay_done and menu_done:
			_fading_out = false
			set_process(false)
			_on_fade_out_complete()

func _on_fade_out_complete() -> void:
	get_tree().paused = false
	if canvas:
		canvas.visible = false
	if _overlay_layer:
		_overlay_layer.visible = false
	if debug_me:
		print(debug_name, ": Pause menu closed. Game resumed.")

#endregion FADE

#region CLOSE

##Initiates the close sequence.
func _close() -> void:
	if _is_closing:
		return
	_is_closing = true
	if menu_controller:
		menu_controller.deactivate()
	_fading_in = false
	_fading_out = true
	set_process(true)
	if debug_me:
		print(debug_name, ": Closing pause menu...")

#endregion CLOSE

#endregion FUNCTIONS
