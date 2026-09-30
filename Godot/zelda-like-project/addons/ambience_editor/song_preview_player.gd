## Editor preview player for a [b]SongResource[/b]. Plays the opener once, then repeats the loop until stopped. The exit stream is never used.
@tool
class_name AmbienceSongPreviewPlayer
extends Node

var _player: AudioStreamPlayer
var _song: SongResource

func _init() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Songs"
	add_child(_player)
	_player.finished.connect(_on_finished)

## Stops any current song, then plays [param song] at [param volume_db], starting with its opener when one is set.
func play_song(song: SongResource, volume_db: float) -> void:
	stop()
	if song == null:
		return
	_song = song
	_player.volume_db = volume_db
	if song.opener != null:
		_player.stream = song.opener
		_player.play()
		return
	_play_loop()

## Stops playback and clears the current song.
func stop() -> void:
	_player.stop()
	_song = null

func _play_loop() -> void:
	if _song == null or _song.loop == null:
		return
	_player.stream = _song.loop
	_player.play()

func _on_finished() -> void:
	if _song == null:
		return
	_play_loop()
