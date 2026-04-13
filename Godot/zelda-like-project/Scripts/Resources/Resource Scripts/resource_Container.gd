##[b][color=red]ContainerResource[/color][/b] defines the visual and audio properties of a chest or container.[br]
##Assign one of these to an [b]InteractableComponent_Container[/b] to configure the chest's appearance and sound.[br]
##[br]
##[b]Sprite Layout[/b]: A horizontal strip where the [b]first frame = closed[/b] and the [b]last frame = opened[/b].[br]
##If [b]frame_count[/b] is greater than 2, opening the chest will animate through all intermediate frames[br]
##before settling on the final opened frame.
class_name ContainerResource
extends Resource

@export_category("Container Visuals")
##A horizontal sprite strip for this chest.[br]
##[b]First frame[/b] = closed. [b]Last frame[/b] = opened.[br]
##Intermediate frames (if any) play as an opening animation.
@export var sprite_sheet : Texture2D
##Number of frames in [b]sprite_sheet[/b], sliced horizontally.
@export_range(1, 32) var frame_count : int = 2

@export_category("Container Audio")
##The sound library that plays when this chest begins opening.[br]
##A random clip is selected each time the chest is opened.
@export var open_sound : SoundLibrary
