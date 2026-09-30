##Directional focus scoring for Sogard menus: center to center, along + 2.4 x sideways offset, lowest score wins.
class_name SogardFocusNav
extends RefCounted

#region VARIABLES
const MIN_ALONG : float = 4.0
const ORTH_WEIGHT : float = 2.4
#endregion VARIABLES

#region FUNCTIONS
##Returns the best candidate in dir from the from control, or null. Candidates less than 4 px ahead along dir are rejected.
static func pick(from : Control, candidates : Array[Control], dir : Vector2i) -> Control:
	if not from or dir == Vector2i.ZERO:
		return null
	var v : Vector2 = Vector2(dir).normalized()
	var origin : Vector2 = from.get_global_rect().get_center()
	var best : Control = null
	var best_score : float = INF
	for c in candidates:
		if c == from or not is_instance_valid(c):
			continue
		var d : Vector2 = c.get_global_rect().get_center() - origin
		var along : float = d.x * v.x + d.y * v.y
		if along <= MIN_ALONG:
			continue
		var orth : float = absf(d.x * -v.y + d.y * v.x)
		var score : float = along + orth * ORTH_WEIGHT
		if score < best_score:
			best_score = score
			best = c
	return best

##Returns every visible, focusable, enabled Control under root (root included).
static func focusables(root : Node) -> Array[Control]:
	var out : Array[Control] = []
	if root:
		_collect(root, out)
	return out

static func _collect(node : Node, out : Array[Control]) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is Control and node.focus_mode != Control.FOCUS_NONE and not _is_disabled(node):
		out.append(node)
	for child in node.get_children():
		_collect(child, out)

static func _is_disabled(node : Node) -> bool:
	var d : Variant = node.get("disabled")
	return d is bool and d
#endregion FUNCTIONS
