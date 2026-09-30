class_name MusicManager
extends Node

@export_group("Item Get Tones")
@export var first_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/first-item_get.wav")
@export var small_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/chest-open_small.wav")
@export var big_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/chest-open_large.wav")
@export var key_item_get_tone: AudioStream = preload("res://Sound/MUSIC/Tones/key-item_get.wav")

@export_group("Transitions")
## Seconds to fade the current song out before a hard switch or stop. 0 cuts instantly.
@export_range(0.0, 10.0, 0.05) var fade_out_seconds: float = 1.0
## Seconds to fade a newly started song in. 0 starts at full volume.
@export_range(0.0, 10.0, 0.05) var fade_in_seconds: float = 1.0
## Seconds to ramp the pause duck in or out.
@export_range(0.0, 5.0, 0.05) var duck_seconds: float = 0.4
## Linear volume multiplier applied to music while the pause duck is active.
@export_range(0.0, 1.0, 0.01) var duck_level: float = 0.5

var _current_song: SongResource = null
var _pending_song: SongResource = null
var _pending_volume_db := 0.0
var _exiting := false
var _stop_after_loop := false
var _base_db := 0.0
var _fade_linear := 1.0
var _duck_linear := 1.0
var _fade_tween: Tween
var _duck_tween: Tween
var _fading_out := false

var _shot_player: AudioStreamPlayer
var _loop_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_shot_player = AudioStreamPlayer.new()
	_shot_player.bus = "Songs"
	add_child(_shot_player)
	_shot_player.finished.connect(_on_shot_finished)

	_loop_player = AudioStreamPlayer.new()
	_loop_player.bus = "Songs"
	add_child(_loop_player)
	_loop_player.finished.connect(_on_loop_finished)

	_setup_tone_ducker()

## Plays song at linear volume. Null stops the music. Graceful waits for the loop end and exit segment; otherwise the current song fades out first.
func request_song(song: SongResource, volume: float = 1.0, graceful: bool = false) -> void:
	if song == null:
		stop_song(graceful)
		return
	var db := linear_to_db(volume) if volume > 0.0 else -80.0
	if song == _current_song:
		_base_db = db
		_apply_volume()
		if _exiting:
			_pending_song = song
			_pending_volume_db = db
		else:
			_pending_song = null
			_stop_after_loop = false
			if _fading_out:
				_cancel_fade_out()
		return
	if not song.is_valid():
		push_error("MusicManager: SongResource is not valid (missing required loop stream)")
		return
	_pending_song = song
	_pending_volume_db = db
	_stop_after_loop = false
	if not _is_any_playing():
		_transition_to_pending()
	elif graceful:
		return
	else:
		_fade_out_then(_transition_to_pending)

## Stops the current song. Graceful lets the loop finish and plays the exit segment; otherwise it fades out.
func stop_song(graceful: bool = false) -> void:
	if _current_song == null and not _is_any_playing():
		return
	_pending_song = null
	if graceful:
		_stop_after_loop = true
		return
	_fade_out_then(_clear_current)

## Returns true when song is the song currently playing.
func is_playing_song(song: SongResource) -> bool:
	return song != null and song == _current_song

## Ducks music to duck_level while active, restores full volume when inactive. Runs while the tree is paused.
func set_pause_duck(active: bool) -> void:
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	var target := duck_level if active else 1.0
	if duck_seconds <= 0.0:
		_duck_linear = target
		_apply_volume()
		return
	_duck_tween = create_tween()
	_duck_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_duck_tween.tween_method(_set_duck_linear, _duck_linear, target, duck_seconds)

## Plays an item get tone on the Tones bus, which ducks the Songs bus.
func play_item_tone(tone: AudioStream) -> void:
	if not tone or not audioManager:
		return
	audioManager.play(tone, "Tones")

func _is_any_playing() -> bool:
	return _shot_player.playing or _loop_player.playing

func _set_duck_linear(v: float) -> void:
	_duck_linear = v
	_apply_volume()

func _set_fade_linear(v: float) -> void:
	_fade_linear = v
	_apply_volume()

func _apply_volume() -> void:
	var lin := _fade_linear * _duck_linear
	var db := _base_db + (linear_to_db(lin) if lin > 0.0 else -80.0)
	_shot_player.volume_db = db
	_loop_player.volume_db = db

func _fade_out_then(on_done: Callable) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if fade_out_seconds <= 0.0 or not _is_any_playing():
		on_done.call()
		return
	_fading_out = true
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_method(_set_fade_linear, _fade_linear, 0.0, fade_out_seconds * _fade_linear)
	_fade_tween.finished.connect(on_done, CONNECT_ONE_SHOT)

func _cancel_fade_out() -> void:
	_fading_out = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if fade_in_seconds <= 0.0:
		_fade_linear = 1.0
		_apply_volume()
		return
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_method(_set_fade_linear, _fade_linear, 1.0, fade_in_seconds * (1.0 - _fade_linear))

func _transition_to_pending() -> void:
	if _pending_song == null:
		_clear_current()
		return
	_current_song = _pending_song
	_pending_song = null
	_exiting = false
	_stop_after_loop = false
	_fading_out = false
	_loop_player.stop()
	_shot_player.stop()
	_base_db = _pending_volume_db
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	if _current_song.opener != null:
		_shot_player.stream = _current_song.opener
		_shot_player.play()
	else:
		_start_loop()
	if fade_in_seconds > 0.0:
		_fade_linear = 0.0
		_apply_volume()
		_fade_tween = create_tween()
		_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_fade_tween.tween_method(_set_fade_linear, 0.0, 1.0, fade_in_seconds)
	else:
		_fade_linear = 1.0
		_apply_volume()

func _clear_current() -> void:
	_loop_player.stop()
	_shot_player.stop()
	_current_song = null
	_exiting = false
	_stop_after_loop = false
	_fading_out = false
	_fade_linear = 1.0
	_apply_volume()
	if _pending_song != null:
		_transition_to_pending()

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
	if _pending_song != null or _stop_after_loop:
		if _current_song != null and _current_song.exit != null:
			_exiting = true
			_shot_player.stream = _current_song.exit
			_shot_player.play()
		else:
			_transition_to_pending()
	else:
		_loop_player.play()

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
