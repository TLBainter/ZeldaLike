##[b][color=red]CharacterAnimationResource[/color][/b] defines one logical animation (e.g. "Idle", "Walk") and all its directional rows.[br]
##Add these inside a Character's [b]Visual → Animations[/b] export group.[br]
##At runtime, [b]CharacterAnimator[/b] reads this data and generates AnimationPlayer animations named [b]{animation_name}{Direction}[/b][br]
##(e.g. animation_name="Walk" → "WalkDown", "WalkUp", "WalkLeft", "WalkRight").
@tool
class_name CharacterAnimationResource
extends Resource

@export_group("Sprite Sheet")
##Must exactly match the [b]sheet_name[/b] of one of the character's CharacterSpriteResources.
@export var sprite_sheet_name: String = ""

@export_group("Animation")
##Name prefix used by CharacterAnimator.play_directional_anim(). Spaces are removed automatically.[br]
##Example: "Idle" → generates "IdleDown", "IdleUp", "IdleLeft", "IdleRight".
@export var animation_name: String = "":
	set(v): animation_name = v.replace(" ", "")
##Frames played per second.
@export var frame_rate: float = 10.0
##Whether the animation loops.
@export var loops: bool = true
##Number of frames to use from each row. Set to -1 to use all horizontal frames the sprite sheet provides.
@export var frame_count: int = -1

@export_group("Directions")
##One entry per compass direction this animation supports. Each entry maps a sprite sheet row to a direction.
@export var directions: Array[CharacterAnimationDirectionEntry] = []
