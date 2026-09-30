##Stepped property animation for Sogard UI. Replaces Tween easing with discrete steps (CSS steps(n), jump-end).
class_name SogardStepper
extends RefCounted

#region VARIABLES
const META_KEY : StringName = &"sogard_stepper_key"
#endregion VARIABLES

#region FUNCTIONS
##Steps target.property from -> to over duration_ms in steps jumps via a Timer child of owner. Returns a Signal emitted once the final value is set.
static func run(owner : Node, target : Object, property : NodePath, from : Variant, to : Variant, duration_ms : int, steps : int) -> Signal:
	var n : int = maxi(steps, 1)
	var key : String = "%d:%s" % [target.get_instance_id(), String(property)]
	stop(owner, target, property)
	var timer : Timer = Timer.new()
	timer.set_meta(META_KEY, key)
	timer.add_user_signal("finished")
	timer.one_shot = false
	timer.ignore_time_scale = true
	timer.wait_time = maxf(float(maxi(duration_ms, 1)) / 1000.0 / float(n), 0.001)
	var state : Dictionary = {"k": 0}
	target.set_indexed(property, from)
	timer.timeout.connect(func() -> void:
		state.k += 1
		if not is_instance_valid(target):
			timer.stop()
			timer.emit_signal("finished")
			timer.queue_free()
			return
		if state.k >= n:
			target.set_indexed(property, to)
			timer.stop()
			timer.emit_signal("finished")
			timer.queue_free()
		else:
			target.set_indexed(property, _step_value(from, to, float(state.k) / float(n)))
	)
	owner.add_child(timer)
	timer.start()
	return Signal(timer, "finished")

##Frees any running stepper on owner for the same target and property. The stopped run never emits finished.
static func stop(owner : Node, target : Object, property : NodePath) -> void:
	if not is_instance_valid(owner) or not is_instance_valid(target):
		return
	var key : String = "%d:%s" % [target.get_instance_id(), String(property)]
	for child in owner.get_children():
		if child is Timer and child.has_meta(META_KEY) and child.get_meta(META_KEY) == key:
			child.stop()
			child.queue_free()

##Interpolated value at fraction t. Ints are rounded so pixel positions stay whole.
static func _step_value(from : Variant, to : Variant, t : float) -> Variant:
	if typeof(from) == TYPE_INT and typeof(to) == TYPE_INT:
		return int(round(lerpf(float(from), float(to), t)))
	if typeof(from) == TYPE_VECTOR2I:
		return Vector2i(Vector2(from).lerp(Vector2(to), t).round())
	return lerp(from, to, t)
#endregion FUNCTIONS
