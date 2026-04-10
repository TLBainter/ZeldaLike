##[b][color=red]StateRun[/color][/b] is a movement state for moving at high speeds.[br]
##While running, you can activate the dash context action.[br]
##There are things you can't do while running, though, like grabbing things or speaking.
##[br]
##[b]LAYER[/b]: Movement
class_name StateRun
extends State

#region FUNCTIONS

func enter():
	super()
	if root and "stats" in root and root.stats and root.stats.resource:
		root.move_speed = root.stats.resource.run_speed
	if root.input: _safe_connect(root.input.on_move, _on_move)
	if not state_machine.is_active:
		return
	coordinator.update_context(get_context_key())
	
func exit():
	if root.input: _safe_disconnect(root.input.on_move, _on_move)
	super()

func _on_move(_move_input : Vector2, move_strength : float):
	if move_strength < GameConstants.JOYSTICK_DEADZONE:
		var _next : State = coordinator.get_transition("idle")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "on_move+strength<0.15"))
	elif move_strength <= GameConstants.RUN_THRESHOLD:
		var _next : State = coordinator.get_transition("move")
		if _next:
			state_machine.change_state(coordinator.try_transition(state_machine, _next, "on_move+strength<=0.49"))

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
		return coordinator.try_transition(state_machine, coordinator.get_transition("dash"), "dash+running+no_held")
	return null

func _has_bat_form() -> bool:
	var character = get_character()
	if not character or not character.inventory:
		return false
	return character.inventory.has_item(ItemID.BAT_FORM) or character.inventory.has_item(ItemID.BAT_FORM_UPGRADED)

#endregion FUNCTIONS
