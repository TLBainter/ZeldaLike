##[b][color=red]EnemyProjectile[/color][/b] is a traveling Area2D that deals damage to the player on contact.[br]
##Spawned by [b]EnemyAttackComponent.spawn_projectile()[/b]; configure via [b]ProjectileAttackResource[/b].
class_name EnemyProjectile
extends Area2D

#region VARIABLES

var _dir : Vector2 = Vector2.DOWN
var _speed : float = 50.0
var _damage : int = 2
var _max_dist : float = 200.0
var _traveled : float = 0.0

#endregion VARIABLES

#region FUNCTIONS

##Initializes direction, speed, range, and damage from [param res].[br]
##Must be called immediately after instantiation, before adding to the tree.
func setup(res : ProjectileAttackResource, dir : Vector2, damage : int) -> void:
	_dir = dir.normalized()
	_speed = res.travel_speed if res else 50.0
	_max_dist = res.max_distance if res else 200.0
	_damage = damage
	if res and res.projectile_sprite_strip:
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.texture = res.projectile_sprite_strip
			if res.sprite_strip_frames > 1:
				sprite.hframes = res.sprite_strip_frames

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta : float) -> void:
	var step := _dir * _speed * delta
	position += step
	_traveled += step.length()
	if _traveled >= _max_dist:
		queue_free()

func _on_body_entered(body : Node2D) -> void:
	if body is PlayerBody:
		body.root.health.damaged(_damage, global_position)
		var target = body.root
		if target and target.has_method("receive_knockback"):
			var t_class : int = target.get_weight_class() if target.has_method("get_weight_class") else 2
			var t_dist : float = _proj_kb_dist(t_class)
			# Deferred so PlayerHealthComponent._apply_best_hit runs before is_invulnerable is set
			target.receive_knockback.call_deferred(_dir, t_dist)
		queue_free()
		return
	# Pass through enemy bodies; destroy on anything else (walls, etc.)
	if body.get_parent() is Enemy:
		return
	queue_free()

static func _proj_kb_dist(weight_class: int) -> float:
	match weight_class:
		1: return 12.0
		2: return 6.0
		_: return 3.0

#endregion FUNCTIONS
