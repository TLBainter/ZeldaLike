##[b][color=red]StatsResource[/color][/b] defines the base stats for an entity.[br]
##Attach to any entity to configure health, defense, weight, speed, and player resources.[br]
##Shared across instances of the same entity type.
class_name StatsResource
extends Resource

#region VARIABLES

@export_category("All Entities")
@export_group("Survivability")
## The maximum health of this entity.
@export var max_health : int = 4
## The defense modifier of this entity. Negative = more vulnerable, positive = more resistant.
@export_range(-1, 5) var defense : int = 0
@export_group("Physicality")
## The weight of this entity. Affects push/pull speed, throw distance, and knockback resistance.
@export_enum("Light:10", "Medium:30", "Heavy:60", "Immovable:100") var weight : int = 30

@export_category("Character")
@export_group("Speed")
## Cooldown in seconds between allowed attacks. Prevents repeated attacks for both player and enemies.
@export var attack_speed : float = 1.0
## The speed used when dodging/rolling. Reserved for future use.
@export var dodge_speed : float = 100.0
## The speed used when walking.
@export var walk_speed : float = 50.0
## The speed used when running.
@export var run_speed : float = 75.0

@export_category("Player")
@export_group("Resources")
## The maximum energy (in total units, not bolts) the player starts with.
@export var max_energy : int = 4
## The maximum magic (in total shards) the player starts with.
@export var max_magic : int = 6

#endregion VARIABLES
