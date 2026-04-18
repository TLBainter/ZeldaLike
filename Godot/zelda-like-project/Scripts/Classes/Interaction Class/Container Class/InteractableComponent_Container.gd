@icon("res://Editor Tools/Icons/icon_chest.svg")
##[b][color=red]InteractableComponent_Container[/color][/b] is a pluggable container interaction zone.[br]
##Extends [b]InteractableComponent[/b] with chest-opening logic.[br]
@tool
class_name InteractableComponent_Container
extends InteractableComponent

#region CONSTANTS

##Frames per second for multi-frame chest opening animations.
const CHEST_ANIM_FPS : float = 8.0

#endregion CONSTANTS

#region EXPORTS

@export_group("Container Settings")
##The resource defining this chest's sprite sheet, open sound, and item kind.
@export var container_data : ContainerResource:
	set(v):
		if container_data and container_data.changed.is_connected(_on_container_data_changed):
			container_data.changed.disconnect(_on_container_data_changed)
		container_data = v
		if container_data and Engine.is_editor_hint():
			container_data.changed.connect(_on_container_data_changed)
		_setup_sprite()

##The resource defining what item the player receives from this chest.
@export var reward : ContainerRewardResource:
	set(v):
		if reward and reward.changed.is_connected(_on_reward_changed):
			reward.changed.disconnect(_on_reward_changed)
		reward = v
		if reward and Engine.is_editor_hint():
			reward.changed.connect(_on_reward_changed)
		_update_item_preview()

@export_group("References")
##The [b]Sprite2D[/b] that displays the chest. Driven by [b]container_data.sprite_sheet[/b].
@export var chest_sprite : Sprite2D:
	set(v):
		chest_sprite = v
		_setup_sprite()

##Editor-only preview sprite showing what item this chest contains.[br]
##Automatically updated from [b]reward.item_resource[/b]. Hidden at runtime.
@export var contained_item_sprite : Sprite2D:
	set(v):
		contained_item_sprite = v
		_update_item_preview()

#endregion EXPORTS

#region VARIABLES

##Whether this chest has been opened. Persisted across sessions via [b]containerManager[/b].
var is_opened : bool = false

# Resolved per interact() call — accounts for upgrade chain logic.
var _resolved_item_id : String = ""
var _resolved_item_kind : ContainerRewardResource.ItemKind = ContainerRewardResource.ItemKind.PROGRESSION
var _resolved_mini_sprite : Texture2D = null
var _resolved_dialogue_ref : String = ""

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	interact_type = InteractType.CONTAINER
	super._ready()
	_setup_sprite()
	if Engine.is_editor_hint():
		_update_item_preview()
		return
	# Hide the item preview sprite at runtime; it is only for level editing.
	if contained_item_sprite:
		contained_item_sprite.visible = false
	# Restore opened state from ContainerManager so chests stay open across sessions.
	# Also subscribe to containers_restored so a /load can update state without a scene reload.
	if containerManager:
		containerManager.containers_restored.connect(_on_containers_restored)
		_on_containers_restored()

##Called by [b]State_Interact[/b] to begin the chest-opening sequence.
func interact(user = null) -> void:
	if is_opened:
		return
	if not container_data:
		push_error(name, ": no ContainerResource assigned")
		return
	if not reward:
		push_error(name, ": no ContainerRewardResource assigned")
		return
	if not user is Player:
		push_error(name, ": interact() called without a Player reference")
		return

	_resolve_upgrade(user)

	# Play the chest open sound (random clip from library).
	if container_data.open_sound and not container_data.open_sound.sl.is_empty() and audioManager:
		audioManager.play(container_data.open_sound.sl.pick_random(), "Sound Effects")

	# Face the player up and play the chest-open animation.
	if user.anim and user.anim is CharacterAnimator:
		user.anim.can_update_facing = false
		user.anim.force_face(Vector2.UP)
		user.anim.play_directional_anim(AnimationNames.CHEST_OPEN, true)
		user.anim.animation_finished.connect(_on_chest_open_done.bind(user), CONNECT_ONE_SHOT)
	else:
		_on_chest_open_done("", user)

	# Animate the chest sprite concurrently with the player animation.
	_animate_sprite_open()

func _on_chest_open_done(_anim_name : String, user : Player) -> void:
	if user.anim and user.anim is CharacterAnimator:
		user.anim.force_face(Vector2.DOWN)
		user.anim.play_directional_anim(AnimationNames.ITEM_GET, true)
		user.anim.animation_finished.connect(_on_item_get_done.bind(user), CONNECT_ONE_SHOT)
	else:
		_on_item_get_done("", user)

func _on_item_get_done(_anim_name : String, user : Player) -> void:
	# Play the item-get sting for this container's kind.
	if container_data and audioManager:
		var sting := _get_item_get_sound(_resolved_item_kind)
		if sting:
			audioManager.play(sting, "UI")

	var mini_sprite := _resolved_mini_sprite
	var ref_id := _resolved_dialogue_ref

	# Show Item Get Sprite.
	if mini_sprite:
		user.show_item_get(mini_sprite)

	if ref_id != "" and user.player_ux and user.player_ux.dialogue_controller:
		var data : Dictionary = dialogueDB.get_dialogue_data(ref_id)
		if not data.is_empty():
			# Column C is the item name; item-get text starts at Column D, so drop the first line.
			if data["lines"].size() > 1:
				data = { "character": data["character"], "lines": data["lines"].slice(1) }
			var dc = user.player_ux.dialogue_controller
			dc.start_dialogue(data, user.input)
			dc.dialogue_closed.connect(_on_dialogue_closed.bind(user), CONNECT_ONE_SHOT)
			return

	# No dialogue (or lookup failed); dismiss sprite and finish immediately.
	user.dismiss_item_get()
	_finish(user)

## Returns the item-get sting [AudioStream] for the given [enum ContainerRewardResource.ItemKind].[br]
## Once you have the audio files, replace [code]null[/code] with [code]preload("res://Sound/SFX/UX/Item Get/YourFile.wav")[/code].
static func _get_item_get_sound(kind : ContainerRewardResource.ItemKind) -> AudioStream:
	match kind:
		ContainerRewardResource.ItemKind.PROGRESSION:
			return null  # Replace: preload("res://Sound/SFX/UX/Item Get/Progression_Sting.wav")
		ContainerRewardResource.ItemKind.DUNGEON_ITEM:
			return null  # Replace: preload("res://Sound/SFX/UX/Item Get/DungeonItem_Sting.wav")
		ContainerRewardResource.ItemKind.UPGRADE:
			return null  # Replace: preload("res://Sound/SFX/UX/Item Get/Upgrade_Sting.wav")
		ContainerRewardResource.ItemKind.INGREDIENT:
			return null  # Replace: preload("res://Sound/SFX/UX/Item Get/Ingredient_Sting.wav")
		ContainerRewardResource.ItemKind.MONEY:
			return null  # Replace: preload("res://Sound/SFX/UX/Item Get/Money_Sting.wav")
	return null

func _on_dialogue_closed(user : Player) -> void:
	user.dismiss_item_get()
	_finish(user)

func _finish(user : Player) -> void:
	# Re-enable facing updates before handing control back.
	if user.anim and user.anim is CharacterAnimator:
		user.anim.can_update_facing = true

	# Apply consumable effects (health, energy, magic, currency) — Money items only.
	if _resolved_item_kind == ContainerRewardResource.ItemKind.MONEY:
		var item_res : ItemResource = ItemID.ITEM_RESOURCES.get(_resolved_item_id)
		if item_res:
			if item_res.recover_health > 0 and user.health:
				user.health.healed(item_res.recover_health)
			if item_res.recover_energy > 0 and user.energy:
				user.energy.restore(item_res.recover_energy)
			if item_res.recover_magic > 0 and user.magic:
				user.magic.restore(item_res.recover_magic)
			if item_res.grant_notes > 0 and user.currency:
				user.currency.add(item_res.grant_notes)

	# Grant the item to inventory.
	if _resolved_item_id != "" and user.inventory:
		var mir_cap : MenuItemResource = ItemID.MENU_ITEM_RESOURCES.get(_resolved_item_id)
		var upgrade_cap := mir_cap as MenuItemUpgradeResource
		var base_health : int = user.health.base_max_health if user.health else 0
		var at_max := upgrade_cap and upgrade_cap.max_quantity > 0 \
			and user.inventory.get_quantity(_resolved_item_id) >= upgrade_cap.get_adjusted_max_total(base_health)
		if not at_max:
			var qty_before : int = user.inventory.get_quantity(_resolved_item_id)
			user.inventory.add_item(_resolved_item_id, 1)
			var qty_after : int = user.inventory.get_quantity(_resolved_item_id)
			_apply_upgrade_permanent_effects(_resolved_item_id, qty_before, qty_after, user)

	is_opened = true
	containerManager.mark_opened(_get_chest_id())
	set_active(false)
	interaction_finished.emit()

#region UPGRADE HELPERS

func _apply_upgrade_permanent_effects(item_id: String, qty_before: int, qty_after: int, user: Player) -> void:
	var mir : MenuItemResource = ItemID.MENU_ITEM_RESOURCES.get(item_id)
	var upgrade := mir as MenuItemUpgradeResource
	if not upgrade or not upgrade.item_function or not upgrade.item_function.has_permanent_effects():
		return
	var timing := upgrade.item_function.permanent_effect_timing
	var sets_to_apply := 0
	if timing == EffectEnums.PermanentEffectTiming.ON_COMPLETE:
		sets_to_apply = int(float(qty_after) / upgrade.num_parts) - int(float(qty_before) / upgrade.num_parts)
	else:
		sets_to_apply = qty_after - qty_before
	for _i in range(sets_to_apply):
		for effect in upgrade.item_function.permanent_effects:
			match effect.target:
				EffectEnums.PermanentEffectTarget.MAX_HEALTH:
					if user.health:
						user.health.increase_max(effect.amount)
				EffectEnums.PermanentEffectTarget.MAX_ENERGY:
					if user.energy:
						user.energy.increase_max(effect.amount)
				EffectEnums.PermanentEffectTarget.MAX_MAGIC:
					if user.magic:
						user.magic.collect_shards(effect.amount)

## Resolves which item to actually give, accounting for the mobility upgrade chain.
## Sets _resolved_item_id/kind/mini_sprite/dialogue_ref before the opening sequence begins.
func _resolve_upgrade(user : Player) -> void:
	# Default: give exactly what the reward says.
	_resolved_item_id = reward.item_id
	_resolved_item_kind = reward.item_kind
	_resolved_mini_sprite = reward.reward_mini_sprite
	_resolved_dialogue_ref = reward.reward_dialogue_ref

	if not ItemID.MOBILITY_UPGRADES.has(reward.item_id):
		_resolve_part_display(user)
		return

	var base_id : String = reward.item_id
	var upgrade_id : String = ItemID.MOBILITY_UPGRADES[base_id]
	var has_base : bool = user.inventory.has_item(base_id)
	var has_upgrade : bool = user.inventory.has_item(upgrade_id)

	if not has_base:
		pass  # Give the base item — defaults already set.
	elif not has_upgrade:
		# Give the upgrade instead.
		_resolved_item_id = upgrade_id
		var mir : MenuItemResource = ItemID.MENU_ITEM_RESOURCES.get(upgrade_id)
		if mir:
			_resolved_mini_sprite = mir.mini_icon
			_resolved_dialogue_ref = mir.text_ref_id
	else:
		# Player has both — give an orange bead and log the error.
		_resolved_item_id = ItemID.ORANGE_BEAD
		_resolved_item_kind = ContainerRewardResource.ItemKind.MONEY
		var item_res : ItemResource = ItemID.ITEM_RESOURCES.get(ItemID.ORANGE_BEAD)
		if item_res:
			_resolved_mini_sprite = item_res.mini_sprite
			_resolved_dialogue_ref = item_res.first_get_dialogue_ref
		_log_upgrade_error(base_id)

## For [MenuItemUpgradeResource] items, replaces the default mini sprite and dialogue ref
## with the data for the specific part the player is about to receive.
func _resolve_part_display(user : Player) -> void:
	var mir := ItemID.MENU_ITEM_RESOURCES.get(_resolved_item_id) as MenuItemUpgradeResource
	if not mir or not user.inventory:
		return
	var qty_before : int = user.inventory.get_quantity(_resolved_item_id)
	var qty_after : int = qty_before + 1
	if qty_after % mir.num_parts == 0:
		if mir.full_mini_sprite:
			_resolved_mini_sprite = mir.full_mini_sprite
		if mir.full_text_ref_id != "":
			_resolved_dialogue_ref = mir.full_text_ref_id
	else:
		var part := mir.get_part_data(mir.get_current_parts(qty_after))
		if part and part.part_mini_sprite:
			_resolved_mini_sprite = part.part_mini_sprite
		if not mir.text_ref_id.is_empty():
			_resolved_dialogue_ref = mir.text_ref_id

func _log_upgrade_error(base_id : String) -> void:
	var scene_name := ""
	if get_tree() and get_tree().current_scene:
		scene_name = get_tree().current_scene.scene_file_path.get_file().get_basename()
	var msg := "[b]ERROR[/b]: Player already has [" + base_id + "], but tried to get it again from Chest [" + _get_chest_id() + "] in Scene [" + scene_name + "]!"
	if debugConsole:
		debugConsole.log(msg)
	push_error(msg)

#endregion UPGRADE HELPERS

#region RESOURCE SIGNAL HANDLERS

func _on_container_data_changed() -> void:
	_setup_sprite()

func _on_reward_changed() -> void:
	_update_item_preview()

#endregion RESOURCE SIGNAL HANDLERS

#region SPRITE HELPERS

##Applies the sprite sheet and hframes to [b]chest_sprite[/b] and shows frame 0 (closed).[br]
##Safe to call in the editor and at runtime.
func _setup_sprite() -> void:
	if not chest_sprite or not container_data:
		return
	chest_sprite.texture = container_data.sprite_sheet
	chest_sprite.hframes = maxi(1, container_data.frame_count)
	chest_sprite.vframes = 1
	chest_sprite.frame = 0

##Updates [b]contained_item_sprite[/b] to show the reward item's static sprite.[br]
##Runs in the editor only; the sprite is hidden at runtime.
func _update_item_preview() -> void:
	if not contained_item_sprite:
		return
	if not reward:
		contained_item_sprite.texture = null
		return
	if reward.item_kind == ContainerRewardResource.ItemKind.MONEY:
		if not reward.item_resource or not reward.item_resource.item_strip:
			contained_item_sprite.texture = null
			return
		contained_item_sprite.texture = reward.item_resource.item_strip
		contained_item_sprite.hframes = 5
		contained_item_sprite.vframes = 1
		contained_item_sprite.frame = 0
	else:
		var mini_icon := reward.reward_mini_sprite
		contained_item_sprite.texture = mini_icon
		contained_item_sprite.hframes = 1
		contained_item_sprite.vframes = 1
		contained_item_sprite.frame = 0

func _last_frame() -> int:
	if not container_data:
		return 0
	return maxi(0, container_data.frame_count - 1)

##Snaps [b]chest_sprite[/b] to [param frame_index].
func _show_frame(frame_index : int) -> void:
	if chest_sprite:
		chest_sprite.frame = frame_index

##Advances the chest sprite from frame 0 to the last frame.[br]
##Snaps instantly for 1–2 frames; tweens at [b]CHEST_ANIM_FPS[/b] for 3+ frames.
func _animate_sprite_open() -> void:
	var fc := container_data.frame_count if container_data else 1
	if fc <= 2:
		_show_frame(_last_frame())
		return
	# Step through frames 1..last with a fixed interval between each.
	var tween := create_tween()
	var interval := 1.0 / CHEST_ANIM_FPS
	for f in range(1, fc):
		var frame_index := f  # capture for lambda
		tween.tween_callback(func(): _show_frame(frame_index))
		tween.tween_interval(interval)

#endregion SPRITE HELPERS

#region PERSISTENCE HELPERS

##Called when [b]containerManager[/b] restores saved state (on [method load_game]).[br]
##Also called once during [method _ready] so startup and load-without-transition both work.
func _on_containers_restored() -> void:
	if is_opened:
		return
	if containerManager and containerManager.is_opened(_get_chest_id()):
		is_opened = true
		_show_frame(_last_frame())
		set_active(false)

##Returns a stable ID for this chest: scene_file_path + "::" + node path from scene root.[br]
##Unique as long as the node is not renamed or moved in the scene tree.
func _get_chest_id() -> String:
	var scene_path : String = ""
	if get_tree() and get_tree().current_scene:
		scene_path = get_tree().current_scene.scene_file_path
	return scene_path + "::" + str(get_path())

#endregion PERSISTENCE HELPERS

#endregion FUNCTIONS
