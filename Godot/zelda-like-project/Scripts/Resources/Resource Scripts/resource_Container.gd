##[b][color=red]ContainerResource[/color][/b] defines the visual and audio properties of a chest or container.[br]
##Assign one of these to an [b]InteractableComponent_Container[/b] to configure the chest's appearance and sound.[br]
##[br]
##[b]Sprite Layout[/b]: A horizontal strip where the [b]first frame = closed[/b] and the [b]last frame = opened[/b].[br]
##If [b]frame_count[/b] is greater than 2, opening the chest will animate through all intermediate frames[br]
##before settling on the final opened frame.[br]
##[br]
##[b]item_kind[/b] indicates the category of item this container holds, which determines the item-get sound flavor.[br]
##The developer is responsible for ensuring the chosen reward matches the declared kind.
class_name ContainerResource
extends Resource

enum ItemKind {
	PROGRESSION,  ## Spells and mobility items
	DUNGEON_ITEM, ## Key, map, notebook
	UPGRADE,      ## Piece of heart, magic medallion, energy bolt
	INGREDIENT,   ## Crafting ingredients
	MONEY,        ## Currency / notes
}

@export_category("Container Visuals")
##A horizontal sprite strip for this chest.[br]
##[b]First frame[/b] = closed. [b]Last frame[/b] = opened.[br]
##Intermediate frames (if any) play as an opening animation.
@export var sprite_sheet : Texture2D
##Number of frames in [b]sprite_sheet[/b], sliced horizontally.
@export_range(1, 32) var frame_count : int = 2

@export_category("Container Audio")
##The sound that plays when this chest begins opening.
@export var open_sound : AudioStream

@export_category("Container Kind")
##The category of item held in this container.[br]
##Determines which item-get sound flavor plays.
@export var item_kind : ItemKind = ItemKind.PROGRESSION
