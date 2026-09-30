@tool
##Plays one AmbienceLayerResource on the Ambience bus, handling its start delay and loop mode. Works the same in the editor and at runtime.
class_name AmbienceLayerPlayer
extends Node

var _layer: AmbienceLayerResource = null
var _player: AudioStreamPlayer
var _timer: Timer
var _play_count := 0
var _last_index := -1
var _warned := false

func _init() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Ambience"
	add_child(_player)
	_player.finished.connect(_on_finished)

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)

##Stops any current playback and starts the given layer using its start mode.
func start(layer: AmbienceLayerResource) -> void:
	stop()
	_layer = layer
	if _layer == null or not _layer.is_valid():
		return
	_player.volume_db = _layer.get_volume_db()
	_play_count = 0
	_last_index = -1
	_warned = false
	if _layer.start_mode == AmbienceLayerResource.StartMode.ON_LOAD:
		_play_once()
		return
	var delay := _layer.pick_start_delay()
	if delay <= 0.0:
		_play_once()
	else:
		_timer.start(delay)

##Stops playback and any pending timer, and clears the layer.
func stop() -> void:
	_timer.stop()
	_player.stop()
	_layer = null

func _play_once() -> void:
	var sounds: Array[AudioStream] = _layer.library.sounds
	var index := randi_range(0, sounds.size() - 1)
	if sounds.size() > 1 and index == _last_index:
		index = (index + randi_range(1, sounds.size() - 1)) % sounds.size()
	_last_index = index
	var stream: AudioStream = sounds[index]
	if not _warned and _is_natively_looping(stream):
		_warned = true
		push_warning("AmbienceLayerPlayer: stream %s has native looping enabled, finished will never fire" % stream.resource_path)
	_player.stream = stream
	_player.play()
	_play_count += 1

func _is_natively_looping(stream: AudioStream) -> bool:
	if stream is AudioStreamWAV:
		return (stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED
	if stream is AudioStreamOggVorbis:
		return (stream as AudioStreamOggVorbis).loop
	if stream is AudioStreamMP3:
		return (stream as AudioStreamMP3).loop
	return false

func _on_finished() -> void:
	if _layer == null:
		return
	match _layer.loop_mode:
		AmbienceLayerResource.LoopMode.CONTINUOUS:
			_play_once()
		AmbienceLayerResource.LoopMode.COUNT:
			if _play_count < _layer.loop_count:
				_play_once()
		AmbienceLayerResource.LoopMode.INTERVAL:
			var t := _layer.pick_loop_interval()
			if t <= 0.0:
				_play_once()
			else:
				_timer.start(t)

func _on_timeout() -> void:
	if _layer != null:
		_play_once()
