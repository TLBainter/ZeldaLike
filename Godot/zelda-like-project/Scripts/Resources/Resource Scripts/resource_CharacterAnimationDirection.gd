##[b][color=red]CharacterAnimationDirectionEntry[/color][/b] maps one sprite sheet row to a compass direction.[br]
##Add these inside a [b]CharacterAnimationResource[/b]'s [b]directions[/b] array — one entry per direction the animation supports.[br]
##The [b]direction[/b] property is displayed as a compass-rose grid in the Inspector (requires the [i]Character Visual Editor[/i] plugin to be enabled).
@tool
class_name CharacterAnimationDirectionEntry
extends Resource

##Compass directions matching CharacterAnimator's facing strings and the clockwise ordering expected by the compass grid UI.
enum Direction {
	Down      = 0,
	DownLeft  = 1,
	Left      = 2,
	UpLeft    = 3,
	Up        = 4,
	UpRight   = 5,
	Right     = 6,
	DownRight = 7,
}

##0-indexed row on the sprite sheet that contains this direction's frames (row 0 = top row).
@export var row: int = 0
##The compass direction this row represents. Use the compass grid to select visually.
@export var direction: Direction = Direction.Down

##Returns the lowercase facing string used internally by CharacterAnimator (e.g. "up_left").
func get_facing_string() -> String:
	match direction:
		Direction.Down:      return "down"
		Direction.DownLeft:  return "down_left"
		Direction.Left:      return "left"
		Direction.UpLeft:    return "up_left"
		Direction.Up:        return "up"
		Direction.UpRight:   return "up_right"
		Direction.Right:     return "right"
		Direction.DownRight: return "down_right"
	return "down"

##Returns the animation name suffix that matches CharacterAnimator.play_directional_anim() (e.g. "Down", "UpLeft").
func get_anim_suffix() -> String:
	return get_facing_string().capitalize().replace(" ", "")
