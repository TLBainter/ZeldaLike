##[b][color=red]DropTable[/color][/b] defines what items an entity can drop and how they are selected.[br]
##Used by breakable jars, enemies, cut grass, and any other entity with loot.[br]
##[br]
##[b]Guaranteed[/b]: Drops every item in the drop pool (skipping maxed-out items).[br]
##[b]Random[/b]: Rolls [b]drop_count[/b] times, each roll picking one item weighted by rarity.[br]
##Items the player doesn't need (at max health, energy, magic, or notes) are skipped.
class_name DropTable
extends Resource

#region VARIABLES

@export_category("Drop Table Settings")
##How items are selected from this table.[br]
##[b]Guaranteed[/b]: All items in the pool are dropped.[br]
##[b]Random[/b]: Items are selected via weighted random rolls.
@export_enum("Guaranteed", "Random") var drop_type : String = "Random"

@export_category("Item Drops")
##The pool of possible drops.[br]
##Key: [b]PickupResource[/b] — the item that can drop.[br]
##Value: [b]int[/b] — rarity modifier (Less Likely: -1, Average: 0, More Likely: 1).
@export var drop_pool : Dictionary[PickupResource, int]
##How many times to roll for an item (only used for Random drop type).
@export var drop_count : int = 1

#endregion VARIABLES

#region FUNCTIONS

##Resolves the drop table and returns an array of [b]PickupResource[/b] to spawn.[br]
##[b]player[/b]: The player node, used to check if items are needed. Pass null to skip max checks.[br]
##For Guaranteed: returns all eligible pickups in the pool.[br]
##For Random: rolls drop_count times using weighted rarity selection, skipping maxed items.
func resolve(player = null) -> Array[PickupResource]:
	var results : Array[PickupResource] = []
	if drop_pool.is_empty():
		return results
	#Build a filtered pool excluding items the player doesn't need.
	var eligible_pickups : Array[PickupResource] = []
	for pickup in drop_pool.keys():
		if pickup and _is_item_needed(pickup, player):
			eligible_pickups.append(pickup)
	if eligible_pickups.is_empty():
		return results
	match drop_type:
		"Guaranteed":
			for pickup in eligible_pickups:
				results.append(pickup)
		"Random":
			for i in range(drop_count):
				var picked = _weighted_random_pick(eligible_pickups)
				if picked:
					results.append(picked)
	return results

##Checks whether the player actually needs this item.[br]
##Returns [b]false[/b] if the player is at max for what this item provides.[br]
##Returns [b]true[/b] if no player is provided (skip check).
func _is_item_needed(pickup : PickupResource, player) -> bool:
	if not player or not pickup or not pickup.item:
		return true
	var item = pickup.item
	#Health: skip if player is at full health.
	if item.recover_health > 0:
		if player.health and player.health.cur_health >= player.health.max_health:
			print("DropTable: Skipping ", item.item_name, " — health is full (", player.health.cur_health, "/", player.health.max_health, ")")
			return false
	#Energy: skip if player is at full energy.
	if item.recover_energy > 0:
		if player.energy and player.energy.cur_energy >= (player.energy.max_energy - 1):
			print("DropTable: Skipping ", item.item_name, " — energy too high (", player.energy.cur_energy, "/", player.energy.max_energy, ")")
			return false
	#Magic: skip if player is at full magic.
	if item.recover_magic > 0:
		if player.magic and player.magic.cur_magic >= player.magic.max_magic:
			print("DropTable: Skipping ", item.item_name, " — magic is full (", player.magic.cur_magic, "/", player.magic.max_magic, ")")
			return false
	#Notes: skip if player has max notes.
	if item.grant_notes > 0:
		if player.currency and player.currency.is_full():
			print("DropTable: Skipping ", item.item_name, " — notes are full (", player.currency.cur_notes, "/", player.currency.max_notes, ")")
			return false
	print("DropTable: ", item.item_name, " is eligible to drop.")

	return true

##Performs a single weighted random selection from the eligible pickups.[br]
##Weight is calculated from the pickup's base rarity + the entry's rarity modifier.
func _weighted_random_pick(eligible : Array[PickupResource]) -> PickupResource:
	var weights : Array[float] = []
	var total_weight : float = 0.0
	for pickup in eligible:
		var weight = _calculate_weight(pickup)
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0.0:
		return null
	var roll : float = randf() * total_weight
	var cumulative : float = 0.0
	for i in range(eligible.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return eligible[i]
	return eligible.back() if not eligible.is_empty() else null

##Calculates the weight for a pickup based on its base rarity and this table's modifier.[br]
##Base weights by rarity: Common=100, Uncommon=60, Rare=30, VeryRare=15, Epic=5, Legendary=1.
func _calculate_weight(pickup : PickupResource) -> float:
	var base_rarity : int = pickup.rarity if pickup else 0
	var modifier : int = drop_pool.get(pickup, 0)
	var effective_rarity : int = clampi(base_rarity - modifier, 0, 5)
	var weight_table : Array[float] = [100.0, 60.0, 30.0, 15.0, 5.0, 1.0]
	return weight_table[effective_rarity]

#endregion FUNCTIONS
