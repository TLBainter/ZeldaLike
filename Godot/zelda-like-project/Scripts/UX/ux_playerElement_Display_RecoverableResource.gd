##[b][color=red]RecoverableResourceDisplay[/color][/b] is a base class for displays of recoverable[br]
##resources (energy, magic, etc). Manages component connection, update loops,[br]
##visibility/darkening of child nodes, and grid display logic.
class_name RecoverableResourceDisplay
extends UXDisplayElement

#region VARIABLES

##The recoverable resource component (e.g., EnergyComponent, MagicComponent).
var _component : RecoverableResourceComponent

#endregion VARIABLES

#region VIRTUAL METHODS

##Override to return the component type from the entity.
func _get_component(_entity: EntityClass) -> RecoverableResourceComponent:
	push_error("RecoverableResourceDisplay._get_component() not overridden in subclass!")
	return null

##Override to return the signal name for component changes.
func _get_change_signal_name() -> String:
	return "resource_changed"

##Override if additional initialization is needed.
func _on_additional_initialization() -> void:
	pass

#endregion VIRTUAL METHODS

#region FUNCTIONS

##Initialize the display with a recoverable resource component and player references.
func initialize(component : RecoverableResourceComponent, player_body : CharacterBody2D, player_cam : CamClass) -> void:
	_component = component
	if _component:
		SignalUtil.safe_connect(_component, _get_change_signal_name(), Callable(self, "_on_component_changed"))
	initialize_display(player_body, player_cam)
	_on_additional_initialization()

func _on_display_initialized() -> void:
	_rebuild_gui_elements()
	_update_gui_elements()
	if debug_me:
		print_rich(debug_name, ": [color=green][i]initialized[/i][/color].")

func _can_fade_out() -> bool:
	return _component and _component.is_full()

#endregion FUNCTIONS

#region COMPONENT CHANGE HANDLER

##Called when the component's resource changes.
func _on_component_changed(_cur : int, _max : int, _change_amount : int) -> void:
	_rebuild_gui_elements()
	_update_gui_elements()
	show_element()
	if debug_me:
		print_rich(debug_name, ": [i]resource changed[/i].")

#endregion COMPONENT CHANGE HANDLER

#region GUI ELEMENT MANAGEMENT

##Rebuild the GUI elements (may change count based on component state).
func _rebuild_gui_elements() -> void:
	if not _component:
		return
	_build_gui_elements(_get_element_count())

##Get the number of GUI elements to display (override per subclass if needed).
func _get_element_count() -> int:
	return 0

##Update the GUI elements with current component state (override in subclass).
func _update_gui_elements() -> void:
	pass

#endregion GUI ELEMENT MANAGEMENT
