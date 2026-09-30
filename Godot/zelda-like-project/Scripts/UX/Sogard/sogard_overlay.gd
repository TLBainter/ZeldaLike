##Top CanvasLayer that hosts Sogard modals and the toast so any screen can summon them without scene edits.
class_name SogardOverlay
extends CanvasLayer

#region VARIABLES
const NODE_NAME : String = "SogardOverlay"
const OVERLAY_LAYER : int = 100
#endregion VARIABLES

#region FUNCTIONS
##Returns the SogardOverlay under the tree root, creating it on first use.
static func host_layer(from : Node) -> SogardOverlay:
	var root : Window = from.get_tree().root
	var existing : Node = root.get_node_or_null(NODE_NAME)
	if existing is SogardOverlay:
		return existing
	var overlay : SogardOverlay = SogardOverlay.new()
	overlay.name = NODE_NAME
	overlay.layer = OVERLAY_LAYER
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(overlay)
	return overlay
#endregion FUNCTIONS
