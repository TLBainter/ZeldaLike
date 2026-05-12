##[b][color=red]DropTable[/color][/b] defines what items an entity can drop and how they are selected.[br]
##Used by breakable jars, enemies, cut grass, and any other entity with loot.[br]
##[br]
##[b]Guaranteed[/b]: Drops every item in the drop pool, always - ignores player need.[br]
##[b]Random[/b]: Rolls [b]drop_count[/b] times, each roll picking one item weighted by rarity.[br]
##For Random drops, items the player doesn't need (at max health, energy, magic, or notes) are skipped.[br]
##[br]
##[b]Pity system[/b]: each consecutive miss (non-empty table, nothing dropped) increments[br]
##[b]player.drop_pity[/b] by 1 (max 25). Items with base weight < 25 receive[br]
##[b]+drop_pity[/b] to their effective weight. Any successful drop resets pity to 0.
class_name DropTable
extends Resource

#region VARIABLES

@export_category("Drop Table Settings")
##How items are selected from this table.[br]
##[b]Guaranteed[/b]: All items in the pool are dropped, regardless of player need.[br]
##[b]Random[/b]: Items are selected via weighted random rolls, skipping items the player doesn't need.
@export_enum("Guaranteed", "Random") var drop_type : String = "Random"
##The percentage chance (0-100) that this drop table is checked at all.[br]
##100 = always drops. 50 = 50% chance to skip entirely and drop nothing.
@export_range(0, 100) var drop_chance : int = 100

@export_category("Item Drops")
##The pool of possible drops.[br]
##Key: [b]PickupResource[/b] -- the item that can drop.[br]
##Value: [b]int[/b] -- drop weight. Higher = more likely relative to other entries.[br]
##Example: an entry with weight 35 is 7x more likely than one with weight 5.[br]
##Set [b]drop_chance[/b] below 100 to add a chance of dropping nothing at all.
@export var drop_pool : Dictionary[PickupResource, int]
##How many times to roll for an item (only used for Random drop type).
@export var drop_count : int = 1

@export_category("Debug")
@export var debug : DebugSettings = DebugSettings.new()
var debug_me : bool:
	get: return debug.debug_me if debug else false
var debug_me_verbose : bool:
	get: return debug.debug_me_verbose if debug else false
var debug_name : String:
	get: return debug.debug_name if debug else ""
	set(v): if debug: debug.debug_name = v

#endregion VARIABLES

#region FUNCTIONS

##Resolves the drop table and returns an array of [b]PickupResource[/b] to spawn.[br]
##[b]player[/b]: The player node, used to apply/update pity (and need-check for Random drops).[br]
##For Guaranteed: returns all items in the pool unconditionally (no need check).[br]
##For Random: rolls drop_count times using weighted rarity selection, skipping maxed items.[br]
##Pity: if nothing drops from a non-empty table, player.drop_pity increments (max 25).[br]
##If any item drops, player.drop_pity resets to 0.
func resolve(player = null) -> Array[PickupResource]:
	var results : Array[PickupResource] = []
	if drop_pool.is_empty():
		return results
	if drop_chance < 100:
		var roll = randi_range(1, 100)
		if roll > drop_chance:
			if debug_me:
				print("DropTable: Chance roll failed (", roll, " > ", drop_chance, "%); dropping nothing.")
			_apply_pity_miss(player)
			return results
		elif debug_me:
			print("DropTable: Chance roll passed (", roll, " <= ", drop_chance, "%).")
	# Guaranteed drops ignore player need; Random drops filter by need.
	var eligible_pickups : Array[PickupResource] = []
	if drop_type == "Guaranteed":
		for pickup in drop_pool.keys():
			if pickup:
				eligible_pickups.append(pickup)
	else:
		for pickup in drop_pool.keys():
			if pickup and _is_item_needed(pickup, player):
				eligible_pickups.append(pickup)
	if eligible_pickups.is_empty():
		_apply_pity_miss(player)
		return results
	var pity : int = player.drop_pity if player and "drop_pity" in player else 0
	if debug_me and pity > 0:
		print("DropTable: Applying pity bonus of +", pity, " to eligible items with base weight < 25.")
	match drop_type:
		"Guaranteed":
			for pickup in eligible_pickups:
				if debug_me_verbose:
					var item_name = pickup.item.first_get_dialogue_ref if pickup.item else "Unknown"
					print("DropTable: Guaranteed drop: ", item_name, " (always)")
				results.append(pickup)
		"Random":
			for i in range(drop_count):
				var picked = _weighted_random_pick(eligible_pickups, pity)
				if picked:
					results.append(picked)
	if results.is_empty():
		_apply_pity_miss(player)
	else:
		_apply_pity_hit(player)
	return results

##Increments player.drop_pity by 1, capped at 25.
func _apply_pity_miss(player) -> void:
	if not player or not "drop_pity" in player:
		return
	var old_pity : int = player.drop_pity
	player.drop_pity = min(player.drop_pity + 1, 25)
	if "debug_me_verbose" in player and player.debug_me_verbose:
		if old_pity < 25:
			print("DropTable: Nothing dropped; pity increased to ", player.drop_pity, "/25.")
		else:
			print("DropTable: Nothing dropped; pity already at cap (25/25).")

##Resets player.drop_pity to 0.
func _apply_pity_hit(player) -> void:
	if not player or not "drop_pity" in player:
		return
	if "debug_me_verbose" in player and player.debug_me_verbose and player.drop_pity > 0:
		print("DropTable: Item dropped; pity reset from ", player.drop_pity, " to 0.")
	player.drop_pity = 0

##Checks whether the player actually needs this item.[br]
##Returns [b]false[/b] if the player is at max for what this item provides.[br]
##Returns [b]true[/b] if no player is provided (skip check).
func _is_item_needed(pickup : PickupResource, player) -> bool:
	if not player or not pickup or not pickup.item:
		return true
	var item = pickup.item
	if item.recover_health > 0:
		if player.health and player.health.cur_health >= player.health.max_health:
			if debug_me:
				print("DropTable: Skipping ", item.first_get_dialogue_ref, "; health is full (", player.health.cur_health, "/", player.health.max_health, ")")
			return false
	if item.recover_energy > 0:
		if player.energy and player.energy.cur_energy >= (player.energy.max_energy - 1):
			if debug_me:
				print("DropTable: Skipping ", item.first_get_dialogue_ref, "; energy too high (", player.energy.cur_energy, "/", player.energy.max_energy, ")")
			return false
	if item.recover_magic > 0:
		if player.magic and player.magic.cur_magic >= player.magic.max_magic:
			if debug_me:
				print("DropTable: Skipping ", item.first_get_dialogue_ref, "; magic is full (", player.magic.cur_magic, "/", player.magic.max_magic, ")")
			return false
	if item.grant_notes > 0:
		if player.currency and player.currency.is_full():
			if debug_me:
				print("DropTable: Skipping ", item.first_get_dialogue_ref, "; notes are full (", player.currency.cur_notes, "/", player.currency.max_notes, ")")
			return false
	if debug_me:
		print("DropTable: ", item.first_get_dialogue_ref, " is eligible to drop.")

	return true

##Performs a single weighted random selection from the eligible pickups.[br]
##[b]pity[/b]: added to the effective weight of items whose base weight is below 25.
func _weighted_random_pick(eligible : Array[PickupResource], pity : int = 0) -> PickupResource:
	var weights : Array[float] = []
	var total_weight : float = 0.0
	for pickup in eligible:
		var weight = _calculate_weight(pickup, pity)
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0.0:
		return null
	if debug_me_verbose:
		print("DropTable: Rolling from pool (", eligible.size(), " eligible):")
		for i in range(eligible.size()):
			var pct = (weights[i] / total_weight) * 100.0
			var item_name = eligible[i].item.first_get_dialogue_ref if eligible[i].item else "Unknown"
			print("  ", item_name, ": ", "%.1f" % pct, "%")
	var roll : float = randf() * total_weight
	var cumulative : float = 0.0
	for i in range(eligible.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			if debug_me:
				print("DropTable: >> Selected: ", eligible[i].item.first_get_dialogue_ref if eligible[i].item else "Unknown")
			return eligible[i]
	if debug_me:
		print("DropTable: >> Selected (fallback): ", eligible.back().item.first_get_dialogue_ref if eligible.back().item else "Unknown")
	return eligible.back() if not eligible.is_empty() else null

##Returns the effective drop weight for a pickup.[br]
##Items with base weight < 25 receive [b]+pity[/b] to their weight.[br]
##Items at 25 or above are unaffected by pity.
func _calculate_weight(pickup : PickupResource, pity : int = 0) -> float:
	var pool_value : int = drop_pool.get(pickup, 1)
	var base : float = float(max(pool_value, 1))
	if base < 25.0:
		base += float(pity)
	return base

#endregion FUNCTIONS
