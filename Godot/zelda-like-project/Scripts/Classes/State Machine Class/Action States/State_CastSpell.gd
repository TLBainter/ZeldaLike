##[b][color=red]StateCastSpell[/color][/b] is the Action Layer state for casting a spell.[br]
##Entered via [b]Player._on_spell_cast_requested()[/b] after [b]prepare()[/b] is called with the target spell.[br]
##[br]
##[b]Phase 0; Interruptible:[/b] From [method enter] until [method on_cast_spell] fires.[br]
##Taking damage in this phase cancels the cast with no effect.[br]
##[b]Phase 1; Committed:[/b] After [method on_cast_spell] fires. Damage no longer interrupts.[br]
##[br]
##Animation method tracks on the AnimationPlayer call [b]Player._anim_start_spell()[/b],
##[b]Player._anim_cast_spell()[/b], and [b]Player._anim_end_spell_casting()[/b], which relay
##to [method on_start_spell], [method on_cast_spell], and [method on_end_spell_casting] here.[br]
##[br]
##[b]LAYER[/b]: Action
class_name StateCastSpell
extends State

#region VARIABLES

@export_group("Transitions")
@export var no_action_state : Node


##The spell being cast. Set by [method prepare] before the state is entered.
var current_spell : MenuItemResource = null

##0 = interruptible (before on_cast_spell fires); 1 = committed (after on_cast_spell fires).
var _cast_phase : int = 0
##The full directional animation name expected to be playing (e.g. "SpellCastHammerDown").
var _expected_anim : String = ""

#endregion VARIABLES

#region FUNCTIONS

##Called by [b]Player._on_spell_cast_requested()[/b] immediately before [b]request_action_change[/b].[br]
##Sets the spell that will be cast when [method enter] fires.
func prepare(spell : MenuItemResource) -> void:
	current_spell = spell

func enter() -> void:
	set_process(false)
	_cast_phase = 0
	_expected_anim = ""

	var character = get_character()
	if not character or not current_spell:
		_exit_to_no_action()
		return

	var cost : int = current_spell.magic_cost if current_spell is SpellResource else 0
	if cost > 0 and character.magic:
		if not character.magic.consume(cost):
			_debug_log("Not enough magic to cast: " + current_spell.item_id)
			_exit_to_no_action()
			return

	coordinator.context_locked = true
	coordinator.freeze_movement()
	lock_facing()

	if character.health:
		_safe_connect(character.health.health_changed, _on_health_changed)

	var anim_prefix : String = current_spell.cast_animation_prefix if current_spell is SpellResource else "SpellCast"
	if character.anim and character.anim is CharacterAnimator:
		character.anim.play_directional_anim(anim_prefix, true)
		_expected_anim = anim_prefix + character.anim.facing.capitalize().replace(" ", "")

	set_process(true)
	_debug_log("Spell cast entered: " + current_spell.item_id + " | anim: " + _expected_anim)
	super()

func exit() -> void:
	set_process(false)
	coordinator.context_locked = false
	coordinator.unfreeze_movement()
	unlock_facing()
	var character = get_character()
	if character and character.health:
		_safe_disconnect(character.health.health_changed, _on_health_changed)
	current_spell = null
	_cast_phase = 0
	super()

func pause() -> void:
	set_process(false)
	var character = get_character()
	if character and character.health:
		_safe_disconnect(character.health.health_changed, _on_health_changed)
	super()

func resume() -> void:
	set_process(true)
	var character = get_character()
	if character and character.health:
		_safe_connect(character.health.health_changed, _on_health_changed)
	super()

func _process(_delta : float) -> void:
	if not state_machine or state_machine.current_state != self:
		set_process(false)
		return
	var character = get_character()
	if not character or not character.anim:
		_exit_to_no_action()
		return
	var cur_anim : String = character.anim.current_animation
	if cur_anim == "" or cur_anim != _expected_anim:
		_debug_log("Animation ended or changed (fallback). phase=" + str(_cast_phase))
		_exit_to_no_action()

##Called via [b]Player._anim_start_spell()[/b] from an AnimationPlayer method track.[br]
##The cast is still interruptible at this point.
func on_start_spell() -> void:
	_cast_phase = 0
	_debug_log("[SpellCast] START SPELL - " + (current_spell.item_id if current_spell else "null"))
	print("[SpellCast] START SPELL | spell=", current_spell.item_id if current_spell else "null")

##Called via [b]Player._anim_cast_spell()[/b] from an AnimationPlayer method track.[br]
##The cast is no longer interruptible after this fires. Spell effect placeholder runs here.
func on_cast_spell() -> void:
	_cast_phase = 1
	_debug_log("[SpellCast] CAST SPELL - " + (current_spell.item_id if current_spell else "null"))
	print("[SpellCast] CAST SPELL | spell=", current_spell.item_id if current_spell else "null")

##Called via [b]Player._anim_end_spell_casting()[/b] from an AnimationPlayer method track.[br]
##Exits the cast state.
func on_end_spell_casting() -> void:
	_debug_log("[SpellCast] END SPELL CASTING - " + (current_spell.item_id if current_spell else "null"))
	print("[SpellCast] END SPELL CASTING | spell=", current_spell.item_id if current_spell else "null")
	_exit_to_no_action()

func _on_health_changed(_cur : int, _max : int, change_amount : int) -> void:
	if change_amount < 0 and _cast_phase == 0:
		_debug_log("Spell interrupted by damage!")
		print("[SpellCast] INTERRUPTED | spell=", current_spell.item_id if current_spell else "null")
		_exit_to_no_action()

func _exit_to_no_action() -> void:
	if no_action_state:
		state_machine.change_state(coordinator.try_transition(state_machine, no_action_state, "spell_cast_ended"))

#endregion FUNCTIONS
