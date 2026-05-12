@icon("res://Editor Tools/Icons/icon_npc.svg")
##[b][color=red]Character[/color][/b] is a subclass of the [b][color=yellow]EntityClass[/color][/b] class.[br]
##This class encompasses [b]NPCs[/b], [b]Enemies[/b], and even the [b]Player[/b].
class_name Character
extends EntityClass

#region VARIABLES
#region COMPONENTS
@export_group("Character Components")
##the character's body
@export var body : CharacterBody2D
##the area used for feet-based collision detection (e.g. trap damage targeting)
@export var foot_area : Area2D
##the navigation agent for the character
@export var nav_agent : NavigationAgent2D
#endregion
#region EXPORT VARIABLES
@export_group("Misc Character Variables")
## Current move speed. Set at runtime by movement states from StatsComponent.
var move_speed : float = 50.0
## True while the character is executing a dash or backstep (blocks MoveComponent velocity writes).
var is_dashing : bool = false
## True while the character is invulnerable and cannot receive damage.
var is_invulnerable : bool = false
## Physics frame when the last knockback ended; used to compute is_knocked_back.
var knockback_end_frame : int = -100
## True for 3 physics frames after knockback ends, covering the deferred body_entered window.
var is_knocked_back : bool:
	get: return Engine.get_physics_frames() - knockback_end_frame <= 3
## True only while StateKnockback is the active no-control state (cleared immediately on exit, before the grace timer).
var is_in_knockback : bool = false
## True while the character is holding block, zeroing MoveComponent velocity.
var is_blocking  : bool   = false
## The facing direction held during block; used by PlayerHealthComponent for directional check.
var block_facing : String = ""
#endregion
#region INTERNAL VARIABLES
##the character's subtype; this is defined by its next subclass.
var subtype : String
## Whether this character can currently move; set false during freeze_input.
var can_move : bool = true
#endregion
#region DAMAGE EFFECT EXPORTS
@export_group("Damage Effects")
##Fallback visual/audio response played when a damage source carries no [b]DamageEffectResource[/b] of its own.
@export var default_damage_effect : DamageEffectResource
#endregion
#region VISUAL EXPORTS
@export_category("Visual")
@export_group("Sprite Sheets")
##One [b]CharacterSpriteResource[/b] per texture used by this character's animations.[br]
##The first entry is applied as the default sprite sheet at runtime.
@export var visual_sprite_sheets : Array[CharacterSpriteResource] = []
@export_group("Animations")
##One [b]CharacterAnimationResource[/b] per logical animation (e.g. Idle, Walk, Run).[br]
##[b]CharacterAnimator[/b] reads these at [code]_ready()[/code] and generates the AnimationPlayer animations automatically.
@export var visual_animations : Array[CharacterAnimationResource] = []
#endregion
#endregion

#region FUNCTIONS
#region READY FUNCTION
func _ready():
	super._ready()
	type = "Character"
	if health:
		health.damage_taken.connect(_on_damage_taken)
#endregion

#region DAMAGE EFFECT
func _on_damage_taken(effect : DamageEffectResource, source_pos : Vector2, amount : int) -> void:
	var active := effect if effect else default_damage_effect
	if active:
		_apply_damage_effect(active, source_pos, amount)

func _apply_damage_effect(effect : DamageEffectResource, pos : Vector2, amount : int) -> void:
	if effect.use_flash:    _run_flash(effect, amount)
	if effect.use_particle: _run_particle(effect, pos)
	if effect.use_sprite:   _run_sprite(effect)
	if effect.use_sound:    _run_sound(effect.sound_library)

func _run_flash(effect : DamageEffectResource, amount : int) -> void:
	var count := amount if effect.flash_count_equals_damage else effect.flash_count
	var interval := effect.get_flash_interval()
	var target : CanvasItem
	if animated_sprite:
		target = animated_sprite
	else:
		target = sprite
	if not target:
		return
	for _i in count:
		target.self_modulate = effect.flash_color
		await get_tree().create_timer(interval).timeout
		target.self_modulate = Color.WHITE
		await get_tree().create_timer(interval).timeout

func _run_particle(effect : DamageEffectResource, damage_pos : Vector2) -> void:
	if not effect.particle_resource:
		return
	var node := effect.particle_resource.instantiate()
	if effect.particle_spawn_point == DamageEffectResource.ParticleSpawnPoint.CHARACTER_ROOT and body:
		body.add_child(node)
		if node is Node2D:
			node.position = Vector2.ZERO
	else:
		get_parent().add_child(node)
		if node is Node2D:
			node.global_position = damage_pos if damage_pos != Vector2.ZERO else global_position
	if node is CanvasItem:
		node.modulate = effect.particle_color
	await get_tree().create_timer(effect.get_particle_duration_value()).timeout
	node.queue_free()

func _run_sprite(effect : DamageEffectResource) -> void:
	if effect.damage_effect_sprites.is_empty():
		return
	if effect.sprite_play_style == DamageEffectResource.SpritePlayStyle.ALL_AT_ONCE:
		for spr in effect.damage_effect_sprites:
			_run_sprite_anim(spr)
	else:
		for i in effect.damage_effect_sprites.size():
			var spr : DamageEffectSprite = effect.damage_effect_sprites[i]
			_run_sprite_anim(spr)
			if i < effect.damage_effect_sprites.size() - 1:
				var loops := spr.loop_count if spr.loops else 1
				var anim_dur := (1.0 / spr.animation_speed) * spr.frame_count * loops
				await get_tree().create_timer(maxf(0.0, anim_dur + effect.sprite_interval)).timeout

func _run_sprite_anim(spr : DamageEffectSprite) -> void:
	if not spr.sprite_strip:
		return
	var node := Sprite2D.new()
	node.texture = spr.sprite_strip
	node.hframes = spr.frame_count
	node.frame = 0
	node.centered = true
	get_parent().add_child(node)
	node.global_position = global_position
	var loop_count := spr.loop_count if spr.loops else 1
	var frame_dur := 1.0 / spr.animation_speed
	for loop_idx in loop_count:
		if spr.sound_play_style == DamageEffectSprite.SoundPlayStyle.EACH_TIME or loop_idx == 0:
			_run_sound(spr.sound_library)
		for frame_idx in spr.frame_count:
			node.frame = frame_idx
			await get_tree().create_timer(frame_dur).timeout
	node.queue_free()

func _run_sound(library : SoundLibrary) -> void:
	if not library or library.sounds.is_empty():
		return
	var stream : AudioStream = library.sounds.pick_random()
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
#endregion DAMAGE EFFECT

#region KNOCKBACK

##Maps [StatsResource] weight enum values to class integers used by knockback helpers.[br]
##Light=1, Medium=2, Heavy=3. Immovable (100) returns 3 (max outgoing) but is immune to receiving knockback.
func get_weight_class() -> int:
	if not stats or not stats.resource:
		return 2
	match stats.resource.weight:
		10: return 1
		30: return 2
		60: return 3
		_:  return 3

##Returns the base knockback distance (px) for a melee interaction.[br]
##[param attacker_class] and [param target_class] are weight classes 1–3.
static func _melee_kb_base(attacker_class: int, target_class: int) -> float:
	var diff := target_class - attacker_class
	match diff:
		2:  return 16.0
		1:  return 8.0
		0:  return 4.0
		-1: return 2.0
		_:  return 4.0

##Returns the base knockback distance (px) for a projectile interaction, keyed on the entity's own class.
static func _proj_kb_base(weight_class: int) -> float:
	match weight_class:
		1: return 8.0
		2: return 4.0
		_: return 2.0

##Launches this character into [param direction] by [param distance] pixels.[br]
##No-ops when the character is already invulnerable, distance is zero, or weight is Immovable.
func receive_knockback(direction: Vector2, distance: float) -> void:
	if is_invulnerable:
		return
	if distance <= 0.0:
		return
	if stats and stats.resource and stats.resource.weight >= 100:
		return
	if not state_machine:
		return
	var knockback_state = state_machine.get_transition(StateID.KNOCKBACK)
	if not knockback_state or not knockback_state is StateKnockback:
		return
	knockback_state.setup(direction, distance)
	state_machine.request_no_control_change(knockback_state)

##Forces the active knockback to rebound, as if the player struck a wall.[br]
##Called by door triggers to prevent knockback from crossing a transition collider.
func bounce_knockback() -> void:
	var knockback_state = state_machine.get_transition(StateID.KNOCKBACK)
	if knockback_state is StateKnockback:
		knockback_state.force_rebound()

#endregion KNOCKBACK

#region FREEZE INPUT
##Freezes or unfreezes this character's input and movement.[br]
##[Player] overrides this to add animation handling and propagate to all enemies.
func freeze_input(should_freeze : bool) -> void:
	var input_component = get("input")
	if input_component:
		input_component.set_process(not should_freeze)
	if should_freeze:
		if body:
			body.velocity = Vector2.ZERO
		if state_machine:
			state_machine.freeze_all()
			state_machine.freeze_no_control()
	else:
		if state_machine:
			state_machine.unfreeze_no_control()
			state_machine.unfreeze_all()
	can_move = not should_freeze
#endregion FREEZE INPUT
