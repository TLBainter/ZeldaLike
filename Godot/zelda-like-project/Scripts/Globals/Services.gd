## Services facade for accessing global manager autoloads.
##
## This file establishes a pattern for centralized access to global services.
## Instead of calling [b]saveManager[/b], [b]audioManager[/b], etc. directly,
## callers should use [b]Services.save[/b], [b]Services.audio[/b], etc.
##
## Over time, all call sites should be migrated to use this facade to reduce coupling
## and make it easier to refactor manager dependencies.
extends Node

@onready var save = get_node("/root/saveManager")
@onready var audio = get_node("/root/audioManager")
@onready var container = get_node("/root/containerManager")
@onready var door = get_node("/root/doorManager")
@onready var destructible = get_node("/root/destructibleManager")
@onready var enemy = get_node("/root/enemyManager")
@onready var music = get_node("/root/musicManager")
@onready var scene_transition = get_node("/root/SceneTransitionManager")
