##[b][color=red]StatePlayerBlock[/color][/b] is the player's block action state.[br]
##Holds until the block button is released or the player takes unblocked HP damage.[br]
##[br]
##[b]LAYER[/b]: Action
class_name StatePlayerBlock
extends StateBlock

#region VARIABLES

var _block_facing : String = ""

#endregion VARIABLES

#region FUNCTIONS

func enter() -> void:
	super()
	var character = get_character()
	if not character:
		push_error(debug_name + ": missing character reference in enter()")
		_exit_to_no_action()
		return
	character.is_blocking = true
	_block_facing = character.anim.facing if character.anim else "down"
	character.block_facing = _block_facing
	if character.anim and character.anim is CharacterAnimator:
		character.anim.anim_override_prefix = "Block"
		character.anim.play_directional_anim("Block")
	coordinator.freeze_movement()
	if character.body:
		character.body.velocity = Vector2.ZERO
	_activate_shape(_block_facing)
	if block_area:
		block_area.monitoring = true
	if character.energy:
		character.energy.pause_recovery()
	if character.health:
		character.health.health_changed.connect(_on_health_changed)
	coordinator.context_locked = true
	set_process(true)

func exit() -> void:
	set_process(false)
	coordinator.context_locked = false
	var character = get_character()
	if character:
		character.is_blocking = false
		character.block_facing = ""
		if character.anim and character.anim is CharacterAnimator:
			character.anim.anim_override_prefix = ""
		if character.energy:
			character.energy.resume_recovery()
		if character.health and character.health.health_changed.is_connected(_on_health_changed):
			character.health.health_changed.disconnect(_on_health_changed)
	_activate_shape("")
	if block_area:
		block_area.set_deferred("monitoring", false)
	coordinator.unfreeze_movement()
	super()

func _process(_delta: float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	var character = get_character()
	if not character or not character.anim:
		return
	if character.anim.facing != _block_facing:
		_block_facing = character.anim.facing
		character.block_facing = _block_facing
		_activate_shape(_block_facing)

func process_input(event: InputEvent) -> State:
	if event.is_action_released("block"):
		return coordinator.try_transition(state_machine,
			coordinator.get_transition(StateID.NO_ACTION), "block+released")
	return null

func _on_health_changed(_cur_hp: int, _max_hp: int, chng_amt: int) -> void:
	if chng_amt < 0:
		_exit_to_no_action()

func _exit_to_no_action() -> void:
	state_machine.change_state(coordinator.get_transition(StateID.NO_ACTION))

#endregion FUNCTIONS
