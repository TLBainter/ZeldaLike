##Groups the sound libraries used by the menuSfx autoload for every shared menu sound.
class_name MenuSfxConfig
extends Resource

##Played when focus moves between menu elements.
@export var nav_move : SoundLibrary
##Generic confirm played when a menu element is pressed.
@export var confirm : SoundLibrary
##Confirm played when a difficulty is chosen.
@export var confirm_difficulty : SoundLibrary
##Confirm played when a game is started or continued.
@export var confirm_start_game : SoundLibrary
##Played when a slider value changes, on the bus the slider controls.
@export var slider_move : SoundLibrary
##Played when a page opens or switches.
@export var page_open : SoundLibrary
##Played when a page closes.
@export var page_close : SoundLibrary
