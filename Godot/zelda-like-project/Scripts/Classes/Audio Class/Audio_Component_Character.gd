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

#endregion sound libraries
#endregion VARIABLES

#region FUNCTIONS
func _ready():
	if health:
		health.healthChanged.connect(_on_health_changed)

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
