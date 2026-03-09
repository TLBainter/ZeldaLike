##[b][color=red]PickupResource[/color][/b] wraps an [b]ItemResource[/b] with world-behavior data.[br]
##Defines how the item behaves when dropped into the world (gravity, rarity).[br]
##Referenced by [b]DropTable[/b] entries and spawned as [b]WorldItem[/b] scenes.
class_name PickupResource
extends Resource

#region VARIABLES

@export_category("Pickup Settings")
##The item this pickup represents.
@export var item : ItemResource

@export_category("World Behavior")
@export_group("Gravity")
##How the item behaves when it enters the world.[br]
##[b]Float[/b]: Drifts slowly downward like a feather.[br]
##[b]Fall[/b]: Falls to the ground like a rock.[br]
##[b]Bounce[/b]: Bounces once before settling.
@export_enum("Float", "Fall", "Bounce") var gravity_type : String = "Fall"

@export_group("Rarity")
##The base rarity of this item. Affects weighted random selection in drop tables.[br]
##Lower rarity = more common. Higher rarity = less likely to drop.[br]
##[b]Common (0)[/b]: Very frequent drops.[br]
##[b]Uncommon (1)[/b]: Moderately frequent.[br]
##[b]Rare (2)[/b]: Infrequent.[br]
##[b]VeryRare (3)[/b]: Very infrequent.[br]
##[b]Epic (4)[/b]: Extremely infrequent.[br]
##[b]Legendary (5)[/b]: Almost never drops.
@export_enum("Common:0", "Uncommon:1", "Rare:2", "VeryRare:3", "Epic:4", "Legendary:5") var rarity : int = 0

#endregion VARIABLES
