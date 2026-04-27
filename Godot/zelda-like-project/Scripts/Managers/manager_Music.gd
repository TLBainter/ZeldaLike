class_name MusicManager
extends Node

var _current_song: SongResource = null
var _pending_song: SongResource = null
var _exiting := false

var _shot_player: AudioStreamPlayer  # Opener and Exit playback
var _loop_player: AudioStreamPlayer  # Loop playback (manually re-triggered to intercept end)

func _ready() -> void:
	_shot_player = AudioStreamPlayer.new()
	_shot_player.bus = "Music"
	add_child(_shot_player)
	_shot_player.finished.connect(_on_shot_finished)

	_loop_player = AudioStreamPlayer.new()
	_loop_player.bus = "Music"
	add_child(_loop_player)
	_loop_player.finished.connect(_on_loop_finished)

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
