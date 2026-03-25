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
@export var mini : AtlasTexture
@export_group("Text")
##The name of the entity.
@export var name : String = str(outline)
##The description of the entity.
@export var description : String = "Please provide a description."
##The effect of the entity.
@export var effect : String = "Please provide the entity's effect."
@export_subgroup("Fonts")
##Font to use for description text.
@export var description_font : Font = preload("res://Sprites/UX/Fonts/GothicPixelSerif.ttf")
##Font used for the effect text.
@export var effect_font : Font = preload("res://Sprites/UX/Fonts/GothicPixelSerif.ttf")
@export_group("Config")
@export_subgroup("Sprite Flashing")
##Whether or not the sprite should flash while hovered.
@export var flash : bool = true
##What color the sprite should flash while it is hovered over:
@export var flash_color : Color = Color(1.0, 1.0, 1.0, 1.0)
@export_subgroup("Count")
##Whether the sprite should show its text quantity.
@export var display_quantity : bool = false
