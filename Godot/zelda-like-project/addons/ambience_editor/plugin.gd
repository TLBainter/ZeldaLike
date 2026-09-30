@tool
extends EditorPlugin

var _preview: AmbiencePreview
var _inspector: AmbienceInspectorPlugin

func _enter_tree() -> void:
	_preview = AmbiencePreview.new()
	add_child(_preview)
	_inspector = AmbienceInspectorPlugin.new(_preview)
	add_inspector_plugin(_inspector)

func _exit_tree() -> void:
	remove_inspector_plugin(_inspector)
	_preview.stop()
	_preview.queue_free()
	_inspector = null
	_preview = null
