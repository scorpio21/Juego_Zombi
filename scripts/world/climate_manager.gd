class_name ClimateManager
extends Node

signal climate_changed(climate_name: String)
signal climate_audio_changed(climate_name: String)

@export_category("Configuración seleccionada")
@export var settings: ClimateSettings ## Preset activo. Se puede cambiar desde el Inspector.

@export_category("Audio meteorológico")
@export var weather_audio_enabled: bool = true ## Activa el bus y la ambientación meteorológica.
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var weather_audio_volume_db: float = -16.0 ## Volumen del WeatherBus.
@export_range(0.1, 10.0, 0.1, "suffix:s") var weather_audio_fade_seconds: float = 2.0 ## Duración del crossfade.
@export var use_procedural_audio_fallback: bool = true ## Mantiene audio aunque falte un OGG.

const WEATHER_BUS := "WeatherBus"
const AUDIO_MIX_RATE := 22050.0
const AUDIO_BUFFER_SECONDS := 0.5
const WEATHER_AUDIO_PATHS := {
	"lluvia": "res://audio/weather/rain_loop.ogg",
	"tormenta": "res://audio/weather/storm_loop.ogg",
	"niebla": "res://audio/weather/fog_ambience.ogg",
	"viento": "res://audio/weather/wind_loop.ogg",
	"noche": "res://audio/weather/night_ambience.ogg"
}

var _weather_audio_players: Array[AudioStreamPlayer] = []
var _weather_audio_playbacks: Array[AudioStreamGeneratorPlayback] = []
var _weather_audio_states: Array[String] = ["", ""]
var _weather_audio_index := 0
var _weather_audio_time := 0.0
var _weather_audio_tween: Tween
var _current_audio_weather := ""
var _thunder_player: AudioStreamPlayer
var _thunder_playback: AudioStreamGeneratorPlayback
var _thunder_time := 99.0

func _ready() -> void:
	if settings == null:
		settings = ClimateSettings.new()
	_setup_weather_bus()
	_setup_weather_players()

func _process(delta: float) -> void:
	if not weather_audio_enabled:
		return
	_weather_audio_time += delta
	for i in range(_weather_audio_players.size()):
		_fill_procedural_buffer(i)
	_fill_thunder_buffer()

func get_settings() -> ClimateSettings:
	return settings

func is_enabled() -> bool:
	return settings != null and settings.climate_enabled

func notify_climate_changed(climate_name: String) -> void:
	climate_changed.emit(climate_name)

func set_weather_audio(climate_name: String, fade_seconds: float = -1.0) -> void:
	if not weather_audio_enabled or _weather_audio_players.is_empty():
		return
	var normalized := climate_name.to_lower()
	var audio_aliases := {"luna_roja": "noche", "ceniza_toxica": "niebla", "ola_calor": "viento"}
	normalized = str(audio_aliases.get(normalized, normalized))
	if normalized in ["soleado", "nublado", "amanecer", "mañana", "tarde", "atardecer"]:
		normalized = ""
	if normalized == _current_audio_weather:
		return
	var fade := weather_audio_fade_seconds if fade_seconds < 0.0 else maxf(0.05, fade_seconds)
	var next_index := 1 - _weather_audio_index
	var next_player := _weather_audio_players[next_index]
	var next_stream := _load_weather_stream(normalized)
	_weather_audio_states[next_index] = normalized
	next_player.stream = next_stream
	next_player.volume_db = -80.0
	if next_stream != null:
		next_player.play()
	if _weather_audio_tween != null and _weather_audio_tween.is_valid():
		_weather_audio_tween.kill()
	_weather_audio_tween = create_tween().set_parallel(true)
	_weather_audio_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weather_audio_tween.tween_property(_weather_audio_players[_weather_audio_index], "volume_db", -80.0, fade)
	_weather_audio_tween.tween_property(next_player, "volume_db", weather_audio_volume_db, fade)
	_weather_audio_index = next_index
	_current_audio_weather = normalized
	climate_audio_changed.emit(climate_name)

func stop_weather_audio(fade_seconds: float = 0.5) -> void:
	if _weather_audio_players.is_empty():
		return
	if _weather_audio_tween != null and _weather_audio_tween.is_valid():
		_weather_audio_tween.kill()
	_weather_audio_tween = create_tween().set_parallel(true)
	_weather_audio_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for player in _weather_audio_players:
		_weather_audio_tween.tween_property(player, "volume_db", -80.0, maxf(0.05, fade_seconds))
	_current_audio_weather = ""

func play_thunder() -> void:
	if not weather_audio_enabled or not is_instance_valid(_thunder_player):
		return
	_thunder_time = 0.0
	_thunder_player.volume_db = -7.0
	_thunder_player.play()
	_thunder_playback = _thunder_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _setup_weather_bus() -> void:
	var bus_index := AudioServer.get_bus_index(WEATHER_BUS)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, WEATHER_BUS)
	AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.set_bus_volume_db(bus_index, 0.0)

func _setup_weather_players() -> void:
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "WeatherAudioPlayer%d" % i
		player.bus = WEATHER_BUS
		player.volume_db = -80.0
		add_child(player)
		_weather_audio_players.append(player)
		_weather_audio_playbacks.append(null)
	_thunder_player = AudioStreamPlayer.new()
	_thunder_player.name = "ThunderPlayer"
	_thunder_player.bus = WEATHER_BUS
	var thunder_stream := AudioStreamGenerator.new()
	thunder_stream.mix_rate = AUDIO_MIX_RATE
	thunder_stream.buffer_length = 0.5
	_thunder_player.stream = thunder_stream
	add_child(_thunder_player)

func _load_weather_stream(climate_name: String) -> AudioStream:
	if climate_name.is_empty():
		return null
	var path: String = WEATHER_AUDIO_PATHS.get(climate_name, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path)
		if loaded is AudioStream:
			print("[WeatherAudio] Cargado: ", path)
			return loaded as AudioStream
		push_warning("[WeatherAudio] El recurso no es un AudioStream: %s" % path)
	if use_procedural_audio_fallback:
		print("[WeatherAudio] Fallback procedural: ", climate_name)
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = AUDIO_MIX_RATE
		generator.buffer_length = AUDIO_BUFFER_SECONDS
		return generator
	push_warning("[WeatherAudio] Falta el sonido climático: %s" % climate_name)
	return null

func _fill_procedural_buffer(index: int) -> void:
	var player := _weather_audio_players[index]
	if player.stream == null or not player.playing:
		return
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	_weather_audio_playbacks[index] = playback
	var climate_name := _weather_audio_states[index]
	var available := mini(playback.get_frames_available(), 512)
	for frame in range(available):
		var sample_time := _weather_audio_time + float(frame) / AUDIO_MIX_RATE
		var sample := _procedural_sample(climate_name, sample_time)
		playback.push_frame(Vector2(sample, sample))

func _fill_thunder_buffer() -> void:
	if _thunder_time >= 1.25 or _thunder_playback == null:
		return
	var available := mini(_thunder_playback.get_frames_available(), 512)
	for frame in range(available):
		var t := _thunder_time + float(frame) / AUDIO_MIX_RATE
		var envelope := exp(-t * 2.7)
		var rumble := sin(TAU * (38.0 + sin(t * 3.0) * 8.0) * t) * 0.18
		var crackle := sin(TAU * 167.0 * t + sin(t * 51.0)) * 0.035 * exp(-t * 9.0)
		_thunder_playback.push_frame(Vector2((rumble + crackle) * envelope, (rumble + crackle) * envelope))
	_thunder_time = t


func _procedural_sample(climate_name: String, sample_time: float) -> float:
	var low := sin(TAU * 48.0 * sample_time) * 0.018
	var mid := sin(TAU * 117.0 * sample_time) * 0.009
	var noise := sin(TAU * 173.0 * sample_time + sin(sample_time * 2.7)) * 0.012
	match climate_name:
		"lluvia":
			return low * 0.45 + mid + noise * 1.8
		"tormenta":
			var rumble := sin(TAU * 31.0 * sample_time) * 0.045
			return rumble + low + noise * 2.2
		"niebla":
			return sin(TAU * 64.0 * sample_time) * 0.025 + noise * 0.4
		"viento":
			return low * 1.8 + mid * 0.8 + noise * 1.5
		"noche":
			return sin(TAU * 42.0 * sample_time) * 0.018 + noise * 0.45
	return 0.0
