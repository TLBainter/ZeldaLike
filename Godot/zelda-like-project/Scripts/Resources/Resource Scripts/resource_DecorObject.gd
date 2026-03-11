##[b][color=red]DecorObject[/color][/b] is a resource defining the properties of a [b]DynamicDecor[/b].[br]
##Configures sprite frames (initial, destroyed, particles), sounds, and drop table.[br]
##[br]
##All frames reference indices into a single atlas texture strip (one row, uniform frame size).
class_name DecorObject
extends Resource

#region VARIABLES

@export_category("Decor Sprites")
@export_group("Atlas")
##The atlas texture strip containing all frames for this decor.[br]
##Should be a single row of uniform-sized frames.
@export var atlas_strip : AtlasTexture
##The width of each frame in pixels.
@export var frame_width : int = 16
##The height of each frame in pixels.
@export var frame_height : int = 16

@export_group("Frame Configuration")
##The frame indices to randomly choose from when the decor is first initialized.[br]
##For grass: [0, 1, 2].
@export var initial_frames : Array[int] = [0]
##The frame index to display after the decor is 'broken'.[br]
##The decor persists with this sprite after being cut/broken.
@export var destroyed_frame : int = 3
##The frame indices for the particle animation that plays when broken.[br]
##These play in order as a one-shot animation above the player, then despawn.[br]
##For grass: [4, 5].
@export var particle_frames : Array[int] = []

@export_category("Decor Audio")
##Sounds that play when this decor is broken/cut.
@export var break_sounds : SoundLibrary

@export_category("Decor Drops")
##The drop table for items that appear when this decor is broken.
@export var drop_table : DropTable

@export_category("Decor Settings")
##Whether this decor can be broken by attacks.
@export var breakable_by_attack : bool = true
##How long the particle animation plays each frame (in seconds).
@export var particle_frame_duration : float = 0.08
##Whether the decor can regrow/reset after some time.[br]
##TODO: Implement regrowth timer when needed.
@export var can_regrow : bool = false
##How long until the decor regrows (in seconds). Only used if can_regrow is true.
@export var regrow_time : float = 10.0

#endregion VARIABLES
