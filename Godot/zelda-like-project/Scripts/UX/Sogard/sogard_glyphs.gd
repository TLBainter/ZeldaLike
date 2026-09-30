##Resolves controller glyph textures by platform and key. Stage 4 may replace the body; the signature is frozen.
class_name SogardGlyphs
extends RefCounted

#region VARIABLES
const PATH_FORMAT : String = "res://Sprites/UX/Sogard/sogard_glyph_%s_%s.tres"
const PLATFORMS : PackedStringArray = ["xbox", "ps", "switch"]
const KEYS : PackedStringArray = ["a", "b", "x", "y", "lb", "rb", "start", "dpad", "act1", "act2", "act3"]
const ACTION_KEYS : Dictionary = {"act1": "a", "act2": "b", "act3": "x"}
const SWITCH_ACTION_KEYS : Dictionary = {"act1": "b", "act2": "a", "act3": "y"}
#endregion VARIABLES

#region FUNCTIONS
##Returns the glyph texture for platform ("xbox", "ps", "switch") and key (a b x y lb rb start dpad, or act1 act2 act3 for the south, east and west buttons bound to actionButton1-3), or null when unknown.
static func get_texture(platform : String, key : String) -> Texture2D:
	var p : String = platform.to_lower()
	var k : String = key.to_lower()
	if not PLATFORMS.has(p) or not KEYS.has(k):
		return null
	k = str((SWITCH_ACTION_KEYS if p == "switch" else ACTION_KEYS).get(k, k))
	var path : String = PATH_FORMAT % [p, k]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
#endregion FUNCTIONS
