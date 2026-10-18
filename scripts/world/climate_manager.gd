class_name ClimateManager
extends Node

signal climate_changed(climate_name: String)
signal climate_audio_changed(climate_name: String)

@export_category("Configuración seleccionada")
@export var settings: ClimateSettings ## Preset activo. Se puede cambiar desde el Inspector.

@export_category("Audio meteorológico")
@export var weather_audio_enabled: bool = true ## Activa el bus y la ambientación meteorológica.
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var weather_audio_volume_db: float = -12.0 ## Volumen del bus Weather.
@export_range(0.1, 10.0, 0.1, "suffix:s") var weather_audio_fade_seconds: float = 2.0 ## Duración del crossfade.

const WEATHER_BUS := "Weather"
const WEATHER_AUDIO_PATHS := {
	"soleado": "res://audio/weather/birds_day.ogg",
	"lluvia": "res://audio/weather/rain_loop.ogg",
	"tormenta": "res://audio/weather/storm_loop.ogg",
	"niebla": "res://audio/weather/fog_ambience.ogg",
	"viento": "res://audio/weather/wind_loop.ogg",
	"noche": "res://audio/weather/night_ambience.ogg"
}

var _weather_audio_players: Array[AudioStreamPlayer] = []
var _weather_audio_states: Array[String] = ["", ""]
var _weather_audio_index := 0
var _weather_audio_tween: Tween
var _current_audio_weather := ""
var _thunder_player: AudioStreamPlayer
var _crows_player: AudioStreamPlayer
var _crows_cooldown := 18.0

func _ready() -> void:
	if settings == null:
		settings = ClimateSettings.new()
	_setup_weather_bus()
	_setup_weather_players()

func _process(delta: float) -> void:
	if not weather_audio_enabled:
		return
	_crows_cooldown = maxf(0.0, _crows_cooldown - delta)
	if _current_audio_weather == "soleado" and _crows_cooldown <= 0.0 and is_instance_valid(_crows_player) and not _crows_player.playing:
		_crows_player.play()
		_crows_cooldown = randf_range(24.0, 48.0)

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
		normalized = "soleado"
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
	var old_index := _weather_audio_index
	_weather_audio_tween = create_tween().set_parallel(true)
	_weather_audio_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weather_audio_tween.tween_property(_weather_audio_players[_weather_audio_index], "volume_db", -80.0, fade)
	_weather_audio_tween.tween_property(next_player, "volume_db", weather_audio_volume_db, fade)
	get_tree().create_timer(fade).timeout.connect(_stop_weather_player.bind(old_index), CONNECT_ONE_SHOT)
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
	get_tree().create_timer(maxf(0.05, fade_seconds)).timeout.connect(_stop_all_weather_audio, CONNECT_ONE_SHOT)
	_current_audio_weather = ""

func play_thunder() -> void:
	if not weather_audio_enabled or not is_instance_valid(_thunder_player):
		return
	var thunder_stream := ResourceLoader.load("res://audio/weather/thunder.ogg") as AudioStream
	if thunder_stream == null:
		push_warning("[WeatherAudio] No se pudo cargar res://audio/weather/thunder.ogg")
		return
	_thunder_player.stream = thunder_stream
	_thunder_player.volume_db = -7.0
	_thunder_player.play()

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
	_thunder_player = AudioStreamPlayer.new()
	_thunder_player.name = "ThunderPlayer"
	_thunder_player.bus = WEATHER_BUS
	add_child(_thunder_player)
	_crows_player = AudioStreamPlayer.new()
	_crows_player.name = "CrowsPlayer"
	_crows_player.bus = WEATHER_BUS
	_crows_player.stream = ResourceLoader.load("res://audio/weather/crows.ogg") as AudioStream
	_crows_player.volume_db = -19.0
	add_child(_crows_player)

func _load_weather_stream(climate_name: String) -> AudioStream:
	if climate_name.is_empty():
		return null
	var path: String = WEATHER_AUDIO_PATHS.get(climate_name, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path)
		if loaded is AudioStream:
			if loaded is AudioStreamOggVorbis:
				(loaded as AudioStreamOggVorbis).loop = true
			print("[WeatherAudio] Cargado: ", path)
			return loaded as AudioStream
		push_warning("[WeatherAudio] El recurso no es un AudioStream: %s" % path)
	push_warning("[WeatherAudio] Falta el sonido climático: %s" % climate_name)
	return null

func _stop_weather_player(index: int) -> void:
	if index >= 0 and index < _weather_audio_players.size():
		_weather_audio_players[index].stop()

func _stop_all_weather_audio() -> void:
	for player in _weather_audio_players:
		player.stop()
