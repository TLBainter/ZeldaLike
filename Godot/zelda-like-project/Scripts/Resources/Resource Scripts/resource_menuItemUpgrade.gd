##[b][color=red]MenuItemUpgradeResource[/color][/b] extends [MenuItemResource] for collectible upgrades made of parts.[br]
##E.g. 4 bone shards -> 1 skull (heart container). Tracks per-part display data and completion state.
class_name MenuItemUpgradeResource
extends MenuItemResource

@export_category("Upgrade Data")

@export_group("Parts")
##Total parts required to complete one upgrade (e.g. 4 bone shards = 1 skull).
@export var num_parts: int = 4
##One [UpgradePartData] entry per displayable state.[br]
##Add entries for part_number 0 (none) through num_parts (full set). Order does not matter.
@export var parts: Array[UpgradePartData] = []

@export_group("Full Completion")
##Mini sprite shown in the item-get popup when the [b]final part[/b] of a set is collected.[br]
##Replaces the base mini_icon for that pickup moment only.
@export var full_mini_sprite: AtlasTexture
##Dialogue CSV ref ID used for item-get text when a complete set is formed.[br]
##Replaces the base text_ref_id for the pickup popup only.
@export var full_text_ref_id: String = ""

@export_group("Limits")
##Maximum number of completed upgrades the player can hold (0 = no limit).[br]
##E.g. 20 means the player can earn at most 20 skulls (= 20 * num_parts total parts).
@export var max_quantity: int = 0

# -- Helpers ------------------------------------------------------------------

##Returns how many parts have been collected toward the [b]current[/b] (incomplete) set.[br]
##E.g. 6 total shards with num_parts=4 -> 2.
func get_current_parts(quantity: int) -> int:
	return quantity % num_parts

##Returns how many parts are still needed to complete the next upgrade.[br]
##Always in the range [1, num_parts].
func get_remaining(quantity: int) -> int:
	var current := get_current_parts(quantity)
	return num_parts if current == 0 else num_parts - current

##Returns the total number of fully completed upgrades.
func get_completed_count(quantity: int) -> int:
	return int(float(quantity) / float(num_parts))

##Returns true when the player has reached max_quantity completed upgrades.
func is_at_max(quantity: int) -> bool:
	return max_quantity > 0 and get_completed_count(quantity) >= max_quantity

##Returns the [UpgradePartData] entry matching the given part_number, or null if none is found.
func get_part_data(part_num: int) -> UpgradePartData:
	for part in parts:
		if part and part.part_number == part_num:
			return part
	return null

##Replaces [code][remaining][/code] in a dialogue string with the live count of parts still needed.[br]
##Call this when populating the info-box description or effect text for in-progress states.[br]
##Example: [code]"Collect [remaining] more to get a new skull!"[/code] -> [code]"Collect 1 more to get a new skull!"[/code]
func resolve_remaining_text(text: String, quantity: int) -> String:
	return text.replace("[remaining]", str(get_remaining(quantity)))

##Returns the max inventory quantity for this upgrade, accounting for upgrades already granted
##by the player's base stats (e.g. starting skulls from stats resource).[br]
##[param base_health]: [code]PlayerHealthComponent.base_max_health[/code] (snapshot before any runtime increases).[br]
##Use this instead of [code]max_quantity * num_parts[/code] when [member max_quantity] represents
##the total cap inclusive of base stats.
func get_adjusted_max_total(base_health: int) -> int:
	if max_quantity <= 0:
		return 0
	var effect_amount : int = 0
	if item_function and item_function.has_permanent_effects():
		for effect in item_function.permanent_effects:
			if effect.target == EffectEnums.PermanentEffectTarget.MAX_HEALTH and effect.amount > 0:
				effect_amount = effect.amount
				break
	if effect_amount <= 0:
		return max_quantity * num_parts
	var base_sets := int(float(base_health) / float(effect_amount))
	return maxi(0, max_quantity - base_sets) * num_parts
