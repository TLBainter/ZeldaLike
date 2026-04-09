##[b][color=red]Player[/color][/b] is the player character class stemming from [b]Entity[/b]/[b]Character[/b].[br]
##This class holds holds the control data for the player.
class_name Player
extends Character

#region VARIABLES
#region NPC COMPONENTS
@export_category("Player Components")
##Currency/money handler; expects type [color=yellow]CurrencyComponent[/color]
@export var currency : CurrencyComponent
##Magic handler; expects type [color=blue]MagicComponent[/color]
@export var magic : MagicComponent
##Stamina handler; excepts type [color=green]StaminaComponent[/color]
@export var energy : EnergyComponent
##Input handler; expects type [color=grey]InputComponent[/color]
@export var input : InputComponent
##A reference to the player UX element.
@export var player_ux : PlayerUX
##reference to the player's camera
@export var player_cam : PlayerCam
@export_group("Spells")
##A reference to the player's spell management component, which tracks equipped spells.
@export var equipped_spells : EquippedSpellsComponent
##The Action Layer state that handles spell casting.
@export var cast_spell_state : StateCastSpell
##The StateCoordinator used to request Action Layer state changes.
@export var state_coordinator : StateCoordinator
@export_group("Items")
##reference to the player's Item Get Sprite.
@export var item_get_sprite : Sprite2D
##reference to the Item Get Sprite's animator
@export var igs_anim : AnimationPlayer
##reference to the player's Inventory Component.
@export var inventory : InventoryComponentPlayer
##A reference to the player's Concoction Item Use Component.
@export var concoction_use : ConcoctionItemUse
@export_category("Player Flags")
##Whether or not the player can currently dash
var can_dash : bool = true
##Whether or not the player can currently move
var can_move : bool = true
##The display name for the player
var display_name : String = "Count"
#endregion
#region MISC EXPORT VARIABLES
#endregion
#region INTERNAL VARIABLES
##the NPC's category (whether it is a shopkeeper, standard, or story NPC).
var category : String
##Tracks consecutive drop table misses for the pity system. Increments each time
##a non-empty drop table yields nothing; resets to 0 when any item drops.
##Capped at 25. Items with base weight >= 25 are unaffected by pity.
var drop_pity : int = 0
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	subtype = "Player"
	add_to_group("player")
	if textResolver:
		textResolver.register_category("player", _resolve_text)
	input.action_button_pressed.connect(_on_action_button_pressed)
	input.spell_cast_requested.connect(_on_spell_cast_requested)

func _resolve_text(key : String):
	match key:
		"name": return display_name if "display_name" in self else "Dracula"
		"health": return health.cur_health if health else 0
		"max_health": return health.max_health if health else 0
	return null

func _on_action_button_pressed(btn):
	match btn:
		"actionButton4":
			pass

##Received from [b]PlayerInputComponent.spell_cast_requested[/b].[br]
func _on_spell_cast_requested(_slot : int, spell : MenuItemResource) -> void:
	if not cast_spell_state or not state_coordinator:
		return
	cast_spell_state.prepare(spell)
	state_coordinator.request_action_change(cast_spell_state)

##Called by an AnimationPlayer method track during a spell cast animation.[br]
func _anim_start_spell() -> void:
	if cast_spell_state:
		cast_spell_state.on_start_spell()

##Called by an AnimationPlayer method track during a spell cast animation.[br]
func _anim_cast_spell() -> void:
	if cast_spell_state:
		cast_spell_state.on_cast_spell()

##Called by an AnimationPlayer method track during a spell cast animation.[br]
func _anim_end_spell_casting() -> void:
	if cast_spell_state:
		cast_spell_state.on_end_spell_casting()

#region ITEM GET SPRITE

##Shows the Item Get Sprite with [param texture] and plays the [b]acquired[/b] animation.
func show_item_get(texture : Texture2D) -> void:
	if not item_get_sprite or not igs_anim:
		return
	item_get_sprite.texture = texture
	igs_anim.play("itemAcquired")
	igs_anim.seek(0.0, true)
	item_get_sprite.visible = true

##Plays the [b]dismiss[/b] animation then hides the Item Get Sprite when it finishes.
func dismiss_item_get() -> void:
	if not igs_anim:
		return
	igs_anim.animation_finished.connect(_on_igs_dismiss_done, CONNECT_ONE_SHOT)
	igs_anim.play("itemDismiss")

func _on_igs_dismiss_done(_anim_name : String) -> void:
	if item_get_sprite:
		item_get_sprite.visible = false

#endregion ITEM GET SPRITE

#region ACTION BUTTON 4

#endregion ACTION BUTTON 4

#region INTERACTIVITY CONTROL
##Prevent the character from moving at all
func freeze_input(should_freeze : bool):
	input.set_process(not should_freeze)
	if should_freeze:
		body.velocity = Vector2.ZERO
		if anim and anim is CharacterAnimator:
			anim.can_update_facing = false
			anim.play_directional_anim(anim.idle_prefix)
		elif anim:
			anim.stop()
		if state_machine:
			state_machine.freeze_all()
	else:
		if anim and anim is CharacterAnimator:
			anim.can_update_facing = true
		if state_machine:
			state_machine.unfreeze_all()
	can_move = (not should_freeze)
		
#endregion INTERACTIVITY CONTROL
