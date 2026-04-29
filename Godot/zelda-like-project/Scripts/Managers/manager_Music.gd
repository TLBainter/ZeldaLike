class_name MusicManager
extends Node

@export_group("Item Get Tones")
@export var first_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/first-item_get.wav")
@export var small_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/chest-open_small.wav")
@export var big_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/chest-open_large.wav")
@export var key_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/key-item_get.wav")

var _current_song: SongResource = null
var _pending_song: SongResource = null
var _exiting := false

var _shot_player: AudioStreamPlayer  # Opener and Exit playback
var _loop_player: AudioStreamPlayer  # Loop playback (manually re-triggered to intercept end)

func _ready() -> void:
	_shot_player = AudioStreamPlayer.new()
	_shot_player.bus = "Songs"
	add_child(_shot_player)
	_shot_player.finished.connect(_on_shot_finished)

	_loop_player = AudioStreamPlayer.new()
	_loop_player.bus = "Songs"
	add_child(_loop_player)
	_loop_player.finished.connect(_on_loop_finished)

	_setup_tone_ducker()

func request_song(song: SongResource) -> void:
	if song == null or song == _current_song:
		return
	_pending_song = song
	if not _shot_player.playing and not _loop_player.playing:
		_transition_to_pending()

func _transition_to_pending() -> void:
	_current_song = _pending_song
	_pending_song = null
	_loop_player.stop()
	_shot_player.stop()
	if _current_song.opener != null:
		_shot_player.stream = _current_song.opener
		_shot_player.play()
	else:
		_start_loop()

func _start_loop() -> void:
	if _current_song == null or _current_song.loop == null:
		return
	_loop_player.stream = _current_song.loop
	_loop_player.play()

func _on_shot_finished() -> void:
	if _exiting:
		_exiting = false
		_transition_to_pending()
	else:
		_start_loop()

func _on_loop_finished() -> void:
	if _pending_song != null:
		if _current_song != null and _current_song.exit != null:
			_exiting = true
			_shot_player.stream = _current_song.exit
			_shot_player.play()
		else:
			_transition_to_pending()
	else:
		_loop_player.play()

func play_item_tone(tone: AudioStream) -> void:
	if not tone or not audioManager:
		return
	audioManager.play(tone, "Tones")

func _setup_tone_ducker() -> void:
	var idx := AudioServer.get_bus_index("Songs")
	if idx < 0 or AudioServer.get_bus_effect_count(idx) > 0:
		return
	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -50.0
	compressor.ratio = 8.0
	compressor.attack_us = 150000.0
	compressor.release_ms = 1200.0
	compressor.sidechain = "Tones"
	AudioServer.add_bus_effect(idx, compressor)
