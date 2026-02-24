##[b][color=red]InGameMargin[/color][/b] is a script designed to automatically scale each side of the viewport margin in game.[br]
##By default, a margin of 16 pixels is used for the in-game margin container.[br]
##This script overrides that to allow the screen to be easily scaled and responsive!
class_name InGameMargin
extends MarginContainer

#region VARIABLES
##a reference to the player.
@export_group("Margin Container Components")
##a reference to the UX control node.
@export var me : PlayerUX
##a reference to the player.
@onready var player : CharacterBody2D = me.player
##how fast this entity will fade out when the player is beneath it.
@onready var fade_out_speed : float = me.player_detection_fadeout_speed
##the target alpha when fading out.
@onready var ux_fade_target : float = me.ux_min_alpha
##current goal alpha value for UX elements. Changes throughout the script.
var target_alpha : float = 1.0
var is_player_under_ui : bool = false

#region FUNCTIONS
func _ready():
	#Disable process to save frame rate and resources.
	#Process is disabled throughout this script for optimization.
	set_process(false)
	#TODO: Test this functionality
	#Connects the viewport size change signal to the margin update script.
	get_viewport().size_changed.connect(_update_margins)
	me.check_viewport_size.connect(_update_margins)
	#Link to timer for checking various UX entities
	#Also verify that 'me' is assigned in inspector
	if me:
		me.check_ux_overlap.connect(_check_player_overlap)
		if me.debug_me and me.debug_me_verbose:
			print("overlap signal connected!")
	else:
		printerr("PlayerUX not assigned in the Inspector! Check the inspecetor of ", me.debug_name)
	_update_margins()
		
func _check_player_overlap():
	if not player:
		#assign the player if it has a null value
		player = me.player
		return
	
	##A reference to the player's position on the screen
	var player_screen_pos = player.get_global_transform_with_canvas().origin
	var my_rect = get_global_rect()
	var is_overlapping = get_global_rect().has_point(player_screen_pos)
	
	#Debug Print
	if me and me.debug_me and me.debug_me_verbose:
		print("--- UX Overlap Check ---")
		print("\tPlayer Screen Pos: ", player_screen_pos)
		print("\tMargin Global Rect: ", my_rect)
		print("\tIs Overlapping: ", is_overlapping)
		print("\tis_player_under_ui state: ", is_player_under_ui)
	
	#Fade out
	if is_overlapping and not is_player_under_ui:
		is_player_under_ui = true
		target_alpha = ux_fade_target
		set_process(true)
	#Fade back in
	elif not is_overlapping and is_player_under_ui:
		is_player_under_ui = false
		target_alpha = 1.0
		set_process(true)
	
func _process(delta):
	modulate.a = move_toward(modulate.a, target_alpha, fade_out_speed * delta)
	if modulate.a == target_alpha:
		set_process(false)
		
#region MARGINS
func _update_margins():
	if not me.player_cam:
		return false
	else:
		##the scale of the viewport when this function is called
		var viewport_size = get_viewport_rect().size / me.player_cam.zoom
	
		#add padding based on viewport size
		if viewport_size != null:
			##X axis padding, with a target of 16 pixels.
			var padding_x = clampi(int(viewport_size.x * 0.01), 16, 32)
			##Y axis padding, with a target of 16 pixels.
			var padding_y = clampi(int(viewport_size.y * 0.02), 16, 32)
			
			add_theme_constant_override("margin_left", padding_x)
			add_theme_constant_override("margin_right", padding_x)
			add_theme_constant_override("margin_top", padding_y)
			add_theme_constant_override("margin_bottom", padding_y)
		#resort to default padding
		else:
			add_theme_constant_override("margin_left", -16)
			add_theme_constant_override("margin_right", -16)
			add_theme_constant_override("margin_top", -16)
			add_theme_constant_override("margin_bottom", -16)
		return true
#endregion MARGINS
#endregion FUNCTIONS
