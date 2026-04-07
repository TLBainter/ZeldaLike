##[b][color=red]Menu Item Resource[/color][/b] is a class for gathering data pertaining to a single menu item to display.[br]
##This is how the menu item's outline, animated sprite, and text data is provided.
class_name MenuItemResource
extends Resource

@export_category("Menu Item Data")
@export_group("Identity")
##The unique item identifier. Must match an ItemID constant.
@export var item_id : String = ""
@export_group("Images")
##The single, static outline image of the item; displays when the item is not available in the menu.[br]
##E.g., if the item has not yet been collected, this will show, instead.
@export var outline : AtlasTexture
##The primary strip of data; should be a 9-frame sprite with 32px size.
@export var main : AtlasTexture
##The smaller, 16px version of the image
@export var mini_icon : AtlasTexture
@export_group("Text")
##The Ref ID in the Dialogue CSV for this item's text.[br]
##Line 1 = name, Line 2 = description, Line 3 = effect.
@export var text_ref_id : String = ""
@export_group("Config")
@export_subgroup("Sprite Flashing")
##Whether or not the sprite should flash while hovered.
@export var flash : bool = true
##What color the sprite should flash while it is hovered over:
@export var flash_color : Color = Color(1.0, 1.0, 1.0, 1.0)
@export_subgroup("Sprite Sheet")
##The number of vertical frames on the sprite sheet.
@export var v_frames : int = 1
##The number of horizontal frames on the sprite sheet.
@export var h_frames : int = 9
@export_subgroup("Count")
##Whether the sprite should show its text quantity.
@export var display_quantity : bool = false
@export_subgroup("Function")
##The initial function of the item.
@export var item_function : ItemFunction
