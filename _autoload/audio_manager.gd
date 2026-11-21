extends Node

## The master output bus name.
const MASTER: StringName = &"Master"
## The music output bus name.
const MUSIC: StringName = &"Music"
## The sound effects output bus name.
const SFX: StringName = &"SFX"

const _SFX_POOL_SIZE: int = 8
const _MIN_VOLUME_DB: float = -80.0
const _DEFAULT_BUS_VOLUME: float = 1.0
const SFX_PITCH_VARIATION: float = 0.05
const _DEFAULT_MUSIC_FADE_TIME: float = 0.8
const _SETTINGS_SECTION: String = "audio"
const _VOLUME_KEYS: Dictionary = {
	MASTER: "master_volume",
	MUSIC: "music_volume",
	SFX: "sfx_volume",
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_use_order: Array[int] = []
var _use_counter: int = 0
var _music_players: Array[AudioStreamPlayer] = []
var _music_tween: Tween
var _music_request_id: int = 0
var _requested_music: AudioStream
var _active_music_index: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name: StringName in [MASTER, MUSIC, SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			push_error("AudioManager: audio bus '%s' does not exist." % bus_name)
		else:
			_restore_bus_volume(bus_name)

	for index: int in 2:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % index
		player.bus = MUSIC
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_music_players.append(player)

	for index: int in _SFX_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = SFX
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)
		_sfx_use_order.append(0)


## Plays a one-shot sound effect on the SFX bus.
func play_sfx(sound: SoundEffect) -> void:
	if (
		sound == null
		or sound.stream == null
		or AudioServer.get_bus_index(SFX) == -1
	):
		return

	var player_index: int = _find_idle_sfx_player()
	if player_index == -1:
		player_index = _find_oldest_sfx_player()

	var player: AudioStreamPlayer = _sfx_players[player_index]
	player.stop()
	player.stream = sound.stream
	player.volume_db = sound.volume_db
	player.pitch_scale = randf_range(
		1.0 - SFX_PITCH_VARIATION,
		1.0 + SFX_PITCH_VARIATION
	) if sound.pitch_variation else 1.0

	_use_counter += 1
	_sfx_use_order[player_index] = _use_counter
	player.play()


## Fades to a new music track on the Music bus.
func play_music(stream: AudioStream, fade_time: float = _DEFAULT_MUSIC_FADE_TIME) -> void:
	if stream == null or AudioServer.get_bus_index(MUSIC) == -1:
		return

	var safe_fade_time: float = maxf(fade_time, 0.0)

	if (
		stream == _requested_music
		and _active_music_index >= 0
		and _music_players[_active_music_index].playing
		and _music_players[_active_music_index].stream == stream
	):
		return

	_requested_music = stream
	_music_request_id += 1
	var request_id: int = _music_request_id
	_kill_music_tween()

	var target_index: int = -1
	for index: int in _music_players.size():
		if _music_players[index].playing and _music_players[index].stream == stream:
			target_index = index
			break
	if target_index == -1:
		target_index = 1 - _active_music_index if _active_music_index >= 0 else 0

	var target_player: AudioStreamPlayer = _music_players[target_index]
	if not target_player.playing or target_player.stream != stream:
		target_player.stop()
		target_player.stream = stream
		target_player.play()

	var outgoing_index: int = -1
	if _active_music_index >= 0 and _active_music_index != target_index:
		if _music_players[_active_music_index].playing:
			outgoing_index = _active_music_index
	target_player.volume_db = _MIN_VOLUME_DB

	if outgoing_index >= 0:
		_music_players[outgoing_index].volume_db = 0.0

	_active_music_index = target_index

	if safe_fade_time == 0.0:
		for index: int in _music_players.size():
			if index != target_index:
				_music_players[index].stop()
				_music_players[index].volume_db = 0.0
		target_player.volume_db = 0.0
		return

	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.set_trans(Tween.TRANS_LINEAR)
	_music_tween.tween_method(
		_update_music_crossfade.bind(target_index, outgoing_index),
		0.0,
		1.0,
		safe_fade_time
	)
	_music_tween.tween_callback(_finish_music_transition.bind(request_id, target_index))


## Stops the current music track, fading it out when requested.
func stop_music(fade_time: float = _DEFAULT_MUSIC_FADE_TIME) -> void:
	if AudioServer.get_bus_index(MUSIC) == -1:
		return

	_requested_music = null
	_music_request_id += 1
	var request_id: int = _music_request_id
	var safe_fade_time: float = maxf(fade_time, 0.0)

	_kill_music_tween()

	var has_playing_music: bool = false
	for player: AudioStreamPlayer in _music_players:
		if player.playing:
			has_playing_music = true

	if not has_playing_music:
		_active_music_index = -1
		return

	if safe_fade_time == 0.0:
		_finish_music_stop(request_id)
		return

	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.set_parallel(true)

	for player: AudioStreamPlayer in _music_players:
		if player.playing:
			_music_tween.tween_property(player, "volume_db", _MIN_VOLUME_DB, safe_fade_time)
	_music_tween.set_parallel(false)
	_music_tween.tween_callback(_finish_music_stop.bind(request_id))


## Sets a bus volume from a clamped linear value between zero and one.
func set_bus_volume(bus: StringName, linear: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus)

	if bus_index == -1:
		return

	var clamped_linear: float = clampf(linear, 0.0, 1.0)

	var volume_db: float = maxf(
		linear_to_db(clamped_linear), _MIN_VOLUME_DB
	) if clamped_linear > 0.0 else _MIN_VOLUME_DB

	AudioServer.set_bus_volume_db(
		bus_index,
		volume_db
	)
	_persist_bus_volume(bus, clamped_linear)


## Returns a bus volume as a linear value between zero and one.
func get_bus_volume(bus: StringName) -> float:
	var bus_index: int = AudioServer.get_bus_index(bus)

	if bus_index == -1:
		return 0.0

	var volume_db: float = AudioServer.get_bus_volume_db(bus_index)

	return 0.0 if volume_db <= _MIN_VOLUME_DB else db_to_linear(volume_db)


func _restore_bus_volume(bus: StringName) -> void:
	if not _VOLUME_KEYS.has(bus):
		return

	var store: Node = get_node_or_null("/root/StoreManager")
	if store == null:
		return

	var key: String = _VOLUME_KEYS[bus]
	var stored_volume: Variant = store.call(
		"get_value", _SETTINGS_SECTION, key, _DEFAULT_BUS_VOLUME
	)
	if stored_volume is float or stored_volume is int:
		set_bus_volume(bus, float(stored_volume))


func _persist_bus_volume(bus: StringName, linear: float) -> void:
	if not _VOLUME_KEYS.has(bus):
		return

	var store: Node = get_node_or_null("/root/StoreManager")
	if store == null:
		return

	var key: String = _VOLUME_KEYS[bus]
	var error: Error = store.call(
		"set_value", _SETTINGS_SECTION, key, linear
	)
	if error != OK:
		push_error("AudioManager: could not persist volume for bus '%s'." % bus)


func _find_idle_sfx_player() -> int:
	for index: int in _sfx_players.size():
		if not _sfx_players[index].playing:
			return index

	return -1


func _find_oldest_sfx_player() -> int:
	var oldest_index: int = 0

	for index: int in _sfx_use_order.size():
		if _sfx_use_order[index] < _sfx_use_order[oldest_index]:
			oldest_index = index

	return oldest_index


func _finish_music_transition(request_id: int, active_index: int) -> void:
	if request_id != _music_request_id:
		return

	for index: int in _music_players.size():
		if index != active_index:
			_music_players[index].stop()
			_music_players[index].volume_db = 0.0
	_active_music_index = active_index
	_music_tween = null


func _update_music_crossfade(progress: float, incoming_index: int, outgoing_index: int) -> void:
	var angle: float = clampf(progress, 0.0, 1.0) * PI * 0.5
	var incoming_amplitude: float = sin(angle)
	var incoming_volume_db: float = (
		linear_to_db(incoming_amplitude)
		if incoming_amplitude > 0.0
		else _MIN_VOLUME_DB
	)

	_music_players[incoming_index].volume_db = maxf(incoming_volume_db, _MIN_VOLUME_DB)

	if outgoing_index >= 0:
		var outgoing_amplitude: float = cos(angle)
		var outgoing_volume_db: float = (
			linear_to_db(outgoing_amplitude)
			if outgoing_amplitude > 0.0
			else _MIN_VOLUME_DB
		)
		_music_players[outgoing_index].volume_db = maxf(outgoing_volume_db, _MIN_VOLUME_DB)


func _finish_music_stop(request_id: int) -> void:
	if request_id != _music_request_id:
		return

	for player: AudioStreamPlayer in _music_players:
		player.stop()
		player.volume_db = 0.0
	_active_music_index = -1
	_music_tween = null


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()

	_music_tween = null
