##Extends ItemFunction for consumable, single-use items.
class_name ItemFunctionConsumable
extends ItemFunction

#region VARIABLES

@export_category("Consumable Settings")
##If false, the player must wait for the current effect to expire before using another.
@export var stackable : bool = false

#endregion VARIABLES
