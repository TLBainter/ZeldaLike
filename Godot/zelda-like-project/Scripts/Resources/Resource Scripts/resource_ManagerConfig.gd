## Configuration resource for manager behavior.
##
## This resource provides a centralized place to configure manager settings
## without modifying core manager code. Managers can read this config in _ready()
## and apply relevant settings based on the scene context.
##
## Extend with more configuration options as managers grow and new behaviors are needed.
class_name ManagerConfig
extends Resource

@export var persist_across_rooms: bool = true
@export var emit_signals_on_restore: bool = false
