## Adds [b]Preview Ambience[/b] and [b]Stop Preview[/b] buttons to the top of the inspector for [b]AmbienceResource[/b].
@tool
class_name AmbienceInspectorPlugin
extends EditorInspectorPlugin

## Holds the button-press logic. A RefCounted helper with WeakRefs avoids lambdas capturing the plugin's self across inspector refreshes.
class _PreviewAction:
	extends RefCounted
	var _preview_ref: WeakRef
	var _ambience_ref: WeakRef

	func _init(preview_ref: WeakRef, ambience_ref: WeakRef) -> void:
		_preview_ref = preview_ref
		_ambience_ref = ambience_ref

	## Plays the inspected ambience through the editor preview node.
	func preview() -> void:
		var node := _preview_ref.get_ref() as AmbiencePreview
		var ambience := _ambience_ref.get_ref() as AmbienceResource
		if node == null or ambience == null:
			return
		node.preview(ambience)

	## Stops any ambience currently playing in the editor preview node.
	func stop() -> void:
		var node := _preview_ref.get_ref() as AmbiencePreview
		if node == null:
			return
		node.stop()

var _preview_ref: WeakRef

func _init(preview: AmbiencePreview) -> void:
	_preview_ref = weakref(preview)

func _can_handle(object: Object) -> bool:
	return object is AmbienceResource

func _parse_begin(object: Object) -> void:
	var action := _PreviewAction.new(_preview_ref, weakref(object))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.set_meta(&"preview_action", action)
	var play_button := Button.new()
	play_button.text = "Preview Ambience"
	play_button.tooltip_text = "Plays the music and all ambience layers in the editor."
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.pressed.connect(action.preview)
	hbox.add_child(play_button)
	var stop_button := Button.new()
	stop_button.text = "Stop Preview"
	stop_button.tooltip_text = "Stops the editor ambience preview."
	stop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stop_button.pressed.connect(action.stop)
	hbox.add_child(stop_button)
	add_custom_control(hbox)
