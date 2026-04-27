##[b][color=red]AudioControl[/color][/b] is the controller for local audio within a character or other entitiy.[br]
##This component handles basic connection to the global Audio Manager.
class_name AudioControl
extends Component

#region VARIABLES
@export_group("Audio Defaults")
##The default bus for audio playing from this controller; can be overriden.
@export_enum("Music", "Ambience", "UI", "Character", "Environment") var default_bus : String = "Choose One"
#endregion VARIABLES

#region FUNCTIONS
##Call this control component to play a sound. Expects stream (audio stream) and bus (the bus to play at) as an input.
##[b]stream[/b]: The audio file to play.
##[b]bus[/b]: The bust to play the audio file at (Music, Ambience, UI, Character, or Environment)
func play_sound(stream : AudioStream, bus : String = default_bus, pitch : float = 1.0) -> AudioStreamPlayer:
	if stream:
		if debug_me:
			print(debug_name, " is playing sound: ", stream.resource_path)
		return audioManager.play(stream, bus, pitch)
	return null

func _make_timer(cb: Callable, one_shot: bool = true) -> Timer:
	var t := Timer.new()
	t.one_shot = one_shot
	t.timeout.connect(cb)
	add_child(t)
	return t
#endregion FUNCITONS
