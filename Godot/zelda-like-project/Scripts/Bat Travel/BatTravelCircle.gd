##[b][color=red]BatTravelCircle[/color][/b] is the 32×32 interact zone at each end of a [BatTravelRoute].[br]
##When the player enters and presses Interact, they glide along the route's curve to the other circle.[br]
##[br]
##This node is a child of [BatTravelRoute] and auto-positions itself at the curve endpoint via [b]@tool[/b].
@tool
class_name BatTravelCircle
extends InteractableComponent

#region VARIABLES

##Set automatically by [BatTravelRoute._ready].[br]
##true = this is Circle A (start); false = Circle B (end).
var _is_start: bool = true

#endregion VARIABLES

#region FUNCTIONS

func _ready() -> void:
	interact_type = InteractType.CUSTOM
	context_key = "Bat Soar"
	shape_type = 0       # Circle
	shape_radius = 16.0  # 32×32 diameter
	super()

##Called by [StateInteract] when the player presses Interact inside this zone.[br]
##Sequences: setup → emit interaction_finished (unfreezes movement) → request state change.
func interact(user = null) -> void:
	var character: EntityClass = user as EntityClass
	var route := get_parent() as BatTravelRoute
	if not character or not route:
		interaction_finished.emit()
		return
	var bat_state := character.state_machine.get_transition("bat_travel") as StateBatTravel
	if not bat_state:
		push_error("BatTravelCircle: 'bat_travel' state not found on player. Add StateBatTravel to the Movement Layer.")
		interaction_finished.emit()
		return
	bat_state.setup(route, _is_start)
	# Emit synchronously — triggers StateInteract.exit() → coordinator.unfreeze_movement().
	interaction_finished.emit()
	# Movement layer is now unfrozen; safe to request the new movement state.
	character.state_machine.request_movement_change(bat_state)

#endregion FUNCTIONS
