##Resolves variable placeholders in text strings using registered category callbacks.
##Placeholder format: [category.key]
class_name TextResolver
extends Node

#region VARIABLES

var _categories : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

func resolve(text : String) -> String:
	var result = text
	var regex = RegEx.new()
	regex.compile("\\[([a-zA-Z_]+)\\.([a-zA-Z_]+)\\]")
	var matches = regex.search_all(result)
	matches.reverse()
	for m in matches:
		var full_match = m.get_string()
		var category = m.get_string(1)
		var key = m.get_string(2)
		var replacement = _resolve_single(category, key)
		result = result.replace(full_match, replacement)
	return result

func _resolve_single(category : String, key : String) -> String:
	if _categories.has(category):
		var resolver : Callable = _categories[category]
		if resolver.is_valid():
			var value = resolver.call(key)
			if value != null:
				return str(value)
	return "[" + category + "." + key + "]"

#region REGISTRATION

func register_category(category_name : String, resolver : Callable) -> void:
	_categories[category_name] = resolver

func unregister_category(category_name : String) -> void:
	_categories.erase(category_name)

#endregion REGISTRATION

#endregion FUNCTIONS
