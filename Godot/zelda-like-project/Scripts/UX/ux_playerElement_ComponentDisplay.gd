##[b][color=red]ComponentDisplay[/color][/b] is a base class for UX displays that manage a component.[br]
##Provides common initialization pattern for connecting component signals and refreshing display.[br]
##Subclasses can extend this and use [method initialize_component_display] to handle common setup logic.
class_name ComponentDisplay
extends UXElement

##Initialize the component display. Calls [method _connect_component_signals] and [method _refresh_display].[br]
##Override the callback methods instead of this one to customize behavior.
func initialize_component_display(component: Node) -> void:
	if not component:
		push_warning(name + ": component is null, display will not update.")
		return
	_connect_component_signals(component)
	_refresh_display()

##Virtual. Override to connect component signals to display callbacks.
func _connect_component_signals(_component: Node) -> void:
	pass

##Virtual. Override to refresh the display with initial component state.
func _refresh_display() -> void:
	pass
