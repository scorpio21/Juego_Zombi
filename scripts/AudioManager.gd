extends Node
## Gestor centralizado de audio para las cartas de mejora.
##
## El banco se genera proceduralmente para que el proyecto funcione sin assets de
## sonido. Si se añaden .ogg/.wav, basta con sustituir _make_tone por streams
## precargados manteniendo la misma API pública.

@export var upgrades_volume_db: float = -4.0
@export var upgrades_enabled: bool = true
@export var generator_mix_rate: int = 44100
@export var max_simultaneous_sounds: int = 8
@export var use_procedural_fallback: bool = true

const UPGRADE_BUS := "Upgrades"
const SOUND_DURATION := 0.42
var _players: Array[AudioStreamPlayer] = []
var _player_cursor := 0
var _music_players: Array[AudioStreamPlayer] = []
var _audio_cache: Dictionary = {}
var _audio_warnings: Dictionary = {}

func _ready() -> void:
	_ensure_upgrade_bus()
	_build_player_pool()

func _ensure_upgrade_bus() -> void:
	var bus_index := AudioServer.get_bus_index(UPGRADE_BUS)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, UPGRADE_BUS)
	AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.set_bus_volume_db(bus_index, upgrades_volume_db)

func _build_player_pool() -> void:
	for old_player in _players:
		if is_instance_valid(old_player):
			old_player.queue_free()
	_players.clear()
	for i in range(maxi(1, max_simultaneous_sounds)):
		var player := AudioStreamPlayer.new()
		player.name = "UpgradeVoice_%02d" % i
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = generator_mix_rate
		generator.buffer_length = 0.8
		player.stream = generator
		player.bus = UPGRADE_BUS
		player.volume_db = 0.0
		add_child(player)
		_players.append(player)

func register_music_player(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player) and not _music_players.has(player):
		_music_players.append(player)

func pause_music_briefly(duration: float = 0.55) -> void:
	for music in _music_players:
		if is_instance_valid(music) and music.playing:
			music.stream_paused = true
		_resume_music_after(duration)

func _resume_music_after(duration: float) -> void:
		await get_tree().create_timer(duration).timeout
		for music in _music_players:
			if is_instance_valid(music):
				music.stream_paused = false

func play_upgrade_event(upgrade_id: String, event_name: String, rarity: String = "COMÚN") -> void:
	if not upgrades_enabled or _players.is_empty():
		return
	var specific_paths := [
		"res://audio/upgrades/%s_%s.wav" % [upgrade_id, event_name],
		"res://audio/upgrades/%s_%s.ogg" % [upgrade_id, event_name],
		"res://assets/audio/upgrades/%s_%s.ogg" % [upgrade_id, event_name]
	]
	var fallback_paths := [
		"res://audio/cards/default_upgrade_%s.wav" % event_name,
		"res://audio/cards/default_upgrade_%s.ogg" % event_name,
		"res://assets/audio/ui/default_upgrade_%s.ogg" % event_name
	]
	var stream := _load_safe_streams(specific_paths, fallback_paths)
	if stream != null:
		_play_stream(stream)
		return
	# El banco procedural mantiene la partida funcionando aunque falten todos los assets.
	if use_procedural_fallback:
		_play_preset(_get_preset(upgrade_id, event_name, rarity))
	return

# API pública usada directamente por el flujo existente de cartas.
func play_card_spawn() -> void:
	_play_card_ui_sound("spawn")

func play_card_hover(upgrade_id: String, rarity: String = "COMÚN") -> void:
	play_upgrade_event(upgrade_id, "hover", rarity)

func play_card_select(upgrade_id: String, rarity: String = "COMÚN") -> void:
	play_upgrade_event(upgrade_id, "select", rarity)

func play_card_rarity(rarity: String, event_name: String = "select") -> void:
	play_rarity_sound(rarity, event_name)

func play_rarity_sound(rarity: String, event_name: String = "select") -> void:
	if not upgrades_enabled or _players.is_empty():
		return
	var rarity_key := rarity.to_lower().replace("ú", "u").replace("é", "e")
	if rarity_key == "comun":
		rarity_key = "common"
	var specific_paths := [
		"res://audio/rarity/%s_%s.wav" % [rarity_key, event_name],
		"res://audio/rarity/%s_%s.ogg" % [rarity_key, event_name],
		"res://assets/audio/rarity/%s_%s.ogg" % [rarity_key, event_name]
	]
	var common_paths := [
		"res://audio/rarity/common_%s.wav" % event_name,
		"res://audio/rarity/common_%s.ogg" % event_name,
		"res://assets/audio/rarity/common_%s.ogg" % event_name
	]
	var stream := _load_safe_streams(specific_paths, common_paths)
	if stream != null:
		_play_stream(stream)
		return
	if use_procedural_fallback:
		_play_preset(_rarity_preset(event_name, rarity))

func play_upgrade_sound(upgrade_id: String, rarity: String = "COMÚN", event_name: String = "apply") -> void:
	play_upgrade_event(upgrade_id, event_name, rarity)

func _play_card_ui_sound(event_name: String) -> void:
	var stream := _load_safe_streams([
		"res://audio/cards/card_%s.wav" % event_name,
		"res://audio/cards/card_%s.ogg" % event_name
	], [
		"res://audio/cards/default_upgrade_%s.wav" % event_name,
		"res://audio/cards/default_upgrade_%s.ogg" % event_name
	])
	if stream != null:
		_play_stream(stream)
	elif use_procedural_fallback:
		_play_preset(_rarity_preset(event_name, "COMÚN"))

func _load_safe_streams(specific_paths: Array, fallback_paths: Array) -> AudioStream:
	for path in specific_paths:
		var stream := _load_cached_stream(str(path))
		if stream != null:
			print("[Audio] Sonido cargado correctamente: ", path)
			return stream
	for path in fallback_paths:
		var fallback := _load_cached_stream(str(path))
		if fallback != null:
			print("[Audio] Fallback utilizado: ", path)
			return fallback
	for path in specific_paths:
		_warn_missing(str(path))
	for path in fallback_paths:
		_warn_missing(str(path))
	return null

func _load_safe_stream(sound_path: String, fallback_path: String) -> AudioStream:
	var stream := _load_cached_stream(sound_path)
	if stream != null:
		print("[Audio] Sonido cargado correctamente: ", sound_path)
		return stream
	var fallback := _load_cached_stream(fallback_path)
	if fallback != null:
		print("[Audio] Fallback utilizado: ", fallback_path, " para ", sound_path)
		return fallback
	_warn_missing(sound_path)
	_warn_missing(fallback_path)
	return null

func _load_cached_stream(path: String) -> AudioStream:
	if _audio_cache.has(path):
		return _audio_cache[path] as AudioStream
	if not ResourceLoader.exists(path):
		return null
	var resource := ResourceLoader.load(path)
	if resource is AudioStream:
		_audio_cache[path] = resource
		return resource as AudioStream
	_warn_missing(path + " (recurso no compatible)")
	return null

func _warn_missing(path: String) -> void:
	if _audio_warnings.has(path):
		return
	_audio_warnings[path] = true
	push_warning("[Audio] Sonido no encontrado: " + path)

func _play_stream(stream: AudioStream) -> void:
	if stream == null or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_player_cursor % _players.size()]
	_player_cursor += 1
	player.stream = stream
	player.stop()
	player.play()

func play_rarity(rarity: String, event_name: String = "appear") -> void:
	play_rarity_sound(rarity, event_name)

func _play_preset(preset: Dictionary) -> void:
	var player: AudioStreamPlayer = _players[_player_cursor % _players.size()]
	_player_cursor += 1
	var generator := player.stream as AudioStreamGenerator
	if generator == null:
		generator = AudioStreamGenerator.new()
		generator.mix_rate = generator_mix_rate
		generator.buffer_length = 0.8
		player.stream = generator
	player.stop()
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var duration := float(preset.get("duration", SOUND_DURATION))
	var frame_count := mini(int(generator_mix_rate * duration), int(generator_mix_rate * 0.72))
	var frequencies: Array = preset.get("frequencies", [440.0])
	var amplitudes: Array = preset.get("amplitudes", [0.22])
	var noise_amount := float(preset.get("noise", 0.0))
	var sweep := float(preset.get("sweep", 0.0))
	var waveform := str(preset.get("waveform", "sine"))
	for frame in range(frame_count):
		var t := float(frame) / float(generator_mix_rate)
		var normalized := t / maxf(duration, 0.001)
		var attack := clampf(t / 0.025, 0.0, 1.0)
		var release := clampf((duration - t) / 0.10, 0.0, 1.0)
		var envelope := attack * release
		var sample := 0.0
		for i in range(frequencies.size()):
			var frequency := float(frequencies[i]) + sweep * normalized
			var phase := TAU * frequency * t
			var wave := sin(phase)
			if waveform == "square":
				wave = 1.0 if sin(phase) >= 0.0 else -1.0
			elif waveform == "saw":
				wave = 2.0 * (frequency * t - floor(0.5 + frequency * t))
			sample += wave * float(amplitudes[min(i, amplitudes.size() - 1)])
		if noise_amount > 0.0:
			sample += randf_range(-noise_amount, noise_amount)
		sample = clampf(sample * envelope, -0.95, 0.95)
		playback.push_frame(Vector2(sample, sample))

func _get_preset(upgrade_id: String, event_name: String, rarity: String) -> Dictionary:
	if upgrade_id == "rarity":
		return _rarity_preset(event_name, rarity)
	var base := _upgrade_preset(upgrade_id, event_name)
	var rarity_layer := _rarity_preset("select" if event_name == "select" else event_name, rarity)
	if event_name == "select" or event_name == "apply":
		base["frequencies"] = base["frequencies"] + rarity_layer["frequencies"]
		base["amplitudes"] = base["amplitudes"] + rarity_layer["amplitudes"]
		base["duration"] = maxf(float(base["duration"]), float(rarity_layer["duration"]))
	return base

func _upgrade_preset(upgrade_id: String, event_name: String) -> Dictionary:
	var presets := {
		"fury": {"hover": {"frequencies": [72.0, 108.0], "amplitudes": [0.16, 0.08], "duration": 0.26, "waveform": "sine"}, "select": {"frequencies": [92.0, 185.0, 370.0], "amplitudes": [0.18, 0.12, 0.06], "duration": 0.50, "noise": 0.025, "sweep": 240.0}, "apply": {"frequencies": [110.0, 220.0], "amplitudes": [0.20, 0.08], "duration": 0.34, "waveform": "square"}},
		"speed": {"hover": {"frequencies": [520.0, 780.0], "amplitudes": [0.10, 0.05], "duration": 0.22, "noise": 0.01, "sweep": 260.0}, "select": {"frequencies": [260.0, 520.0, 1040.0], "amplitudes": [0.12, 0.10, 0.05], "duration": 0.40, "sweep": 700.0}, "apply": {"frequencies": [330.0, 660.0], "amplitudes": [0.14, 0.08], "duration": 0.30, "sweep": 400.0}},
		"medkit": {"hover": {"frequencies": [880.0, 1320.0], "amplitudes": [0.10, 0.06], "duration": 0.24, "waveform": "sine"}, "select": {"frequencies": [523.0, 659.0, 784.0], "amplitudes": [0.12, 0.10, 0.08], "duration": 0.54}, "apply": {"frequencies": [392.0, 523.0, 784.0], "amplitudes": [0.10, 0.10, 0.08], "duration": 0.62}},
		"heavy": {"hover": {"frequencies": [180.0, 360.0], "amplitudes": [0.13, 0.08], "duration": 0.20, "noise": 0.04, "waveform": "square"}, "select": {"frequencies": [90.0, 180.0, 270.0], "amplitudes": [0.20, 0.13, 0.08], "duration": 0.46, "noise": 0.05, "waveform": "square"}, "apply": {"frequencies": [120.0, 240.0], "amplitudes": [0.20, 0.10], "duration": 0.38, "noise": 0.04}},
		"survivor": {"hover": {"frequencies": [300.0, 450.0], "amplitudes": [0.10, 0.08], "duration": 0.30, "sweep": 180.0}, "select": {"frequencies": [220.0, 440.0, 880.0], "amplitudes": [0.14, 0.10, 0.06], "duration": 0.58, "sweep": 300.0}, "apply": {"frequencies": [261.0, 392.0, 523.0], "amplitudes": [0.12, 0.10, 0.08], "duration": 0.52}}
	}
	return (presets.get(upgrade_id, presets["survivor"]) as Dictionary).get(event_name, {"frequencies": [440.0], "amplitudes": [0.12], "duration": SOUND_DURATION})

func _rarity_preset(event_name: String, rarity: String) -> Dictionary:
	match rarity:
		"RARA":
			return {"frequencies": [740.0, 1110.0], "amplitudes": [0.07, 0.04], "duration": 0.32, "sweep": 180.0}
		"ÉPICA":
			return {"frequencies": [130.0, 260.0, 520.0], "amplitudes": [0.09, 0.06, 0.04], "duration": 0.48, "noise": 0.02, "sweep": 280.0}
		"LEGENDARIA":
			return {"frequencies": [55.0, 110.0, 220.0, 440.0], "amplitudes": [0.14, 0.10, 0.07, 0.04], "duration": 0.72, "noise": 0.035, "sweep": 420.0, "waveform": "saw"}
	return {"frequencies": [440.0], "amplitudes": [0.10], "duration": 0.18}
