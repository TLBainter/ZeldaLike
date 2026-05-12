##Defines item properties: visuals, sound, first-pickup dialogue, and effects.
##Used by PickupResource to define world-droppable items.
##Sprite layout: 5 frames at 16x16. Frame 0=static, 1-4=sparkle animation. Shadow follows same layout.
class_name ItemResource
extends Resource

#region VARIABLES

@export_category("Item Sprites")
@export_group("Item Texture")
##The full atlas texture strip for this item (5 frames, 80x16).[br]
##Frame 0: static. Frames 1-4: sparkle animation.
@export var item_strip : AtlasTexture
@export_group("Shadow Texture")
##The full atlas texture strip for this item's shadow (5 frames, 80x16).[br]
##Frame 0: static. Frames 1-4: shadow animation synced with bob.
@export var shadow_strip : AtlasTexture

@export_category("Item Effects")
@export_group("Recovery")
##How much health this item restores. 0 = no health recovery.
@export var recover_health : int = 0
##How much energy this item restores. 0 = no energy recovery.
@export var recover_energy : int = 0
##How much magic this item restores. 0 = no magic recovery.
@export var recover_magic : int = 0
@export_group("Currency")
##How many notes (money) this item grants. 0 = no notes.
@export var grant_notes : int = 0

@export_category("Item Get Sprite")
##The texture shown in the Item Get Sprite when this item is picked up.[br]
##Used for container rewards. World items use their [b]item_strip[/b] frame 0 instead.
@export var mini_sprite : Texture2D

@export_category("Item Audio")
##Sounds that play when this item is picked up or used.
@export var use_sounds : SoundLibrary

@export_category("Item Dialogue")
##The dialogue reference ID for the first-time-get message.[br]
##Uses the existing dialogue CSV system. Leave empty for no dialogue.
@export var first_get_dialogue_ref : String = ""
##Whether to always show the dialogue on pickup, not just the first time.
@export var always_show_dialogue : bool = false

#endregion VARIABLES
