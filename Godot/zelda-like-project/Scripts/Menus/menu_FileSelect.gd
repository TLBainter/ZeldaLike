class_name FileSelect
extends Control

signal slot_selected(slot: int)

@onready var _grid : GridContainer = $GridContainer

func _ready() -> void:
	for i in saveManager.SLOT_COUNT:
		var panel := _grid.get_child(i) as FileSelectPanel
		if panel:
			panel.panel_selected.connect(_on_panel_selected)

func open(is_new_game: bool) -> void:
	for i in saveManager.SLOT_COUNT:
		var panel := _grid.get_child(i) as FileSelectPanel
		if not panel:
			continue
		var data       : Dictionary = saveManager.read_save_data(i)
		var selectable : bool       = is_new_game or not data.is_empty()
		panel.setup(i, data, selectable)

func _on_panel_selected(slot: int) -> void:
	slot_selected.emit(slot)
