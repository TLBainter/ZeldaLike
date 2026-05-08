##[b][color=red]StateRun[/color][/b] is a movement state for moving at high speeds.[br]
##While running, you can activate the dash context action.[br]
##There are things you can't do while running, though, like grabbing things or speaking.
##[br]
##[b]LAYER[/b]: Movement
class_name StateRun
extends MovementState

#region FUNCTIONS

func enter():
	super()
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.run_speed
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < GameConstants.JOYSTICK_DEADZONE:
		_safe_transition(StateID.IDLE)
	elif move_strength <= GameConstants.RUN_THRESHOLD:
		_safe_transition(StateID.MOVE)

func get_context_key() -> String:
	if coordinator.held_object:
		return "throw"
	if _has_bat_form():
		return "Bat Dash"
	return ""

func process_input(event : InputEvent) -> State:
	if event.is_action_pressed("actionButton4") or event.is_action_pressed("dash"):
		if coordinator.held_object:
			return null
		if not _has_bat_form():
			return null
		if coordinator.is_on_dodge_cooldown():
			return null
		return coordinator.try_transition(state_machine, coordinator.get_transition(StateID.DASH), "dash+running+no_held")
	return null

func _has_bat_form() -> bool:
	var character = get_character()
	var inv = character.get("inventory") if character else null
	if not inv:
		return false
	return inv.has_item(ItemID.BAT_FORM) or inv.has_item(ItemID.BAT_FORM_UPGRADED)

#endregion FUNCTIONS
