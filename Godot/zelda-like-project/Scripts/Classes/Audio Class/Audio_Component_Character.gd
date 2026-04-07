##[b][color=red]CharacterAudioControl[b][/color] is used to play audio from an Entity_Character class.
class_name CharacterAudioControl
extends AudioControl

#region VARIABLES

@export_category("Components")
##The Health component of this entity
@export var health : HealthComponent
##The parent character (root node)
@export var root : Character
##The local audio player for the character (if any)
@export var local_audio : AudioStreamPlayer2D
##The character's body
@onready var body : CharacterBody2D = root.body

#region sound libraries
#Sound Libraries#

@export_category("Sound Libraries")
@export_group("Damage and Heal")
##sounds to play when damaged
@export var damage_sounds : SoundLibrary
##sounds to play when taking heavy damage
@export var heavy_damage_sounds : SoundLibrary
##sounds to play when healed
@export var heal_sounds : SoundLibrary
##sounds to play when dying
@export var death_sounds : SoundLibrary
@export_group("Footstep")
##The default walking sounds if others are not available
@export var generic_walk_sounds : SoundLibrary
##sounds to play when walking on carpet
@export var carpet_walk_sounds : SoundLibrary
##sounds to play when walking on dirt
@export var dirt_walk_sounds : SoundLibrary
##sounds to play when walking on grass
@export var grass_walk_sounds : SoundLibrary
##sounds to play when walking on stone
@export var stone_walk_sounds : SoundLibrary
##sounds to play when walking on wood
@export var wood_walk_sounds : SoundLibrary
@export_group("Attack")
##sounds to play when performing an attack swing
@export var attack_sounds : SoundLibrary
@export_group("Dodge")
##sounds to play when starting a dash
@export var enter_dash_sounds : SoundLibrary
##sounds to play when ending a dash
@export var exit_dash_sounds : SoundLibrary
##looping wingbeat sounds during the dash (up to 2 overlap, randomized pitch)
@export var bat_flap_sounds : SoundLibrary
##stochastic squeak sounds during the dash (randomized pitch)
@export var bat_squeak_sounds : SoundLibrary
##sounds to play when starting a backstep
@export var enter_backstep_sounds : SoundLibrary
##sounds to play when ending a backstep
@export var exit_backstep_sounds : SoundLibrary
##sounds to play when rebounding off a wall after a dash
@export var rebound_sounds : SoundLibrary

#endregion sound libraries

#region dash loop state
var _dash_loop_active : bool = false
var _bat_flap_active_count : int = 0
var _bat_flap_timer : Timer
var _bat_squeak_chance : float = 0.5
var _bat_squeak_timer : Timer
#endregion dash loop state

#endregion VARIABLES

#region FUNCTIONS
func _ready():
	if health:
		health.health_changed.connect(_on_health_changed)
	_bat_flap_timer = Timer.new()
	_bat_flap_timer.one_shot = true
	_bat_flap_timer.timeout.connect(_on_bat_flap_timer)
	add_child(_bat_flap_timer)
	_bat_squeak_timer = Timer.new()
	_bat_squeak_timer.one_shot = true
	_bat_squeak_timer.timeout.connect(_on_bat_squeak_timer)
	add_child(_bat_squeak_timer)

#region local sound
##Plays a sound locally
func _play_local_sound(stream : AudioStream, bus : String = default_bus, pitch : float = 1.0):
	if stream and local_audio:
		if debug_me:
			print(debug_name, " is playing sound: ", stream.resource_path, " from local audio!")
		local_audio.bus = bus
		local_audio.stream = stream
		local_audio.pitch_scale = pitch
		local_audio.play()
#endregion local sound

#region health and damage audio
##Receives the health change signal and plays a sound from a set based on the damage or healing received.
func _on_health_changed(cur_hp : int, _max_hp : int, change_amount : int):
	#TAKING DEADLY DAMAGE#
	if cur_hp == 0:
		_play_death_sound()
		return
	#TAKING HEAVY DAMAGE#
	elif change_amount <= -4 and heavy_damage_sounds != null and heavy_damage_sounds.sl.has(AudioStream):
		_play_heavy_damage_sound()
		return
	#TAKING SOME DAMAGE#
	elif change_amount < 0:
		_play_damage_sound()
		return
	#RECEIVING HEALING#
	elif change_amount > 0:
		_play_heal_sound()
		return

##Plays Heavy Damage Sound
func _play_heavy_damage_sound():
	#Return if no audio value
	if heavy_damage_sounds == null:
		return
	
	#Get random sound
	var clip = heavy_damage_sounds.sl.pick_random()
	
	#Play the sound with the appropriate bus
	#If local audio is available, it will play it there.
	#Otherwise, it will only play the sound globally with the audio manager.
	if local_audio != null:
		_play_local_sound(clip, default_bus)
	else:
		play_sound(clip, default_bus)

##Plays Damage Sound
func _play_damage_sound():
		#Return if no audio value
	if damage_sounds == null:
		return
	
	#Get random sound
	var clip = damage_sounds.sl.pick_random()
	
	#Play the sound with the appropriate bus
	#If local audio is available, it will play it there.
	#Otherwise, it will only play the sound globally with the audio manager.
	if local_audio != null:
		_play_local_sound(clip, default_bus)
	else:
		play_sound(clip, default_bus)

##Plays Heal Sound
func _play_heal_sound():
		#Return if no audio value
	if heal_sounds == null:
		return
	
	#Get random sound
	var clip = heal_sounds.sl.pick_random()
	
	#Play the sound with the appropriate bus
	#If local audio is available, it will play it there.
	#Otherwise, it will only play the sound globally with the audio manager.
	if local_audio != null:
		_play_local_sound(clip, default_bus)
	else:
		play_sound(clip, default_bus)

##Plays Death Sound
func _play_death_sound():
		#Return if no audio value
	if death_sounds == null:
		return
	
	#Get random sound
	var clip = death_sounds.sl.pick_random()
	
	#Play the sound with the appropriate bus
	#If local audio is available, it will play it there.
	#Otherwise, it will only play the sound globally with the audio manager.
	if local_audio != null:
		_play_local_sound(clip, default_bus)
	else:
		play_sound(clip, default_bus)

##Plays a one-shot dodge sound from a SoundLibrary through the global audio manager (non-positional).
func _play_one_shot(library : SoundLibrary) -> void:
	if library == null or library.sl.is_empty():
		return
	play_sound(library.sl.pick_random(), default_bus)

#region dodge one-shots
##Plays a random enter-dash sound.
func play_enter_dash_sound() -> void:
	_play_one_shot(enter_dash_sounds)

##Plays a random exit-dash sound.
func play_exit_dash_sound() -> void:
	_play_one_shot(exit_dash_sounds)

##Plays a random enter-backstep sound.
func play_enter_backstep_sound() -> void:
	_play_one_shot(enter_backstep_sounds)

##Plays a random exit-backstep sound.
func play_exit_backstep_sound() -> void:
	_play_one_shot(exit_backstep_sounds)

##Plays a random dash rebound sound.
func play_rebound_sound() -> void:
	_play_one_shot(rebound_sounds)
#endregion dodge one-shots

#region dash loop
##Starts the bat-flap and bat-squeak layers. Call from StateDash.enter().
func start_dash_loop() -> void:
	_dash_loop_active = true
	_bat_flap_active_count = 0
	_bat_squeak_chance = 0.5
	_schedule_bat_flap()
	_roll_bat_squeak()

##Stops both dash loop layers. Call from StateDash.exit().
func stop_dash_loop() -> void:
	_dash_loop_active = false
	_bat_flap_timer.stop()
	_bat_squeak_timer.stop()

# --- Bat Flap ---
func _schedule_bat_flap() -> void:
	if not _dash_loop_active or bat_flap_sounds == null or bat_flap_sounds.sl.is_empty():
		return
	var clip : AudioStream = bat_flap_sounds.sl.pick_random()
	if _bat_flap_active_count < 2:
		_bat_flap_active_count += 1
		var ap : AudioStreamPlayer = play_sound(clip, default_bus, randf_range(0.9, 1.1))
		if ap:
			ap.volume_db = linear_to_db(0.25)
			ap.finished.connect(_on_bat_flap_sound_finished, CONNECT_ONE_SHOT)
	_bat_flap_timer.start(randf_range(clip.get_length() * 0.5, clip.get_length()))

func _on_bat_flap_timer() -> void:
	_schedule_bat_flap()

func _on_bat_flap_sound_finished() -> void:
	_bat_flap_active_count = maxi(0, _bat_flap_active_count - 1)

# --- Bat Squeak ---
func _roll_bat_squeak() -> void:
	if not _dash_loop_active:
		if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] _roll_bat_squeak called but loop inactive ; bailing.")
		return
	if bat_squeak_sounds == null or bat_squeak_sounds.sl.is_empty():
		if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] _roll_bat_squeak bailing ; library null or empty.")
		return
	var roll := randf()
	if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] rolling: ", snappedf(roll, 0.01), " vs chance ", snappedf(_bat_squeak_chance, 0.01))
	if roll < _bat_squeak_chance:
		_bat_squeak_chance = 0.4
		var clip : AudioStream = bat_squeak_sounds.sl.pick_random()
		var pitch := randf_range(0.9, 1.1)
		var ap : AudioStreamPlayer = play_sound(clip, default_bus, pitch)
		if ap:
			ap.volume_db = linear_to_db(0.1)
			ap.finished.connect(_on_bat_squeak_sound_finished, CONNECT_ONE_SHOT)
			if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] PLAYING ; clip=", clip.resource_path.get_file(),
				"  pitch=", snappedf(pitch, 0.01), "  bus=", ap.bus, "  player=", ap)
		else:
			if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] play_sound returned NULL ; chain broken!")
	else:
		_bat_squeak_chance = 0.6
		if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] skipped ; waiting 0.02s before next roll.")
		_bat_squeak_timer.start(0.02)

func _on_bat_squeak_sound_finished() -> void:
	if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] sound finished ; rolling again.")
	_roll_bat_squeak()

func _on_bat_squeak_timer() -> void:
	if debug_me: print_rich("[color=#FF69B4][BatSqueak][/color] retry timer fired ; rolling again.")
	_roll_bat_squeak()
#endregion dash loop

##Plays a random attack swing sound.
func play_attack_sound():
	if attack_sounds == null:
		return
	var clip = attack_sounds.sl.pick_random()
	if local_audio != null:
		_play_local_sound(clip, default_bus)
	else:
		play_sound(clip, default_bus)
#endregion health and damage audio

#endregion FUNCTIONS
