##[b][color=red]TextResolver[/color][/b] is an autoload that resolves variable placeholders in text strings.[br]
##Placeholders use the format [code][category.key][/code].[br]
##Categories are registered at runtime with a callback that returns the value.[br]
class_name TextResolver
extends Node

#region VARIABLES

##Registered category resolvers.[br]
##Format: { "category_name" : Callable(key : String) -> String }
var _categories : Dictionary = {}

#endregion VARIABLES

#region FUNCTIONS

func _ready():
	pass

##Resolves all [category.key] placeholders in the given text.[br]
##Returns the text with all recognized placeholders replaced.
func resolve(text : String) -> String:
	var result = text
	var regex = RegEx.new()
	regex.compile("\\[([a-zA-Z_]+)\\.([a-zA-Z_]+)\\]")
	var matches = regex.search_all(result)
	#Process matches in reverse order so positions stay valid.
	matches.reverse()
	for m in matches:
		var full_match = m.get_string()
		var category = m.get_string(1)
		var key = m.get_string(2)
		var replacement = _resolve_single(category, key)
		result = result.replace(full_match, replacement)
	return result

##Resolves a single category.key pair.
func _resolve_single(category : String, key : String) -> String:
	if _categories.has(category):
		var resolver : Callable = _categories[category]
		if resolver.is_valid():
			var value = resolver.call(key)
			if value != null:
				return str(value)
	return "[" + category + "." + key + "]"

#region REGISTRATION

##Registers a category with a resolver callable.[br]
##The callable receives a key string and should return the value (any type, converted to String).[br]
##[br]
##Example:[br]
##[code]textResolver.register_category("cur", _resolve_currency)[/code][br]
##[code]func _resolve_currency(key : String):[/code][br]
##[code]    match key:[/code][br]
##[code]        "currency": return cur_notes[/code]
func register_category(category_name : String, resolver : Callable) -> void:
	_categories[category_name] = resolver

##Unregisters a category.
func unregister_category(category_name : String) -> void:
	_categories.erase(category_name)

#endregion REGISTRATION

#endregion FUNCTIONS
