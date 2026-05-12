##Defines Trap node data: sprite sheet, animation timing, trigger behavior, and damage.
class_name TrapResource
extends Resource

enum TriggerType { TIME_INTERVAL, PLAYER_TOUCH }
enum PlayerTargetPart { BODY, FEET }

#region VARIABLES

@export_category("Trap Sprite")
@export_group("Sprite Sheet")
##The full horizontal sprite sheet for this trap.[br]
##Should be a single row of uniform-sized frames.
@export var sprite_texture : Texture2D
##Number of evenly-spaced frames in the sprite sheet.
@export var frame_count : int = 4
##Frame index (0-based) at which the damage event fires.
@export var damage_frame : int = 2
##How long each frame is displayed (seconds).
@export var frame_duration : float = 0.08

@export_category("Trap Behavior")
@export_group("Trigger")
##How this trap activates.
@export var trigger_type : TriggerType = TriggerType.TIME_INTERVAL
@export_group("Time Interval")
##Seconds between triggers.[br]
##Only fires while the trap is within the camera's bounds.
@export var interval_seconds : float = 2.0
@export_group("Player Touch")
##Seconds to wait after the player enters the damage area before triggering.[br]
##0.0 triggers immediately on entry.
@export_range(0.0, 1.0) var touch_delay : float = 0.0

@export_category("Trap Audio")
##Sounds to play when the trap triggers (at the start of its animation).
@export var trigger_sounds : SoundLibrary

@export_category("Trap Stats")
##Which part of the player this trap targets for damage.[br]
##[b]BODY[/b]: damages when the player's main body is in the area.[br]
##[b]FEET[/b]: damages only when the player's feet are in the area.
@export var target_part : PlayerTargetPart = PlayerTargetPart.BODY
##Damage dealt to the player when the damage frame is reached and they are inside the area.
@export_range(1, 4) var trap_damage : int = 1

#endregion VARIABLES
