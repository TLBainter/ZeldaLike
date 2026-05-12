##[b][color=red]CharacterSpriteResource[/color][/b] describes a single sprite sheet used by a character.[br]
##Add one per texture in the character's [b]Visual → Sprite Sheets[/b] export group.[br]
##The [b]sheet_name[/b] is referenced by [b]CharacterAnimationResource[/b] to bind animations to this sheet.
@tool
class_name CharacterSpriteResource
extends Resource

@export_group("Sprite Sheet")
##The sprite sheet texture.
@export var texture: Texture2D
##Unique name for this sheet; referenced by CharacterAnimationResource.sprite_sheet_name.
@export var sheet_name: String = ""
##Side length of one sprite in pixels (e.g. 16 → 16×16 sprites).[br]
##hframes = texture.width / sprite_size. All sprites in the sheet must be square and uniform.
@export var sprite_size: int = 16

##Returns the number of horizontal frames calculated from the texture width and sprite size.
func get_hframes() -> int:
	if not texture or sprite_size <= 0:
		return 0
	return int(float(texture.get_width()) / sprite_size)

##Returns the number of vertical frames calculated from the texture height and sprite size.
func get_vframes() -> int:
	if not texture or sprite_size <= 0:
		return 0
	return int(float(texture.get_height()) / sprite_size)
