extends Node

func safe_connect(obj: Object, sig: String, handler: Callable) -> void:
	if obj and not obj.is_connected(sig, handler):
		obj.connect(sig, handler)
