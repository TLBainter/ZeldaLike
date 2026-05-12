@tool
extends EditorPlugin

var _inspector: DirectionInspectorPlugin

func _enter_tree() -> void:
	_inspector = DirectionInspectorPlugin.new()
	add_inspector_plugin(_inspector)

func _exit_tree() -> void:
	remove_inspector_plugin(_inspector)
	_inspector = null
