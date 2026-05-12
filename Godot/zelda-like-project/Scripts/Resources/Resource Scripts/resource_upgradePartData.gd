##[b][color=red]UpgradePartData[/color][/b] holds display data for a single part-count state of a [MenuItemUpgradeResource].[br]
##Add one entry per displayable state: part_number 0 (none collected) through num_parts (full set complete).
class_name UpgradePartData
extends Resource

@export_category("Upgrade Part Data")
@export_group("Identity")
##Which part count this entry represents.[br]
##0 = seen but none collected; num_parts = fully completed set.
@export var part_number: int = 0

@export_group("Sprites")
##Mini sprite shown in the item-get popup when this part is collected.[br]
##Leave blank to fall back to [MenuItemUpgradeResource].mini_icon.
@export var part_mini_sprite: AtlasTexture
##Static image shown in the menu when the panel is [b]not[/b] hovered.
@export var part_static_sprite: AtlasTexture
##Animation strip played in the menu when the panel [b]is[/b] hovered.[br]
##Same format as [MenuItemResource].main - a horizontal sprite strip.
@export var part_anim_sprite: AtlasTexture

@export_group("Anim Config")
##Horizontal frame count for the anim strip (mirrors [MenuItemResource].h_frames).
@export var anim_h_frames: int = 9
##Vertical frame count for the anim strip.
@export var anim_v_frames: int = 1
