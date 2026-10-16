extends Node2D

const SAVE_PATH := "user://survivor_records.json"
const WORLD_SIZE := Vector2(1280, 720)
const PLAYER_SPEED := 310.0
const UPGRADE_INTERVAL := 25.0
const MAX_PARTICLES := 180
const MAGAZINE_SIZE := 12
const RELOAD_DURATION := 0.85
const ENEMY_DATABASE_SCRIPT := preload("res://scripts/enemies/enemy_database.gd")
const CHARACTER_DATA_SCRIPT := preload("res://scripts/characters/character_data.gd")
const STORM_EFFECT_SCRIPT := preload("res://scripts/ui/storm_effect.gd")
const DESTRUCTIBLE_OBJECT_SCRIPT := preload("res://scripts/world/destructible_object.gd")
const WORLD_ATMOSPHERE_SCRIPT := preload("res://scripts/world/world_atmosphere.gd")
const VIRTUAL_JOYSTICK_SCRIPT := preload("res://scripts/ui/virtual_joystick.gd")
const LOADING_ATMOSPHERE_SCRIPT := preload("res://scripts/ui/loading_screen.gd")

var mode := "menu"
var player_pos := Vector2(640, 390)
var aim_pos := Vector2(640, 390)
var player_moving := false
var player_facing := Vector2.DOWN
var player_dead := false
var player_sprite: AnimatedSprite2D
var bullets: Array[Dictionary] = []
var zombies: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var props: Array[Dictionary] = []
var navigation_region: NavigationRegion2D
var world_parallax: ParallaxBackground
var world_camera: Camera2D
var world_backdrop: Sprite2D
var world_tilemap: TileMapLayer
var world_decor_layer: TileMapLayer
var road_spawn_points: Array[Vector2] = []
var road_waypoints: Array[Vector2] = []
var spawn_serial := 0
var world_seed := 0
var zombie_sheet: Texture2D
var zombie_scene: PackedScene
var bestiary_scene: PackedScene
var zombie_animation_sheets: Array[Texture2D] = []
var survivor_sheet: Texture2D
var survivor_directional_sheets: Array[Texture2D] = []
var enemy_data_list: Array[Resource] = []
var character_data_list: Array[Resource] = []
var bestiary
var score := 0
var kills := 0
var wave := 0
var combo := 0
var lives := 3
var damage_cooldown := 0.0
var spawn_protection := 0.0
var player_speed := PLAYER_SPEED
var score_multiplier := 1.0
var projectile_speed_multiplier := 1.0
var fire_rate_multiplier := 1.0
var bullet_size_multiplier := 1.0
var shoot_cooldown := 0.0
var ammo_in_magazine := MAGAZINE_SIZE
var reload_timer := 0.0
var weapon_reloading := false
var protection_timer := 0.0
var phase_timer := 0.0
var upgrade_levels: Dictionary = {}
var evolution_unlocked: Dictionary = {}
var evolution_acquired: Dictionary = {}
var player_base_speed := PLAYER_SPEED
const MAX_UPGRADE_LEVEL := 5
const UPGRADE_MAX_LEVELS := {"fury": 5, "speed": 4, "medkit": 3, "heavy": 5, "survivor": 3}
const UPGRADE_EVOLUTIONS := {
	"fury": {"id": "fury_evolution", "title": "FURIA SANGRIENTA"},
	"speed": {"id": "speed_evolution", "title": "CORREDOR FANTASMA"},
	"medkit": {"id": "medkit_evolution", "title": "BLINDAJE MILITAR"},
	"heavy": {"id": "heavy_evolution", "title": "MUNICIÓN DEVASTADORA"},
	"survivor": {"id": "survivor_evolution", "title": "ÚLTIMA ESPERANZA"}
}
var upgrade_timer := 0.0
var upgrade_pending := false
var upgrade_selecting := false
var upgrade_options: Array[Dictionary] = []
var upgrade_card_textures: Dictionary = {}
var upgrade_float_time := 0.0
var wave_timer := 0.0
var spawn_timer := 0.0
var flash_timer := 0.0
var game_time := 0.0
var weather := "soleado"
var next_weather_wave := 3
var weather_darkness := 0.0
var weather_visibility := 1.0
var weather_rain_strength := 0.0
var weather_fog_strength := 0.0
var weather_lightning_strength := 0.0
var weather_lightning_timer := 0.0
var weather_change_timer := 0.0
var weather_tween: Tween
var climate_controller: ClimateManager
var climate_config: ClimateSettings
var username := ""
var records: Dictionary = {}
var rng := RandomNumberGenerator.new()
var name_input: LineEdit
var start_button: Button
var settings_button: Button
var exit_button: Button
var stats_button: Button
var character_buttons: Array[Button] = []
var character_highlight: Panel
var selected_character := -1
var character_voice_armed := false
var menu_message: Label
var voice_debug_label: Label
var leaderboard_label: Label
var hud: CanvasLayer
var score_label: Label
var wave_label: Label
var record_label: Label
var lives_label: Label
var ammo_label: Label
var life_icons: Array[TextureRect] = []
var status_label: Label
var game_over_label: Label
var upgrade_panel: ColorRect
var upgrade_overlay: ColorRect
var upgrade_title: Label
var upgrade_confirm_label: Label
var upgrade_buttons: Array[Button] = []
var overlay: ColorRect
var title_label: Label
var title_glow_label: Label
var storm_effect
var subtitle_label: Label
var settings_panel: ColorRect
var settings_status: Label
var settings_controller_status: Label
var sensitivity_slider: HSlider
var settings_action_buttons: Dictionary = {}
var stats_panel: ColorRect
var stats_content: Label
var selection_stats_panel: Panel
var selection_portrait: TextureRect
var selection_preview: AnimatedSprite2D
var selection_name: Label
var selection_description: RichTextLabel
var selection_stat_bars: Dictionary = {}
var selection_stat_values: Dictionary = {}
var selection_message: Label
var rebinding_action := ""
var mouse_sensitivity := 1.0
var audio_manager: Node
var camera_shake_timer := 0.0
var camera_shake_strength := 0.0
var upgrade_lightning_flash: ColorRect
var touch_layer: CanvasLayer
var touch_root: Control
var touch_joystick: Control
var touch_shoot_button: Button
var touch_reload_button: Button
var touch_move := Vector2.ZERO
var touch_shoot_pressed := false
var loading_layer: CanvasLayer
var loading_root: Control
var loading_black: ColorRect
var loading_logo: Label
var loading_tip: Label
var loading_progress: TextureProgressBar
var loading_status: Label
var loading_flash: ColorRect
var loading_tip_index := 0
var loading_tip_timer := 0.0
var boot_loading_finished := false
var scene_transition_layer: CanvasLayer
var scene_transition_fade: ColorRect
var scene_transition_label: Label
var scene_transition_busy := false
var escape_key_was_down := false
var reload_key_was_down := false
var menu_key_was_down := false
const LOADING_TIPS := [
	"Mantén la distancia: los infectados rodean al objetivo.",
	"Las oleadas llegan por la carretera del horizonte.",
	"Busca mejoras que complementen tu estilo de supervivencia.",
	"La niebla reduce la visibilidad, pero no detiene a los infectados."
]

func _ready() -> void:
	# Keep atlas frames pixel-perfect: linear filtering leaks neighboring cells.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	audio_manager = get_node_or_null("/root/AudioManager")
	zombie_scene = load("res://scenes/enemies/zombie.tscn") as PackedScene
	bestiary_scene = load("res://scenes/ui/bestiary.tscn") as PackedScene
	climate_controller = get_node_or_null("ClimateManager") as ClimateManager
	if climate_controller != null:
		climate_config = climate_controller.get_settings()
	rng.randomize()
	enemy_data_list = ENEMY_DATABASE_SCRIPT.all()
	zombie_sheet = load("res://assets/zombies/zombie_types_12.png") as Texture2D
	var animated_zombie_names := ["worker", "police", "soldier", "construction", "scientist", "nurse", "civilian", "burned", "toxic", "mutant", "armored", "runner"]
	for zombie_name in animated_zombie_names:
		var animated_texture: Texture2D = load("res://assets/zombies/animated/Zombie_%s.png" % zombie_name) as Texture2D
		zombie_animation_sheets.append(animated_texture)
	survivor_sheet = load("res://assets/characters/survivors_4.png") as Texture2D
	_build_character_data()
	var animated_survivor_names := ["01", "02", "03", "04"]
	for survivor_name in animated_survivor_names:
		var directional_texture: Texture2D = load("res://assets/characters/directional/survivor_%s_directional.png" % survivor_name)
		survivor_directional_sheets.append(directional_texture)
	records = _load_records()
	queue_redraw()
	_build_menu()
	_build_hud()
	_build_touch_controls()
	_build_props()
	_build_world_parallax()
	_build_world_camera()
	bestiary = bestiary_scene.instantiate() if bestiary_scene != null else null
	var bestiary_layer := CanvasLayer.new()
	bestiary_layer.name = "BestiaryLayer"
	bestiary_layer.layer = 20
	add_child(bestiary_layer)
	bestiary_layer.add_child(bestiary)
	bestiary.setup(enemy_data_list, _current_discovered_ids())
	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerAnimatedSprite"
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.centered = true
	player_sprite.position = player_pos
	player_sprite.visible = false
	player_sprite.z_index = 5
	add_child(player_sprite)
	queue_redraw()
	if is_instance_valid(audio_manager):
		audio_manager.call("start_menu_music")

func _process(delta: float) -> void:
	game_time += delta
	_poll_keyboard_shortcuts()
	if loading_layer != null and loading_layer.visible and not boot_loading_finished:
		loading_tip_timer += delta
		if loading_tip_timer >= 0.72:
			loading_tip_timer = 0.0
			_loading_cycle_tip()
	flash_timer = maxf(0.0, flash_timer - delta)
	camera_shake_timer = maxf(0.0, camera_shake_timer - delta)
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	spawn_protection = maxf(0.0, spawn_protection - delta)
	protection_timer = maxf(0.0, protection_timer - delta)
	phase_timer = maxf(0.0, phase_timer - delta)
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	if weapon_reloading:
		reload_timer = maxf(0.0, reload_timer - delta)
		if reload_timer <= 0.0:
			weapon_reloading = false
			ammo_in_magazine = MAGAZINE_SIZE
			if mode == "playing" and status_label != null:
				status_label.text = "ARMA LISTA"
			_update_hud()
	_update_weather(delta)
	if touch_root != null:
		touch_root.visible = _touch_controls_available() and mode == "playing" and not upgrade_selecting
	if mode == "playing":
		_update_game(delta)
		_update_player_sprite()
		queue_redraw()
	elif mode == "upgrade":
		upgrade_float_time += delta
		if not upgrade_selecting:
			for i in range(upgrade_buttons.size()):
				var card := upgrade_buttons[i]
				if is_instance_valid(card):
					var base_position: Vector2 = card.get_meta("base_position", card.position)
					card.position = base_position + Vector2(0.0, sin(upgrade_float_time * 2.0 + float(i) * 1.4) * 3.0)
		_update_particles(delta)
		queue_redraw()
	elif mode == "game_over":
		_update_particles(delta)
		queue_redraw()
	if mode == "menu" and title_label != null:
		var pulse := 0.88 + 0.12 * sin(game_time * 2.0)
		var reveal: float = 1.0
		if storm_effect != null:
			reveal = float(storm_effect.get_logo_alpha())
		title_label.modulate = Color(0.88, 0.98, 1.0, pulse * reveal)
		if title_glow_label != null:
			title_glow_label.modulate = Color(0.2, 0.78, 1.0, (0.16 + pulse * 0.10) * reveal)
		if storm_effect != null and storm_effect.flash_strength > 0.0:
			title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if title_glow_label != null:
				title_glow_label.modulate = Color(0.65, 0.92, 1.0, 0.55)
	if settings_panel != null and settings_panel.visible:
		_update_controller_status()
	_apply_camera_shake()

func _poll_keyboard_shortcuts() -> void:
	# El juego puede ejecutarse embebido en el editor y algunos controles
	# consumen InputEventKey antes de que llegue a _unhandled_input. Leer el
	# estado físico del teclado garantiza que Esc y R sigan funcionando.
	var escape_down := Input.is_key_pressed(KEY_ESCAPE)
	if escape_down and not escape_key_was_down and mode in ["playing", "upgrade", "game_over"]:
		print("[DEBUG][MENU] Escape detectado por polling | modo=", mode, " | transition_busy=", scene_transition_busy)
		if not username.is_empty():
			_save_record()
		_return_to_menu("Sesion guardada. Elige otro superviviente o vuelve a entrar.")
	escape_key_was_down = escape_down

	var reload_down := Input.is_key_pressed(KEY_R)
	if reload_down and not reload_key_was_down:
		if mode == "playing":
			_reload_weapon()
	reload_key_was_down = reload_down

	var menu_down := Input.is_key_pressed(KEY_F)
	if menu_down and not menu_key_was_down and mode in ["playing", "upgrade", "game_over"]:
		print("[DEBUG][MENU] F detectada por polling | modo=", mode, " | transition_busy=", scene_transition_busy)
		_return_to_menu("Sesion guardada. Elige otro superviviente o vuelve a entrar.")
	menu_key_was_down = menu_down

func _touch_controls_available() -> bool:
	# En Windows/Linux/macOS el juego se controla con teclado y ratón. En Web,
	# DisplayServer detecta correctamente los móviles con pantalla táctil.
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _weather_profile(weather_name: String) -> Dictionary:
	match weather_name:
		"nublado":
			return {"darkness": 0.18, "visibility": 0.84, "rain": 0.0, "fog": 0.08}
		"lluvia":
			return {"darkness": 0.12, "visibility": 0.94, "rain": 0.75, "fog": 0.04}
		"tormenta":
			return {"darkness": 0.30, "visibility": 0.82, "rain": 1.0, "fog": 0.14}
		"niebla":
			return {"darkness": 0.16, "visibility": 0.54, "rain": 0.0, "fog": 0.82}
		"noche":
			return {"darkness": 0.48, "visibility": 0.66, "rain": 0.10, "fog": 0.20}
	return {"darkness": 0.0, "visibility": 1.0, "rain": 0.0, "fog": 0.0}

func _climate_enabled() -> bool:
	return climate_config == null or climate_config.climate_enabled

func _climate_float(value: float, fallback: float) -> float:
	return value if climate_config != null else fallback

func _weather_duration(weather_name: String) -> float:
	if climate_config == null:
		return 120.0
	return climate_config.night_duration if weather_name == "noche" else climate_config.day_duration

func _random_change_interval() -> float:
	if climate_config == null:
		return 120.0
	return rng.randf_range(climate_config.min_change_interval, maxf(climate_config.min_change_interval, climate_config.max_change_interval))

func _set_weather(next_weather: String, announce: bool = true) -> void:
	if not _climate_enabled():
		next_weather = "soleado"
	weather = next_weather
	var profile := _weather_profile(next_weather)
	var rain_target := float(profile["rain"]) * (climate_config.rain_intensity if climate_config != null else 1.0)
	var fog_target := float(profile["fog"]) * (climate_config.fog_intensity if climate_config != null else 1.0)
	weather_change_timer = _weather_duration(next_weather) if next_weather == "noche" or next_weather == "soleado" else _random_change_interval()
	if weather_tween != null and weather_tween.is_valid():
		weather_tween.kill()
	weather_tween = create_tween().set_parallel(true)
	weather_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var transition_time := climate_config.climate_transition_speed if climate_config != null else 1.8
	weather_tween.tween_property(self, "weather_darkness", float(profile["darkness"]), transition_time)
	weather_tween.tween_property(self, "weather_visibility", float(profile["visibility"]), transition_time)
	weather_tween.tween_property(self, "weather_rain_strength", rain_target, transition_time)
	weather_tween.tween_property(self, "weather_fog_strength", fog_target, transition_time)
	if announce and mode == "playing":
		var weather_names := {"soleado": "SOLEADO", "nublado": "NUBLADO", "lluvia": "LLUVIA", "tormenta": "TORMENTA", "niebla": "NIEBLA", "noche": "NOCHE"}
		status_label.text = "CLIMA: %s" % str(weather_names.get(next_weather, next_weather.to_upper()))
		if next_weather == "noche":
			status_label.text = "Ha caído la noche. Los infectados son más peligrosos."

func _maybe_change_weather(force: bool = false) -> void:
	if not _climate_enabled():
		return
	if not force and weather_change_timer > 0.0:
		return
	if not force and wave < next_weather_wave:
		weather_change_timer = 2.0
		return
	next_weather_wave = wave + rng.randi_range(3, 4)
	weather_change_timer = _random_change_interval()
	if rng.randf() > 0.78 and not force:
		return
	_set_weather(_roll_weather(), true)

func _roll_weather() -> String:
	var weights := {
		"soleado": 0.85,
		"nublado": 0.75,
		"lluvia": climate_config.rain_probability if climate_config != null else 0.28,
		"tormenta": climate_config.storm_probability if climate_config != null else 0.12,
		"niebla": climate_config.fog_probability if climate_config != null else 0.18,
		"noche": 0.80
	}
	weights.erase(weather)
	var total := 0.0
	for weight in weights.values():
		total += float(weight)
	if total <= 0.0:
		return "soleado"
	var roll := rng.randf_range(0.0, total)
	for key in weights.keys():
		roll -= float(weights[key])
		if roll <= 0.0:
			return str(key)
	return "soleado"

func _update_weather(delta: float) -> void:
	if not _climate_enabled():
		if weather != "soleado" or weather_darkness > 0.001 or weather_rain_strength > 0.001 or weather_fog_strength > 0.001:
			_set_weather("soleado", false)
		weather_change_timer = 0.0
		weather_lightning_strength = 0.0
		return
	weather_change_timer = maxf(0.0, weather_change_timer - delta)
	if mode == "playing" and weather_change_timer <= 0.0:
		_maybe_change_weather(false)
	weather_lightning_strength = maxf(0.0, weather_lightning_strength - delta * 3.8)
	if weather != "tormenta":
		weather_lightning_timer = 0.0
		return
	weather_lightning_timer -= delta
	if weather_lightning_timer <= 0.0:
		var frequency := climate_config.lightning_frequency if climate_config != null else 5.5
		weather_lightning_timer = rng.randf_range(maxf(0.2, frequency * 0.65), maxf(0.3, frequency * 1.35))
		weather_lightning_strength = 1.0
		flash_timer = 0.24
		_spawn_burst(player_pos, Color("c5e9ff"), 12)
		if is_instance_valid(audio_manager):
			audio_manager.call("play_upgrade_sound", "thunder", "LEGENDARIA", "select")
	queue_redraw()

func _weather_player_speed() -> float:
	return 0.95 if weather == "lluvia" or weather == "tormenta" else 1.0

func _weather_zombie_speed() -> float:
	return 0.95 if weather == "lluvia" or weather == "tormenta" else 1.0

func _night_bonus_for_enemy(data: Resource) -> float:
	if weather != "noche":
		return 0.0
	var enemy_id := str(data.id)
	var base_bonus := climate_config.night_zombie_bonus if climate_config != null else 0.01
	if enemy_id == "runner":
		return base_bonus * 2.0
	if enemy_id == "toxic" or enemy_id == "scientist" or enemy_id == "burned":
		return base_bonus * 3.0
	if str(data.rarity).to_lower().contains("épico") or enemy_id == "mutant" or enemy_id == "armored":
		return base_bonus * 4.0
	return base_bonus

func _build_loading_overlay() -> void:
	loading_layer = CanvasLayer.new()
	loading_layer.name = "CinematicLoadingLayer"
	loading_layer.layer = 100
	add_child(loading_layer)
	loading_root = Control.new()
	loading_root.name = "LoadingRoot"
	loading_root.size = WORLD_SIZE
	loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_layer.add_child(loading_root)
	loading_black = ColorRect.new()
	loading_black.name = "BlackScreen"
	loading_black.size = WORLD_SIZE
	loading_black.color = Color(0.0, 0.008, 0.012, 1.0)
	loading_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(loading_black)
	var fog := LOADING_ATMOSPHERE_SCRIPT.new()
	fog.name = "MovingFog"
	fog.size = WORLD_SIZE
	fog.z_index = 1
	loading_root.add_child(fog)
	loading_logo = _label(loading_root, "NOCHE DE LOS INFECTADOS", Vector2(160, 206), 42, Color("e6f7fb"))
	loading_logo.size = Vector2(960, 64)
	loading_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_logo.add_theme_constant_override("outline_size", 5)
	loading_logo.add_theme_color_override("font_outline_color", Color(0.12, 0.55, 0.78, 0.92))
	loading_logo.add_theme_constant_override("shadow_offset_x", 4)
	loading_logo.add_theme_constant_override("shadow_offset_y", 7)
	loading_logo.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.04, 0.95))
	loading_logo.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_logo.z_index = 2
	loading_tip = _label(loading_root, LOADING_TIPS[0], Vector2(190, 390), 16, Color("b7c9cd"))
	loading_tip.size = Vector2(900, 34)
	loading_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_tip.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_tip.z_index = 2
	loading_progress = TextureProgressBar.new()
	loading_progress.name = "LoadingProgress"
	loading_progress.position = Vector2(390, 472)
	loading_progress.size = Vector2(500, 28)
	loading_progress.max_value = 100.0
	loading_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_progress.texture_under = load("res://assets/ui/stats/stat_bar_bg.png") as Texture2D
	loading_progress.texture_progress = load("res://assets/ui/stats/defense_fill.png") as Texture2D
	loading_progress.texture_over = load("res://assets/ui/stats/stat_bar_frame.png") as Texture2D
	loading_progress.nine_patch_stretch = true
	loading_progress.stretch_margin_left = 20
	loading_progress.stretch_margin_top = 8
	loading_progress.stretch_margin_right = 20
	loading_progress.stretch_margin_bottom = 8
	loading_progress.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	loading_progress.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_progress.z_index = 2
	loading_root.add_child(loading_progress)
	loading_status = _label(loading_root, "PREPARANDO LA NOCHE...", Vector2(300, 515), 13, Color("7bc5cf"))
	loading_status.size = Vector2(680, 26)
	loading_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_status.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_status.z_index = 2
	loading_flash = ColorRect.new()
	loading_flash.name = "LoadingFlash"
	loading_flash.size = WORLD_SIZE
	loading_flash.color = Color(0.55, 0.88, 1.0, 0.0)
	loading_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_flash.z_index = 10
	loading_root.add_child(loading_flash)
	_build_scene_transition_overlay()
	loading_layer.visible = true

func _build_scene_transition_overlay() -> void:
	scene_transition_layer = CanvasLayer.new()
	scene_transition_layer.name = "SceneTransitionLayer"
	scene_transition_layer.layer = 110
	add_child(scene_transition_layer)
	var root := Control.new()
	root.size = WORLD_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_transition_layer.add_child(root)
	scene_transition_fade = ColorRect.new()
	scene_transition_fade.size = WORLD_SIZE
	scene_transition_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	scene_transition_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scene_transition_fade)
	scene_transition_label = _label(root, "", Vector2(260, 338), 18, Color("c8e5e8"))
	scene_transition_label.size = Vector2(760, 40)
	scene_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_transition_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	scene_transition_label.add_theme_constant_override("outline_size", 3)
	scene_transition_label.add_theme_color_override("font_outline_color", Color(0.0, 0.08, 0.10, 0.9))
	scene_transition_layer.visible = false

func _play_boot_loading() -> void:
	boot_loading_finished = false
	loading_tip_index = 0
	loading_tip_timer = 0.0
	loading_tip.text = LOADING_TIPS[0]
	loading_progress.value = 0.0
	loading_root.modulate = Color.WHITE
	loading_black.color = Color(0.0, 0.008, 0.012, 1.0)
	loading_logo.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_tip.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_progress.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_status.modulate = Color(1.0, 1.0, 1.0, 0.0)
	loading_layer.visible = true
	var reveal := create_tween().set_parallel()
	reveal.tween_property(loading_logo, "modulate", Color.WHITE, 0.72).set_delay(0.12)
	reveal.tween_property(loading_tip, "modulate", Color.WHITE, 0.55).set_delay(0.50)
	reveal.tween_property(loading_progress, "modulate", Color.WHITE, 0.48).set_delay(0.72)
	reveal.tween_property(loading_status, "modulate", Color.WHITE, 0.48).set_delay(0.82)
	var progress_tween := create_tween()
	progress_tween.tween_interval(0.32)
	progress_tween.tween_property(loading_progress, "value", 100.0, 1.42)
	progress_tween.tween_interval(0.18)
	progress_tween.tween_callback(_finish_boot_loading)

func _loading_cycle_tip() -> void:
	loading_tip_index = (loading_tip_index + 1) % LOADING_TIPS.size()
	var tween := create_tween()
	tween.tween_property(loading_tip, "modulate:a", 0.25, 0.12)
	tween.tween_callback(func() -> void: loading_tip.text = LOADING_TIPS[loading_tip_index])
	tween.tween_property(loading_tip, "modulate:a", 1.0, 0.18)

func _finish_boot_loading() -> void:
	if boot_loading_finished:
		return
	loading_status.text = "CARGA COMPLETADA"
	var tween := create_tween()
	tween.tween_property(loading_flash, "color", Color(0.62, 0.9, 1.0, 0.24), 0.08)
	tween.tween_property(loading_flash, "color", Color(0.62, 0.9, 1.0, 0.0), 0.26)
	tween.tween_interval(0.16)
	tween.tween_callback(_reveal_menu_after_loading)

func _reveal_menu_after_loading() -> void:
	boot_loading_finished = true
	var menu_layer := get_node_or_null("MenuLayer") as CanvasLayer
	if menu_layer != null:
		menu_layer.visible = true
	var tween := create_tween()
	tween.tween_property(loading_root, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.58)
	tween.tween_callback(func() -> void:
		loading_layer.visible = false
		loading_root.modulate = Color.WHITE
	)

func _play_scene_transition(callback: Callable, message: String) -> void:
	if scene_transition_busy or scene_transition_layer == null:
		return
	scene_transition_busy = true
	scene_transition_layer.visible = true
	scene_transition_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	scene_transition_label.text = message
	scene_transition_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(scene_transition_fade, "color", Color(0.0, 0.0, 0.0, 1.0), 0.36)
	tween.parallel().tween_property(scene_transition_label, "modulate", Color.WHITE, 0.24)
	tween.tween_interval(0.10)
	tween.tween_callback(callback)
	tween.tween_interval(0.12)
	tween.tween_property(scene_transition_fade, "color", Color(0.0, 0.0, 0.0, 0.0), 0.46)
	tween.parallel().tween_property(scene_transition_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.24)
	tween.tween_callback(func() -> void:
		scene_transition_busy = false
		scene_transition_layer.visible = false
	)

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MenuLayer"
	add_child(layer)
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = WORLD_SIZE
	bg.color = Color("091018")
	layer.add_child(bg)
	var menu_image := TextureRect.new()
	menu_image.position = Vector2.ZERO
	menu_image.size = WORLD_SIZE
	menu_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_image.texture = load("res://assets/backgrounds/menu_apocalypse.png") as Texture2D
	layer.add_child(menu_image)
	storm_effect = STORM_EFFECT_SCRIPT.new()
	storm_effect.name = "StormTitleAtmosphere"
	storm_effect.position = Vector2.ZERO
	storm_effect.size = WORLD_SIZE
	layer.add_child(storm_effect)

	var panel := ColorRect.new()
	panel.position = Vector2(310, 105)
	panel.size = Vector2(660, 585)
	panel.color = Color(0.04, 0.08, 0.1, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)

	title_glow_label = _label(layer, "NOCHE DE LOS INFECTADOS", Vector2(365, 155), 34, Color("267d9c"))
	title_glow_label.size = Vector2(560, 48)
	title_glow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_glow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_glow_label.add_theme_constant_override("outline_size", 10)
	title_glow_label.add_theme_color_override("font_outline_color", Color(0.10, 0.58, 0.88, 0.42))
	title_label = _label(layer, "NOCHE DE LOS INFECTADOS", Vector2(365, 151), 34, Color("e9f1f3"))
	title_label.size = Vector2(560, 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.add_theme_color_override("font_outline_color", Color("d9f3f8"))
	title_label.add_theme_constant_override("shadow_offset_x", 5)
	title_label.add_theme_constant_override("shadow_offset_y", 8)
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.04, 0.9))
	subtitle_label = _label(layer, "SOBREVIVE. DISPARA. RECUERDA.", Vector2(365, 205), 14, Color("d34d52"))
	subtitle_label.size = Vector2(560, 26)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_constant_override("outline_size", 2)
	subtitle_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	subtitle_label.add_theme_constant_override("shadow_offset_y", 3)
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	title_label.visible = true
	subtitle_label.visible = true
	name_input = LineEdit.new()
	name_input.position = Vector2(487, 263)
	name_input.size = Vector2(320, 39)
	name_input.placeholder_text = "Enter your name"
	name_input.max_length = 18
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.focus_mode = Control.FOCUS_ALL
	name_input.mouse_filter = Control.MOUSE_FILTER_STOP
	name_input.virtual_keyboard_enabled = true
	name_input.virtual_keyboard_show_on_focus = true
	name_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	name_input.add_theme_font_size_override("font_size", 17)
	name_input.add_theme_color_override("font_color", Color("ecf3f1"))
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0, 0, 0, 0.05)
	input_style.border_width_left = 1
	input_style.border_width_top = 1
	input_style.border_width_right = 1
	input_style.border_width_bottom = 1
	input_style.border_color = Color(0.5, 0.8, 0.8, 0.35)
	name_input.add_theme_stylebox_override("normal", input_style)
	name_input.gui_input.connect(_on_name_input_gui_input)
	layer.add_child(name_input)
	character_highlight = Panel.new()
	character_highlight.position = Vector2(260, 325)
	character_highlight.visible = selected_character >= 0
	character_highlight.size = Vector2(160, 200)
	character_highlight.pivot_offset = character_highlight.size * 0.5
	character_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.0, 0.8, 0.65, 0.04)
	highlight_style.border_width_left = 3
	highlight_style.border_width_top = 3
	highlight_style.border_width_right = 3
	highlight_style.border_width_bottom = 3
	highlight_style.border_color = Color("54f5c8")
	character_highlight.add_theme_stylebox_override("panel", highlight_style)
	layer.add_child(character_highlight)
	if survivor_sheet != null:
		var survivor_cell := Vector2(survivor_sheet.get_width() / 4.0, survivor_sheet.get_height())
		for i in range(4):
			var survivor_view := TextureRect.new()
			survivor_view.position = Vector2(275 + i * 160, 340)
			survivor_view.size = Vector2(125, 174)
			survivor_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			survivor_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			survivor_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var survivor_atlas := AtlasTexture.new()
			survivor_atlas.atlas = survivor_sheet
			survivor_atlas.region = Rect2(Vector2(i * survivor_cell.x, 0), survivor_cell)
			survivor_view.texture = survivor_atlas
			layer.add_child(survivor_view)
	for i in range(4):
		var character_button := Button.new()
		character_button.position = Vector2(260 + i * 160, 325)
		character_button.size = Vector2(150, 200)
		character_button.text = ""
		character_button.flat = true
		character_button.modulate = Color(1, 1, 1, 0.02)
		character_button.focus_mode = Control.FOCUS_ALL
		character_button.mouse_entered.connect(_on_character_card_focus.bind(i))
		character_button.focus_entered.connect(_on_character_card_focus.bind(i))
		character_button.pressed.connect(_on_character_card_pressed.bind(i))
		layer.add_child(character_button)
		character_buttons.append(character_button)
	# Godot puede dar foco al primer Button al construir el menú. Ese foco
	# inicial no debe reproducir una voz sin interacción del jugador.
	character_voice_armed = false
	call_deferred("_arm_character_voice")
	_build_character_selection_panel(layer)
	start_button = Button.new()
	start_button.position = Vector2(488, 548)
	start_button.size = Vector2(320, 58)
	start_button.text = "START GAME"
	start_button.modulate = Color.WHITE
	_style_menu_button(start_button, Color("35d8c2"), 17)
	start_button.pressed.connect(_start_game)
	layer.add_child(start_button)
	settings_button = Button.new()
	settings_button.position = Vector2(321, 626)
	settings_button.size = Vector2(150, 46)
	settings_button.text = "SETTINGS"
	settings_button.modulate = Color.WHITE
	_style_menu_button(settings_button, Color("6d8e9a"), 15)
	settings_button.pressed.connect(_show_settings)
	layer.add_child(settings_button)
	exit_button = Button.new()
	exit_button.position = Vector2(489, 626)
	exit_button.size = Vector2(150, 46)
	exit_button.text = "EXIT"
	exit_button.modulate = Color.WHITE
	_style_menu_button(exit_button, Color("6d8e9a"), 15)
	exit_button.pressed.connect(_exit_game)
	layer.add_child(exit_button)
	stats_button = Button.new()
	stats_button.position = Vector2(657, 626)
	stats_button.size = Vector2(150, 46)
	stats_button.text = "STATISTICS"
	_style_menu_button(stats_button, Color("6d8e9a"), 14)
	stats_button.pressed.connect(_show_statistics)
	layer.add_child(stats_button)
	var bestiary_button := Button.new()
	bestiary_button.position = Vector2(825, 626)
	bestiary_button.size = Vector2(150, 46)
	bestiary_button.text = "BESTIARIO"
	_style_menu_button(bestiary_button, Color("6d8e9a"), 13)
	bestiary_button.pressed.connect(_show_bestiary)
	layer.add_child(bestiary_button)
	_build_settings_panel(layer)
	_build_stats_panel(layer)
	# Zona independiente sobre el botón para evitar que los avisos de
	# validación se dibujen encima de START GAME.
	menu_message = _label(layer, "WASD para moverte  •  Ratón para apuntar  •  Click para disparar", Vector2(390, 510), 14, Color("7e969f"))
	menu_message.size = Vector2(560, 28)
	menu_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_message.visible = false
	voice_debug_label = _label(layer, "", Vector2(24, 680), 11, Color("8de8d0"))
	voice_debug_label.size = Vector2(1232, 28)
	voice_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voice_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	voice_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voice_debug_label.visible = false
	leaderboard_label = _label(layer, "", Vector2(365, 580), 14, Color("b9c9c8"))
	leaderboard_label.size = Vector2(560, 135)
	leaderboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_label.visible = false
	_refresh_leaderboard()

func _on_name_input_gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not pressed or name_input == null:
		return

	# El toque debe conservar el gesto del usuario: los navegadores móviles
	# bloquean el teclado si se solicita automáticamente desde _ready().
	name_input.grab_focus()
	if OS.has_feature("web") and DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		var cursor := name_input.caret_column
		DisplayServer.virtual_keyboard_show(
			name_input.text,
			name_input.get_global_rect(),
			DisplayServer.KEYBOARD_TYPE_DEFAULT,
			name_input.max_length,
			cursor,
			cursor
		)

func _on_character_card_focus(index: int) -> void:
	if not character_voice_armed or index < 0 or index >= character_data_list.size() or index == selected_character:
		return
	_play_character_voice_debug(index, false)

func _play_character_voice_debug(index: int, force: bool) -> void:
	if index < 0 or index >= character_data_list.size():
		return
	var character_id := str(character_data_list[index].id)
	var started := false
	if is_instance_valid(audio_manager):
		started = bool(audio_manager.call("play_character_voice", character_id, force))
	var voice_path := "desconocida"
	if character_id == "lumberjack":
		voice_path = "res://audio/voces/Alexluigui.ogg"
	elif character_id == "hunter":
		voice_path = "res://audio/voces/Melo.ogg"
	elif character_id == "engineer":
		voice_path = "res://audio/voces/Lobaherida.ogg"
	elif character_id == "survivor":
		voice_path = "res://audio/voces/Cristhian.ogg"
	print("[UI][VOICE_DEBUG] selección | index=", index, " | ID=", character_id, " | started=", started, " | path=", voice_path, " | force=", force)
	if voice_debug_label != null:
		voice_debug_label.text = "VOZ DEBUG · ID: %s · ARCHIVO: %s · ESTADO: %s" % [character_id, voice_path.get_file(), "REPRODUCIENDO" if started else "NO DISPONIBLE"]
		voice_debug_label.visible = true
		voice_debug_label.modulate = Color.WHITE
		var debug_tween := create_tween()
		debug_tween.tween_interval(4.0)
		debug_tween.tween_property(voice_debug_label, "modulate:a", 0.0, 0.35)
		debug_tween.tween_callback(func() -> void:
			voice_debug_label.visible = false
			voice_debug_label.modulate = Color.WHITE
		)

func _arm_character_voice() -> void:
	# Espera un frame para ignorar el foco automático del menú recién creado.
	await get_tree().process_frame
	character_voice_armed = true

func _on_character_card_pressed(index: int) -> void:
	# En táctil el Button puede no emitir focus_entered; la selección garantiza
	# igualmente la reproducción de la voz antes de aplicar el personaje.
	character_voice_armed = true
	if index != selected_character:
		_on_character_card_focus(index)
	_select_character(index)

func _select_character(index: int) -> void:
	if index < 0 or index >= character_data_list.size():
		return
	var character_changed := index != selected_character
	selected_character = index
	# La voz es el sonido de confirmación de la carta. Se elimina el tono
	# procedural antiguo que se superponía y ocultaba la voz en Web.
	if character_changed and is_instance_valid(audio_manager):
		_play_character_voice_debug(index, true)
	character_highlight.position = Vector2(260 + index * 160, 325)
	character_highlight.visible = true
	character_highlight.scale = Vector2(1.08, 1.08)
	var highlight_pulse := create_tween()
	highlight_pulse.tween_property(character_highlight, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_selection_panel()
	_refresh_character_selection()
	if selection_message != null:
		selection_message.visible = false
	# A short confirmation pulse makes the selection immediately visible.
	if selection_preview != null:
		selection_preview.scale = Vector2(1.35, 1.35)
		var pulse := create_tween()
		pulse.tween_property(selection_preview, "scale", Vector2(1.25, 1.25), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_selection_panel() -> void:
	if selection_stats_panel == null:
		return
	if selection_stats_panel.visible:
		return
	selection_stats_panel.visible = true
	var final_position := Vector2(955, 160)
	selection_stats_panel.position = Vector2(1280, 160)
	var reveal := create_tween()
	reveal.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal.tween_property(selection_stats_panel, "position", final_position, 0.28)

func _build_character_data() -> void:
	character_data_list.clear()
	# Keep the startup path deterministic. These Resource instances are the
	# same CharacterData structure used by the selection UI and can later be
	# replaced by .tres resources without changing the rest of the code.
	var definitions := [
		["lumberjack", "AlexLuigui", "Fuerte y resistente; abre camino con su hacha.", 140, 30, 12, 185.0, 0.08, "Golpe de hacha"],
		["hunter", "Melo", "Especialista a distancia y en golpes críticos.", 100, 38, 7, 300.0, 0.18, "Disparo preciso"],
		["engineer", "Loba Herida", "Especialista en herramientas y reparación; resiste más tiempo.", 115, 24, 15, 210.0, 0.10, "Reparación"],
		["survivor", "Cristhian", "Sobrevive herido, pero sigue siendo equilibrado, rápido y decidido.", 125, 28, 10, 225.0, 0.12, "Adrenalina"]
	]
	for definition in definitions:
		var data = CHARACTER_DATA_SCRIPT.new()
		data.id = definition[0]
		data.display_name = definition[1]
		data.description = definition[2]
		data.level = 1
		data.max_health = definition[3]
		data.attack_power = definition[4]
		data.defense = definition[5]
		data.attack_range = definition[6]
		data.critical_chance = definition[7]
		data.special_ability = definition[8]
		character_data_list.append(data)
	for character_index in range(character_data_list.size()):
		var data = character_data_list[character_index]
		if survivor_sheet != null:
			var cell := Vector2(survivor_sheet.get_width() / 4.0, survivor_sheet.get_height())
			var portrait := AtlasTexture.new()
			portrait.atlas = survivor_sheet
			portrait.region = Rect2(Vector2(character_index * cell.x, 0), cell)
			data.portrait = portrait

func _build_character_selection_panel(parent: Node) -> void:
	selection_stats_panel = Panel.new()
	selection_stats_panel.position = Vector2(955, 160)
	# Keep the panel above the bottom menu buttons. The content ends at the
	# skill row, so a shorter panel gives the selection screen clear separation.
	selection_stats_panel.size = Vector2(305, 455)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.055, 0.07, 0.96)
	panel_style.border_color = Color("347d78")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	panel_style.shadow_size = 12
	selection_stats_panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(selection_stats_panel)
	selection_stats_panel.visible = false
	var heading := _label(selection_stats_panel, "PERFIL DEL SUPERVIVIENTE", Vector2(18, 12), 12, Color("65e6c4"))
	heading.size = Vector2(270, 22)
	selection_name = _label(selection_stats_panel, "Selecciona un personaje", Vector2(18, 35), 21, Color("f0d28a"))
	selection_name.size = Vector2(270, 32)
	selection_name.clip_text = true
	selection_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selection_portrait = TextureRect.new()
	selection_portrait.position = Vector2(18, 98)
	selection_portrait.size = Vector2(70, 70)
	selection_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selection_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selection_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_portrait.visible = false
	selection_stats_panel.add_child(selection_portrait)
	selection_description = RichTextLabel.new()
	selection_description.name = "SelectionDescription"
	selection_description.set_anchors_preset(Control.PRESET_TOP_WIDE)
	selection_description.offset_left = 100.0
	selection_description.offset_top = 99.0
	selection_description.offset_right = -15.0
	selection_description.offset_bottom = 169.0
	selection_description.bbcode_enabled = false
	selection_description.fit_content = false
	selection_description.scroll_active = false
	selection_description.clip_contents = true
	selection_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_description.add_theme_font_size_override("normal_font_size", 11)
	selection_description.add_theme_color_override("default_color", Color("b9c9c8"))
	selection_description.add_theme_constant_override("line_separation", 2)
	selection_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_description.text = "Haz clic en un personaje para ver sus estadísticas."
	selection_stats_panel.add_child(selection_description)
	var stat_names := ["Vida máxima", "Ataque", "Defensa", "Velocidad", "Alcance", "Crítico"]
	var stat_icon_paths := {
		"Vida máxima": "res://assets/ui/stats/stat_health.png",
		"Ataque": "res://assets/ui/stats/stat_attack.png",
		"Defensa": "res://assets/ui/stats/stat_defense.png",
		"Velocidad": "res://assets/ui/stats/stat_speed.png",
		"Alcance": "res://assets/ui/stats/stat_range.png",
		"Crítico": "res://assets/ui/stats/stat_critical.png"
	}
	var bar_under := load("res://assets/ui/stats/stat_bar_bg.png") as Texture2D
	var bar_over := load("res://assets/ui/stats/stat_bar_frame.png") as Texture2D
	var bar_progress_paths := {
		"Vida máxima": "res://assets/ui/stats/life_fill.png",
		"Ataque": "res://assets/ui/stats/attack_fill.png",
		"Defensa": "res://assets/ui/stats/defense_fill.png",
		"Velocidad": "res://assets/ui/stats/speed_fill.png",
		"Alcance": "res://assets/ui/stats/range_fill.png",
		"Crítico": "res://assets/ui/stats/critical_fill.png"
	}
	for i in range(stat_names.size()):
		var stat_name: String = stat_names[i]
		var y := 190.0 + i * 35.0
		var icon := TextureRect.new()
		icon.position = Vector2(18, y - 3)
		icon.size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(str(stat_icon_paths[stat_name])) as Texture2D
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selection_stats_panel.add_child(icon)
		var label := _label(selection_stats_panel, stat_name, Vector2(48, y), 11, Color("d5e3df"))
		label.size = Vector2(76, 20)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var bar := TextureProgressBar.new()
		bar.position = Vector2(126, y + 1)
		bar.size = Vector2(126, 19)
		bar.max_value = 100.0
		bar.value = 0.0
		bar.step = 1.0
		bar.texture_under = bar_under
		bar.texture_progress = load(str(bar_progress_paths[stat_name])) as Texture2D
		bar.texture_over = bar_over
		bar.nine_patch_stretch = true
		# The PNGs contain the complete material, lighting and wear. Keep the
		# texture colors untouched: no flat tint or modulate is applied.
		bar.stretch_margin_left = 20
		bar.stretch_margin_top = 8
		bar.stretch_margin_right = 20
		bar.stretch_margin_bottom = 8
		bar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selection_stats_panel.add_child(bar)
		selection_stat_bars[stat_name] = bar
		var value_label := _label(selection_stats_panel, "00", Vector2(258, y - 1), 12, Color("e8f5ef"))
		value_label.size = Vector2(31, 21)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		selection_stat_values[stat_name] = value_label
	var divider := ColorRect.new()
	divider.position = Vector2(18, 410)
	divider.size = Vector2(269, 1)
	divider.color = Color(0.30, 0.84, 0.76, 0.22)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_stats_panel.add_child(divider)
	var skill := _label(selection_stats_panel, "HABILIDAD  ·  —", Vector2(18, 424), 12, Color("f0bf6d"))
	skill.size = Vector2(269, 28)
	skill.clip_text = true
	skill.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	skill.name = "SelectionSkill"
	# Mensaje de validación centrado justo encima del botón principal.
	selection_message = _label(parent, "Selecciona un personaje", Vector2(488, 514), 13, Color("e27878"))
	selection_message.size = Vector2(320, 28)
	selection_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selection_message.visible = false
	selection_preview = AnimatedSprite2D.new()
	selection_preview.name = "SelectedCharacterPreview"
	selection_preview.position = Vector2(53, 138)
	selection_preview.scale = Vector2(0.92, 0.92)
	selection_preview.z_index = 4
	selection_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selection_preview.visible = false
	selection_stats_panel.add_child(selection_preview)
	if selected_character >= 0:
		_refresh_character_selection()

func _refresh_character_selection() -> void:
	if selected_character < 0 or selected_character >= character_data_list.size():
		return
	var data = character_data_list[selected_character]
	selection_name.text = data.display_name
	selection_portrait.texture = data.portrait
	selection_description.text = data.description
	var values := {
		"Vida máxima": clampf(float(data.max_health) / 2.0, 0.0, 100.0),
		"Ataque": clampf(float(data.attack_power) / 0.5, 0.0, 100.0),
		"Defensa": clampf(float(data.defense) * 5.0, 0.0, 100.0),
		"Velocidad": clampf(float(data.speed) / 4.0, 0.0, 100.0),
		"Alcance": clampf(float(data.attack_range) / 4.0, 0.0, 100.0),
		"Crítico": data.critical_chance * 100.0
	}
	for stat_name in selection_stat_bars.keys():
		var stat_value := clampf(float(values[stat_name]), 0.0, 100.0)
		var bar: TextureProgressBar = selection_stat_bars[stat_name]
		bar.value = stat_value
		var value_label: Label = selection_stat_values[stat_name]
		value_label.text = "%02d" % int(round(stat_value))
	var skill_label: Label = selection_stats_panel.get_node("SelectionSkill")
	skill_label.text = "HABILIDAD  ·  %s" % data.special_ability
	if selection_preview != null:
		var texture: Texture2D = survivor_directional_sheets[selected_character] if selected_character < survivor_directional_sheets.size() else null
		selection_preview.sprite_frames = _build_selection_preview_frames(texture)
		selection_preview.visible = texture != null
		selection_preview.play("idle_preview")

func _build_selection_preview_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle_preview")
	frames.set_animation_speed("idle_preview", 5.0)
	frames.set_animation_loop("idle_preview", true)
	if texture == null:
		return frames
	for frame_index in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * 64, 64, 64, 64)
		frames.add_frame("idle_preview", atlas)
	return frames

func _show_bestiary() -> void:
	if bestiary == null:
		return
	bestiary.setup(enemy_data_list, _current_discovered_ids())
	bestiary.visible = true
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "open")

func _show_settings() -> void:
	settings_panel.visible = true
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "open")
	_update_controller_status()
	_update_settings_buttons()

func _build_stats_panel(parent: Node) -> void:
	stats_panel = ColorRect.new()
	stats_panel.position = Vector2(270, 120)
	stats_panel.size = Vector2(740, 500)
	stats_panel.color = Color(0.035, 0.07, 0.09, 0.96)
	parent.add_child(stats_panel)
	var stats_background := TextureRect.new()
	stats_background.position = Vector2.ZERO
	stats_background.size = Vector2(740, 500)
	stats_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stats_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stats_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_background.texture = load("res://assets/backgrounds/menu_apocalypse.png") as Texture2D
	stats_panel.add_child(stats_background)
	var stats_tint := ColorRect.new()
	stats_tint.position = Vector2.ZERO
	stats_tint.size = Vector2(740, 500)
	stats_tint.color = Color(0.015, 0.04, 0.06, 0.62)
	stats_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_panel.add_child(stats_tint)
	var title := _label(stats_panel, "STATISTICS", Vector2(0, 24), 30, Color("f0bf6d"))
	title.size = Vector2(740, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_content = _label(stats_panel, "", Vector2(45, 90), 16, Color("dce9e7"))
	stats_content.size = Vector2(650, 300)
	stats_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_button := Button.new()
	close_button.position = Vector2(265, 430)
	close_button.size = Vector2(210, 40)
	close_button.text = "CLOSE"
	_style_menu_button(close_button, Color("6d8e9a"), 15)
	close_button.pressed.connect(_close_statistics)
	stats_panel.add_child(close_button)
	stats_panel.visible = false

func _show_statistics() -> void:
	_refresh_leaderboard()
	stats_panel.visible = true
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "open")

func _close_statistics() -> void:
	stats_panel.visible = false
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "close")

func _build_settings_panel(parent: Node) -> void:
	settings_panel = ColorRect.new()
	settings_panel.position = Vector2(300, 105)
	settings_panel.size = Vector2(680, 545)
	settings_panel.color = Color(0.035, 0.07, 0.09, 0.98)
	parent.add_child(settings_panel)
	var title := _label(settings_panel, "SETTINGS", Vector2(0, 24), 30, Color("f0bf6d"))
	title.size = Vector2(680, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var help := _label(settings_panel, "Pulsa una accion y despues una tecla o boton del mando", Vector2(0, 67), 14, Color("a8b8bf"))
	help.size = Vector2(680, 28)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var actions := [["move_up", "MOVE UP"], ["move_down", "MOVE DOWN"], ["move_left", "MOVE LEFT"], ["move_right", "MOVE RIGHT"], ["shoot", "SHOOT"]]
	for i in range(actions.size()):
		var action_name: String = actions[i][0]
		var action_title: String = actions[i][1]
		var label := _label(settings_panel, action_title, Vector2(55, 112 + i * 54), 16, Color("e9f1f3"))
		label.size = Vector2(210, 38)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var action_button := Button.new()
		action_button.position = Vector2(300, 108 + i * 54)
		action_button.size = Vector2(300, 42)
		action_button.pressed.connect(_begin_rebind.bind(action_name))
		settings_panel.add_child(action_button)
		settings_action_buttons[action_name] = action_button
	settings_controller_status = _label(settings_panel, "CONTROLLER: comprobando...", Vector2(55, 390), 16, Color("85d6c4"))
	settings_controller_status.size = Vector2(570, 32)
	var sensitivity_label := _label(settings_panel, "MOUSE SENSITIVITY", Vector2(55, 430), 15, Color("e9f1f3"))
	sensitivity_label.size = Vector2(210, 32)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.position = Vector2(300, 430)
	sensitivity_slider.size = Vector2(300, 32)
	sensitivity_slider.min_value = 0.5
	sensitivity_slider.max_value = 2.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value = mouse_sensitivity
	sensitivity_slider.value_changed.connect(_set_mouse_sensitivity)
	settings_panel.add_child(sensitivity_slider)
	settings_status = _label(settings_panel, "", Vector2(55, 474), 14, Color("d96d6f"))
	settings_status.size = Vector2(570, 28)
	settings_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_button := Button.new()
	close_button.position = Vector2(235, 505)
	close_button.size = Vector2(210, 38)
	close_button.text = "CLOSE"
	close_button.pressed.connect(_close_settings)
	settings_panel.add_child(close_button)
	settings_panel.visible = false
	_update_settings_buttons()

func _close_settings() -> void:
	rebinding_action = ""
	settings_panel.visible = false
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "close")

func _begin_rebind(action_name: String) -> void:
	rebinding_action = action_name
	settings_status.text = "Esperando entrada para %s..." % action_name.to_upper()

func _assign_input_event(event: InputEvent) -> void:
	InputMap.action_erase_events(rebinding_action)
	InputMap.action_add_event(rebinding_action, event)
	settings_status.text = "%s asignado a %s" % [rebinding_action.to_upper(), _event_text(event)]
	rebinding_action = ""
	_update_settings_buttons()

func _event_text(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.keycode)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "MOUSE LEFT"
			MOUSE_BUTTON_RIGHT: return "MOUSE RIGHT"
			MOUSE_BUTTON_MIDDLE: return "MOUSE MIDDLE"
			MOUSE_BUTTON_WHEEL_UP: return "WHEEL UP"
			MOUSE_BUTTON_WHEEL_DOWN: return "WHEEL DOWN"
			MOUSE_BUTTON_WHEEL_LEFT: return "WHEEL LEFT"
			MOUSE_BUTTON_WHEEL_RIGHT: return "WHEEL RIGHT"
			_: return "MOUSE %d" % event.button_index
	if event is InputEventJoypadButton:
		return "PAD BUTTON %d" % event.button_index
	return "INPUT"

func _update_settings_buttons() -> void:
	for action_name in settings_action_buttons.keys():
		var events := InputMap.action_get_events(action_name)
		var button: Button = settings_action_buttons[action_name]
		button.text = _event_text(events[0]) if not events.is_empty() else "UNASSIGNED"

func _set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = value
	if settings_status != null:
		settings_status.text = "Sensibilidad: %.1fx" % mouse_sensitivity

func _update_controller_status() -> void:
	if settings_controller_status == null:
		return
	var pads := Input.get_connected_joypads()
	settings_controller_status.text = "CONTROLLER: CONECTADO (%d)" % pads.size() if not pads.is_empty() else "CONTROLLER: no detectado"

func _exit_game() -> void:
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "press")
	get_tree().quit()

func _refresh_leaderboard() -> void:
	if leaderboard_label == null:
		return
	var entries: Array[Dictionary] = []
	for player_name in records.keys():
		entries.append({"name": str(player_name), "stats": _normalize_record(records[player_name])})
	entries.sort_custom(_sort_records_by_score)
	var text := "MEJORES SUPERVIVIENTES\n"
	if entries.is_empty():
		text += "Aun no hay partidas registradas"
	else:
		for i in range(mini(5, entries.size())):
			var entry: Dictionary = entries[i]
			var stats: Dictionary = entry["stats"]
			text += "%d. %-14s  %06d pts  |  Ronda %02d\n" % [i + 1, entry["name"], int(stats["score"]), int(stats["wave"])]
		var best_round_name: String = entries[0]["name"]
		var best_round: int = int(entries[0]["stats"]["wave"])
		for entry in entries:
			var entry_wave: int = int(entry["stats"]["wave"])
			if entry_wave > best_round:
				best_round = entry_wave
				best_round_name = entry["name"]
		text += "\nMAYOR RONDA: %s  |  Ronda %02d" % [best_round_name, best_round]
	leaderboard_label.text = text
	if stats_content != null:
		var stats_text := "PLAYER STATISTICS\n\n"
		if entries.is_empty():
			stats_text += "Aun no hay partidas registradas"
		else:
			for i in range(mini(10, entries.size())):
				var stats_entry: Dictionary = entries[i]
				var player_stats: Dictionary = stats_entry["stats"]
				stats_text += "%02d  %-16s  SCORE %06d   ROUND %02d   KILLS %03d   GAMES %02d\n" % [i + 1, stats_entry["name"], int(player_stats["score"]), int(player_stats["wave"]), int(player_stats["kills"]), int(player_stats["plays"])]
		stats_content.text = stats_text

func _sort_records_by_score(a: Dictionary, b: Dictionary) -> bool:
	var score_a: int = int(a["stats"]["score"])
	var score_b: int = int(b["stats"]["score"])
	if score_a == score_b:
		return int(a["stats"]["wave"]) > int(b["stats"]["wave"])
	return score_a > score_b

func _normalize_record(value) -> Dictionary:
	if value is Dictionary:
		return {
			"score": int(value.get("score", 0)),
			"wave": int(value.get("wave", 1)),
			"kills": int(value.get("kills", 0)),
			"plays": int(value.get("plays", 0)),
			"discovered": Array(value.get("discovered", []))
		}
	return {"score": int(value), "wave": 1, "kills": 0, "plays": 0, "discovered": []}

func _current_discovered_ids() -> Array[String]:
	var result: Array[String] = []
	if username.is_empty():
		return result
	var saved: Array = _normalize_record(records.get(username, {}))["discovered"]
	for enemy_id in saved:
		result.append(str(enemy_id))
	return result

func _on_enemy_discovered(data) -> void:
	if username.is_empty() or data == null:
		return
	var stats := _normalize_record(records.get(username, {}))
	var discovered: Array = stats["discovered"]
	if not discovered.has(data.id):
		discovered.append(data.id)
		stats["discovered"] = discovered
		records[username] = stats
		_write_records()
		if bestiary != null:
			bestiary.setup(enemy_data_list, _current_discovered_ids())

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var top := ColorRect.new()
	top.position = Vector2(20, 18)
	top.size = Vector2(1240, 86)
	top.color = Color(0.03, 0.07, 0.1, 0.86)
	hud.add_child(top)
	score_label = _label(hud, "PUNTOS  0", Vector2(44, 32), 23, Color("f0bf6d"))
	wave_label = _label(hud, "OLEADA  1", Vector2(320, 35), 19, Color("e9f1f3"))
	record_label = _label(hud, "RECORD  0", Vector2(510, 35), 19, Color("85d6c4"))
	lives_label = _label(hud, "VIDAS", Vector2(705, 35), 19, Color("e85b63"))
	var heart_texture: Texture2D = load("res://assets/ui/heart.svg") as Texture2D
	for i in range(3):
		var heart := TextureRect.new()
		heart.position = Vector2(770 + i * 16, 42)
		heart.size = Vector2(13, 12)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture = heart_texture
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(heart)
		life_icons.append(heart)
	status_label = _label(hud, "", Vector2(820, 38), 16, Color("d96d6f"))
	ammo_label = _label(hud, "MUNICIÓN  12/12", Vector2(1045, 38), 15, Color("f0bf6d"))
	ammo_label.size = Vector2(190, 24)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	game_over_label = _label(hud, "", Vector2(380, 295), 30, Color("f0bf6d"))
	game_over_label.size = Vector2(520, 120)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.visible = false
	_build_upgrade_panel()
	hud.visible = false

func _build_touch_controls() -> void:
	touch_layer = CanvasLayer.new()
	touch_layer.name = "TouchControlsLayer"
	touch_layer.layer = 30
	add_child(touch_layer)
	touch_root = Control.new()
	touch_root.name = "TouchControls"
	touch_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_layer.add_child(touch_root)

	touch_joystick = VIRTUAL_JOYSTICK_SCRIPT.new()
	touch_joystick.name = "MoveJoystick"
	touch_joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	touch_joystick.offset_left = 34.0
	touch_joystick.offset_top = -214.0
	touch_joystick.offset_right = 214.0
	touch_joystick.offset_bottom = -34.0
	touch_joystick.connect("vector_changed", Callable(self, "_on_touch_move_changed"))
	touch_root.add_child(touch_joystick)

	touch_shoot_button = _create_touch_button("DISPARAR", Color("e85b63"))
	touch_shoot_button.name = "ShootButton"
	touch_shoot_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	touch_shoot_button.offset_left = -214.0
	touch_shoot_button.offset_top = -214.0
	touch_shoot_button.offset_right = -34.0
	touch_shoot_button.offset_bottom = -34.0
	touch_shoot_button.button_down.connect(_on_touch_shoot_down)
	touch_shoot_button.button_up.connect(_on_touch_shoot_up)
	touch_root.add_child(touch_shoot_button)

	touch_reload_button = _create_touch_button("RECARGAR", Color("f0bf6d"))
	touch_reload_button.name = "ReloadButton"
	touch_reload_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# El botón de recarga queda encima del disparo y fuera de su área.
	touch_reload_button.offset_left = -214.0
	touch_reload_button.offset_top = -280.0
	touch_reload_button.offset_right = -64.0
	touch_reload_button.offset_bottom = -225.0
	touch_reload_button.pressed.connect(_on_touch_reload)
	touch_root.add_child(touch_reload_button)
	touch_root.visible = false

func _create_touch_button(text: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("e8f5ef"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.10, 0.13, 0.86)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.78)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	normal.shadow_size = 8
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.38)
	pressed.border_color = Color(accent.r, accent.g, accent.b, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	return button

func _on_touch_move_changed(value: Vector2) -> void:
	touch_move = value

func _on_touch_shoot_down() -> void:
	touch_shoot_pressed = true

func _on_touch_shoot_up() -> void:
	touch_shoot_pressed = false

func _on_touch_reload() -> void:
	_reload_weapon()

func _reload_weapon() -> void:
	if mode != "playing" or weapon_reloading or ammo_in_magazine >= MAGAZINE_SIZE:
		return
	weapon_reloading = true
	reload_timer = RELOAD_DURATION
	shoot_cooldown = maxf(shoot_cooldown, RELOAD_DURATION)
	if status_label != null:
		status_label.text = "RECARGANDO..."
	_update_hud()

func _build_upgrade_panel() -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.name = "UpgradeOverlay"
	upgrade_overlay.position = Vector2.ZERO
	upgrade_overlay.size = WORLD_SIZE
	upgrade_overlay.color = Color(0.005, 0.012, 0.018, 0.0)
	upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrade_overlay.z_index = 5
	# Desenfoque suave del escenario mientras la elección está abierta.
	var blur_shader := Shader.new()
	blur_shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear; void fragment() { vec2 p = SCREEN_PIXEL_SIZE * 2.0; vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0) * 0.36; c += textureLod(screen_texture, SCREEN_UV + vec2(p.x, 0.0), 0.0) * 0.16; c += textureLod(screen_texture, SCREEN_UV - vec2(p.x, 0.0), 0.0) * 0.16; c += textureLod(screen_texture, SCREEN_UV + vec2(0.0, p.y), 0.0) * 0.16; c += textureLod(screen_texture, SCREEN_UV - vec2(0.0, p.y), 0.0) * 0.16; COLOR = vec4(c.rgb * 0.72, 1.0); }"
	var blur_material := ShaderMaterial.new()
	blur_material.shader = blur_shader
	upgrade_overlay.material = blur_material
	hud.add_child(upgrade_overlay)
	upgrade_lightning_flash = ColorRect.new()
	upgrade_lightning_flash.name = "UpgradeLightningFlash"
	upgrade_lightning_flash.position = Vector2.ZERO
	upgrade_lightning_flash.size = WORLD_SIZE
	upgrade_lightning_flash.color = Color(0.65, 0.88, 1.0, 0.0)
	upgrade_lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_lightning_flash.z_index = 7
	hud.add_child(upgrade_lightning_flash)
	upgrade_panel = ColorRect.new()
	upgrade_panel.position = Vector2(235, 125)
	upgrade_panel.size = Vector2(810, 535)
	upgrade_panel.color = Color(0.035, 0.075, 0.1, 0.98)
	upgrade_panel.z_index = 6
	hud.add_child(upgrade_panel)
	upgrade_title = _label(upgrade_panel, "ELIGE UNA MEJORA", Vector2(0, 28), 28, Color("f0bf6d"))
	upgrade_title.size = Vector2(810, 45)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint := _label(upgrade_panel, "La noche se detiene mientras decides", Vector2(0, 68), 15, Color("9db0b3"))
	hint.size = Vector2(810, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_card_textures = {
		"fury": load("res://assets/ui/upgrades/upgrade_fury.png") as Texture2D,
		"speed": load("res://assets/ui/upgrades/upgrade_speed.png") as Texture2D,
		"medkit": load("res://assets/ui/upgrades/upgrade_medkit.png") as Texture2D,
		"heavy": load("res://assets/ui/upgrades/upgrade_heavy.png") as Texture2D,
		"survivor": load("res://assets/ui/upgrades/upgrade_survivor.png") as Texture2D
	}
	for i in range(3):
		var button := Button.new()
		button.position = Vector2(35 + i * 255, 112)
		button.size = Vector2(235, 385)
		button.set_meta("base_position", button.position)
		button.add_theme_font_size_override("font_size", 1)
		button.text = ""
		var art := TextureRect.new()
		art.name = "Art"
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		var shade := ColorRect.new()
		shade.name = "TextShade"
		shade.position = Vector2(8, 277)
		shade.size = Vector2(219, 98)
		shade.color = Color(0.01, 0.025, 0.035, 0.86)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(shade)
		var card_title := Label.new()
		card_title.name = "CardTitle"
		card_title.position = Vector2(16, 286)
		card_title.size = Vector2(203, 28)
		card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_title.add_theme_font_size_override("font_size", 17)
		card_title.add_theme_color_override("font_color", Color("f0bf6d"))
		card_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_title)
		var card_description := Label.new()
		card_description.name = "CardDescription"
		card_description.position = Vector2(16, 316)
		card_description.size = Vector2(203, 50)
		card_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_description.add_theme_font_size_override("font_size", 13)
		card_description.add_theme_color_override("font_color", Color("e1ece9"))
		card_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_description)
		button.pressed.connect(_choose_upgrade.bind(i))
		button.mouse_entered.connect(_on_upgrade_card_hover.bind(button, true))
		button.mouse_exited.connect(_on_upgrade_card_hover.bind(button, false))
		upgrade_panel.add_child(button)
		upgrade_buttons.append(button)
	upgrade_panel.visible = false
	upgrade_overlay.visible = false
	upgrade_confirm_label = _label(hud, "", Vector2(250, 285), 32, Color("f0bf6d"))
	upgrade_confirm_label.size = Vector2(780, 110)
	upgrade_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_confirm_label.z_index = 8
	upgrade_confirm_label.visible = false

func _on_upgrade_card_hover(button: Button, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	button.z_index = 2 if hovered else 0
	var rarity := str(button.get_meta("rarity", "COMÚN"))
	if hovered:
		_spawn_burst(player_pos, _rarity_color(rarity), 6)
		if is_instance_valid(audio_manager):
			audio_manager.call("play_card_hover", str(button.get_meta("upgrade_id", "survivor")), rarity)
	button.modulate = Color(1.10, 1.10, 1.10, 1.0) if hovered else Color.WHITE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * (1.10 if hovered else 1.0), 0.16)

func _style_upgrade_card(button: Button, rarity: String) -> void:
	button.set_meta("rarity", rarity)
	var accent := _rarity_color(rarity)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.015, 0.025, 0.035, 0.92)
	normal.border_color = Color(accent, 0.92)
	normal.set_border_width_all(3 if rarity != "COMÚN" else 2)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color(accent, 0.42 if rarity != "COMÚN" else 0.18)
	normal.shadow_size = 12 if rarity != "COMÚN" else 5
	var hover := normal.duplicate()
	hover.border_color = Color(accent, 1.0)
	hover.set_border_width_all(5)
	hover.shadow_color = Color(accent, 0.8)
	hover.shadow_size = 22
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)

func _play_upgrade_sound(upgrade_id: String, event_name: String, rarity: String) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.call("play_upgrade_sound", upgrade_id, rarity, event_name)

func _apply_camera_shake() -> void:
	if world_camera == null or not world_camera.enabled:
		return
	if camera_shake_timer > 0.0:
		var falloff := clampf(camera_shake_timer / 0.30, 0.0, 1.0)
		world_camera.position = player_pos + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * camera_shake_strength * falloff

func _shake_camera(duration: float = 0.30, strength: float = 10.0) -> void:
	camera_shake_timer = maxf(camera_shake_timer, duration)
	camera_shake_strength = maxf(camera_shake_strength, strength)

func _label(parent: Node, text_value: String, pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _style_menu_button(button: Button, accent: Color, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("e9f4f1"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.08, 0.1, 0.9)
	normal.border_color = Color(accent, 0.72)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(accent, 0.28)
	hover.border_color = Color(accent, 1.0)
	hover.set_border_width_all(3)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(accent, 0.45)
	pressed.border_color = Color("effffb")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.mouse_entered.connect(_on_ui_button_hover)
	button.pressed.connect(_on_ui_button_pressed)

func _on_ui_button_hover() -> void:
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "hover")

func _on_ui_button_pressed() -> void:
	if is_instance_valid(audio_manager):
		audio_manager.call("play_ui_event", "press")

func _build_props() -> void:
	_build_city_tilemap()
	return

func _build_city_tilemap() -> void:
	for old_prop in props:
		var old_node = old_prop.get("node")
		if is_instance_valid(old_node):
			old_node.queue_free()
	props.clear()
	if is_instance_valid(world_tilemap):
		world_tilemap.queue_free()
	if is_instance_valid(world_decor_layer):
		world_decor_layer.queue_free()
	if is_instance_valid(world_backdrop):
		world_backdrop.queue_free()
	var backdrop_texture: Texture2D = load("res://assets/world/urban_city_backdrop.png") as Texture2D
	if backdrop_texture != null:
		world_backdrop = Sprite2D.new()
		world_backdrop.name = "UrbanCityBackdrop"
		world_backdrop.texture = backdrop_texture
		world_backdrop.position = Vector2(640, 405)
		world_backdrop.scale = Vector2(0.714, 0.714)
		world_backdrop.z_index = -20
		world_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(world_backdrop)
		move_child(world_backdrop, 0)
	var urban_texture: Texture2D = load("res://assets/world/urban_apocalypse_tileset_clean.png") as Texture2D
	if urban_texture == null:
		urban_texture = load("res://assets/world/urban_apocalypse_tileset.png") as Texture2D
	if urban_texture == null:
		return
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(128, 128)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = urban_texture
	atlas.texture_region_size = Vector2i(128, 128)
	for y in range(8):
		for x in range(8):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, 0)
	world_tilemap = TileMapLayer.new()
	world_tilemap.name = "UrbanGroundTileMap"
	world_tilemap.position = Vector2(0, 120)
	world_tilemap.z_index = -15
	world_tilemap.visible = false
	world_tilemap.tile_set = tile_set
	add_child(world_tilemap)
	move_child(world_tilemap, 1)
	# Base de asfalto agrietado. Usamos una baldosa neutra para que las
	# marcas de carril solo aparezcan en la carretera principal.
	for y in range(5):
		for x in range(10):
			world_tilemap.set_cell(Vector2i(x, y), 0, Vector2i(7, 3))
	# Aceras perimetrales y pocas zonas verdes para mantener una lectura limpia.
	for x in range(10):
		world_tilemap.set_cell(Vector2i(x, 0), 0, Vector2i(1, 1))
		world_tilemap.set_cell(Vector2i(x, 4), 0, Vector2i(0, 1))
	for cell in [Vector2i(0, 1), Vector2i(0, 3), Vector2i(9, 1), Vector2i(9, 3)]:
		world_tilemap.set_cell(cell, 0, Vector2i(0, 2))
	# Carretera principal diagonal de un solo carril visual. El asfalto de la
	# base queda visible alrededor para evitar un mosaico saturado.
	var road_tiles := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	for x in range(1, 9):
		var center_y := clampi(3 - int(round(float(x) * 0.25)), 1, 3)
		var road_tile: Vector2i = road_tiles[x % road_tiles.size()]
		world_tilemap.set_cell(Vector2i(x, center_y), 0, road_tile)

	world_decor_layer = TileMapLayer.new()
	world_decor_layer.name = "UrbanDecorSprites"
	world_decor_layer.position = Vector2(0, 120)
	world_decor_layer.z_index = -14
	world_decor_layer.visible = false
	world_decor_layer.tile_set = tile_set
	add_child(world_decor_layer)
	move_child(world_decor_layer, 2)
	var decorations := [
		{"cell": Vector2i(1, 1), "tile": Vector2i(1, 4), "kind": "car", "health": 120.0, "size": Vector2(72, 62), "explosive": true},
		{"cell": Vector2i(7, 1), "tile": Vector2i(2, 4), "kind": "car", "health": 120.0, "size": Vector2(72, 62), "explosive": true},
		{"cell": Vector2i(4, 3), "tile": Vector2i(5, 4), "kind": "bus", "health": 260.0, "size": Vector2(116, 70), "explosive": true},
		{"cell": Vector2i(8, 3), "tile": Vector2i(7, 4), "kind": "bus", "health": 260.0, "size": Vector2(105, 70), "explosive": true},
		{"cell": Vector2i(2, 0), "tile": Vector2i(0, 5), "kind": "barricade", "health": 80.0, "size": Vector2(90, 36), "explosive": false},
		{"cell": Vector2i(6, 4), "tile": Vector2i(1, 5), "kind": "barricade", "health": 80.0, "size": Vector2(90, 36), "explosive": false},
		{"cell": Vector2i(0, 1), "tile": Vector2i(3, 6), "kind": "tree", "health": 90.0, "size": Vector2(70, 70), "explosive": false},
		{"cell": Vector2i(9, 1), "tile": Vector2i(4, 6), "kind": "tree", "health": 90.0, "size": Vector2(70, 70), "explosive": false},
		{"cell": Vector2i(9, 0), "tile": Vector2i(7, 7), "kind": "bus_stop", "health": 180.0, "size": Vector2(96, 80), "explosive": false},
		{"cell": Vector2i(0, 4), "tile": Vector2i(0, 6), "kind": "lamp", "health": 55.0, "size": Vector2(34, 68), "explosive": false}
	]
	for decoration in decorations:
		var cell: Vector2i = decoration["cell"]
		world_decor_layer.set_cell(cell, 0, decoration["tile"])
		var position := Vector2(cell.x * 128.0 + 64.0, 120.0 + cell.y * 128.0 + 64.0)
		var object = DESTRUCTIBLE_OBJECT_SCRIPT.new()
		object.position = position
		object.setup(str(decoration["kind"]), float(decoration["health"]), Vector2(decoration["size"]), bool(decoration["explosive"]))
		object.destroyed.connect(_on_city_object_destroyed.bind(cell))
		object.damaged.connect(_on_prop_damaged)
		add_child(object)
		var obstacle := NavigationObstacle2D.new()
		obstacle.name = "NavigationObstacle"
		obstacle.avoidance_enabled = true
		var decoration_size: Vector2 = Vector2(decoration["size"])
		obstacle.radius = maxf(decoration_size.x, decoration_size.y) * 0.5
		object.add_child(obstacle)
		props.append({"pos": position, "type": 0, "size": 1.0, "node": object, "kind": decoration["kind"], "cell": cell})
	_build_city_navigation()

func _on_city_object_destroyed(object, cell: Vector2i) -> void:
	if is_instance_valid(world_decor_layer):
		world_decor_layer.erase_cell(cell)
	_on_prop_destroyed(object)

func _build_city_navigation() -> void:
	if navigation_region != null and is_instance_valid(navigation_region):
		navigation_region.queue_free()
	navigation_region = NavigationRegion2D.new()
	navigation_region.name = "UrbanNavigationRegion"
	var navigation_polygon := NavigationPolygon.new()
	navigation_polygon.vertices = PackedVector2Array([
		Vector2(24, 126), Vector2(1256, 126), Vector2(1256, 704), Vector2(24, 704)
	])
	navigation_polygon.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	navigation_region.navigation_polygon = navigation_polygon
	add_child(navigation_region)
	move_child(navigation_region, 0)
	_build_road_spawn_points()

func _build_road_spawn_points() -> void:
	for child in get_children():
		if child.name.begins_with("RoadSpawnPoint"):
			child.queue_free()
	road_spawn_points.clear()
	# Puntos fuera de la pantalla, en la entrada superior de la carretera.
	# La ruta desciende desde la ciudad del fondo hacia el centro del mapa.
	road_spawn_points = [Vector2(1010, 72), Vector2(1085, 60), Vector2(1160, 48)]
	road_waypoints = [Vector2(970, 150), Vector2(880, 235), Vector2(780, 315), Vector2(690, 370)]
	for i in range(road_spawn_points.size()):
		var spawn_point := Node2D.new()
		spawn_point.name = "RoadSpawnPoint_%02d" % (i + 1)
		spawn_point.position = road_spawn_points[i]
		spawn_point.set_meta("route", "main_road")
		add_child(spawn_point)

func _build_world_parallax() -> void:
	world_parallax = ParallaxBackground.new()
	world_parallax.name = "WorldParallax"
	world_parallax.scroll_ignore_camera_zoom = true
	add_child(world_parallax)
	move_child(world_parallax, 0)
	# El escenario jugable lo dibuja UrbanGroundTileMap. Las capas parallax
	# solo contienen atmósfera y no reutilizan el fondo del menú.
	var mid_layer := ParallaxLayer.new()
	mid_layer.name = "SmokeAndStructuresLayer"
	mid_layer.motion_scale = Vector2(0.22, 0.12)
	var mid_atmosphere := WORLD_ATMOSPHERE_SCRIPT.new()
	mid_atmosphere.layer_kind = "mid"
	mid_layer.add_child(mid_atmosphere)
	world_parallax.add_child(mid_layer)
	var front_layer := ParallaxLayer.new()
	front_layer.name = "FogAndVegetationLayer"
	front_layer.motion_scale = Vector2(0.55, 0.3)
	var front_atmosphere := WORLD_ATMOSPHERE_SCRIPT.new()
	front_atmosphere.layer_kind = "front"
	front_layer.add_child(front_atmosphere)
	world_parallax.add_child(front_layer)
	var weather_layer := ParallaxLayer.new()
	weather_layer.name = "RainAndAshLayer"
	weather_layer.motion_scale = Vector2(0.9, 0.65)
	var weather := WORLD_ATMOSPHERE_SCRIPT.new()
	weather.layer_kind = "weather"
	weather_layer.add_child(weather)
	world_parallax.add_child(weather_layer)
	world_parallax.visible = false

func _build_world_camera() -> void:
	world_camera = Camera2D.new()
	world_camera.name = "WorldCamera"
	world_camera.position = player_pos
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 5.5
	world_camera.limit_left = 0
	world_camera.limit_top = 120
	world_camera.limit_right = 1280
	world_camera.limit_bottom = 720
	world_camera.limit_smoothed = true
	world_camera.enabled = false
	add_child(world_camera)

func _is_free_prop_position(position: Vector2, object_size: Vector2) -> bool:
	var candidate := Rect2(position - object_size * 0.5 - Vector2(12, 12), object_size + Vector2(24, 24))
	for prop in props:
		var other = prop.get("node")
		if is_instance_valid(other) and candidate.intersects(other.collision_rect()):
			return false
	return true

func _on_prop_damaged(_object, _ratio: float) -> void:
	_spawn_burst(_object.global_position, Color("d8a46d"), 3)
	queue_redraw()

func _on_prop_destroyed(object) -> void:
	var was_explosive := bool(object.explosive)
	_spawn_burst(object.global_position, Color("a9a39a"), 18 if was_explosive else 10)
	_spawn_burst(object.global_position, Color("6f4b36"), 10)
	if was_explosive:
		_explode_vehicle(object.global_position)
	queue_redraw()

func _explode_vehicle(center: Vector2) -> void:
	flash_timer = 0.35
	for i in range(zombies.size() - 1, -1, -1):
		var zombie: Dictionary = zombies[i]
		var distance := center.distance_to(zombie["pos"])
		if distance < 145.0:
			var zombie_node = zombie.get("node")
			if is_instance_valid(zombie_node) and not zombie_node.is_dead:
				zombie_node.take_damage(65.0)
				zombie["pos"] += center.direction_to(zombie["pos"]) * (145.0 - distance) * 0.7
				zombies[i] = zombie

func _build_player_sprite_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	# Layout of the compact directional atlas (384x320, cells of 64x64):
	# row 0 = walk_up (6), row 1 = walk_down (6), row 2 = walk_left (5),
	# row 3 = walk_right (5), row 4 = death (6).
	# The final column of the left/right rows is transparent by design.
	var definitions := {
		"walk_up": {"row": 0, "count": 6, "fps": 9.0, "loop": true},
		"walk_down": {"row": 1, "count": 6, "fps": 9.0, "loop": true},
		"walk_right": {"row": 3, "count": 5, "fps": 9.0, "loop": true},
		"walk_left": {"row": 2, "count": 5, "fps": 9.0, "loop": true},
		"idle_up": {"row": 0, "count": 1, "fps": 1.0, "loop": false},
		"idle_down": {"row": 1, "count": 1, "fps": 1.0, "loop": false},
		"idle_right": {"row": 3, "count": 1, "fps": 1.0, "loop": false},
		"idle_left": {"row": 2, "count": 1, "fps": 1.0, "loop": false},
		# No attack row exists in this compact atlas. Keep attacks directional
		# and stable by reusing that direction's walk frames until an attack row
		# is supplied.
		"attack_up": {"row": 0, "count": 6, "fps": 12.0, "loop": false},
		"attack_down": {"row": 1, "count": 6, "fps": 12.0, "loop": false},
		"attack_right": {"row": 3, "count": 5, "fps": 12.0, "loop": false},
		"attack_left": {"row": 2, "count": 5, "fps": 12.0, "loop": false},
		"death": {"row": 4, "count": 6, "fps": 8.0, "loop": false}
	}
	for animation_name in definitions:
		var definition: Dictionary = definitions[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(definition["fps"]))
		frames.set_animation_loop(animation_name, bool(definition["loop"]))
		var count: int = int(definition["count"])
		var row: int = int(definition["row"])
		for frame_index in range(count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(frame_index * 64, row * 64, 64, 64)
			frames.add_frame(animation_name, atlas)
	return frames

func _direction_animation_suffix() -> String:
	if absf(player_facing.x) < 0.38:
		return "down" if player_facing.y >= 0.0 else "up"
	if absf(player_facing.y) < 0.38:
		return "right" if player_facing.x >= 0.0 else "left"
	return "right" if player_facing.x >= 0.0 else "left"

func _configure_player_sprite() -> void:
	if player_sprite == null or selected_character < 0:
		return
	var texture: Texture2D = null
	if selected_character < survivor_directional_sheets.size():
		texture = survivor_directional_sheets[selected_character]
	if texture == null:
		return
	player_sprite.sprite_frames = _build_player_sprite_frames(texture)
	player_sprite.animation = "idle_down"
	player_sprite.frame = 0
	player_sprite.flip_h = false
	player_sprite.visible = true

func _update_player_sprite() -> void:
	if player_sprite == null or player_dead:
		return
	player_sprite.position = player_pos
	var suffix := _direction_animation_suffix()
	var animation_name := "idle_" + suffix
	if Input.is_action_pressed("shoot") or touch_shoot_pressed:
		animation_name = "attack_" + suffix
	elif player_moving:
		animation_name = ("run_" + suffix) if Input.is_key_pressed(KEY_SHIFT) else ("walk_" + suffix)
	# The compact stable atlas has no separate run rows; walk is deliberately used
	# for run until a dedicated run atlas is supplied.
	if animation_name.begins_with("run_"):
		animation_name = "walk_" + suffix
	# The directional atlas already contains separate left/right frames.
	# Flipping the left row would turn the survivor around and make it look
	# like it is walking backwards.
	player_sprite.flip_h = false
	if player_sprite.animation != animation_name:
		player_sprite.play(animation_name)
	elif not player_sprite.is_playing() and not animation_name.begins_with("idle_"):
		player_sprite.play(animation_name)

func _start_game() -> void:
	if selected_character < 0 or selected_character >= character_data_list.size():
		selection_message.text = "Selecciona un personaje"
		selection_message.visible = true
		return
	username = name_input.text.strip_edges()
	if username.is_empty():
		selection_message.text = "Escribe tu nombre"
		selection_message.visible = true
		name_input.grab_focus()
		return
	menu_message.visible = false
	_play_scene_transition(Callable(self, "_start_game_after_transition"), "ENTRANDO EN LA NOCHE...")
	# Respaldo para Web y algunos drivers gráficos: si el Tween no entrega
	# el callback, la partida no puede quedarse bloqueada en el menú.
	await get_tree().create_timer(1.25).timeout
	if mode == "menu":
		_start_game_after_transition()

func _start_game_after_transition() -> void:
	if mode == "playing":
		return
	if is_instance_valid(audio_manager):
		audio_manager.call("stop_loading_ambience")
		audio_manager.call("fade_out_menu_music", 0.35)
		audio_manager.call("play_game_event", "start_game")
	if selected_character < 0 or selected_character >= character_data_list.size():
		selection_message.text = "Selecciona un personaje"
		selection_message.visible = true
		return
	username = name_input.text.strip_edges()
	if username.is_empty():
		selection_message.text = "Escribe tu nombre"
		selection_message.visible = true
		name_input.grab_focus()
		return
	menu_message.visible = false
	var player_stats := _normalize_record(records.get(username, {}))
	player_stats["plays"] = int(player_stats["plays"]) + 1
	records[username] = player_stats
	_write_records()
	mode = "playing"
	var menu_layer := get_node_or_null("MenuLayer") as CanvasLayer
	if menu_layer != null:
		menu_layer.visible = false
	touch_move = Vector2.ZERO
	touch_shoot_pressed = false
	weapon_reloading = false
	reload_timer = 0.0
	ammo_in_magazine = MAGAZINE_SIZE
	player_moving = false
	player_facing = Vector2.DOWN
	player_dead = false
	score = 0
	kills = 0
	combo = 0
	lives = 3
	damage_cooldown = 0.0
	spawn_protection = 3.0
	player_speed = character_data_list[selected_character].speed
	player_base_speed = player_speed
	score_multiplier = 1.0
	projectile_speed_multiplier = 1.0
	fire_rate_multiplier = 1.0
	bullet_size_multiplier = 1.0
	protection_timer = 0.0
	phase_timer = 0.0
	upgrade_levels.clear()
	evolution_unlocked.clear()
	evolution_acquired.clear()
	upgrade_timer = 0.0
	upgrade_pending = false
	wave = 1
	spawn_serial = 0
	_build_props()
	wave_timer = 0.0
	spawn_timer = 0.0
	game_time = 0.0
	weather = "soleado"
	next_weather_wave = rng.randi_range(3, 4)
	weather_darkness = 0.0
	weather_visibility = 1.0
	weather_rain_strength = 0.0
	weather_fog_strength = 0.0
	weather_lightning_strength = 0.0
	weather_lightning_timer = 0.0
	_set_weather("soleado", false)
	player_pos = Vector2(640, 405)
	_configure_player_sprite()
	bullets.clear()
	for old_zombie in zombies:
		var old_node = old_zombie.get("node")
		if is_instance_valid(old_node):
			old_node.queue_free()
	zombies.clear()
	particles.clear()
	hud.visible = true
	game_over_label.visible = false
	if world_parallax != null:
		world_parallax.visible = true
	if world_camera != null:
		world_camera.position = player_pos
		world_camera.enabled = true
	if bestiary != null:
		bestiary.visible = false
	upgrade_panel.visible = false
	_spawn_wave()
	_update_hud()

func _update_game(delta: float) -> void:
	if player_dead:
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_move.length_squared() > 0.01:
		movement = touch_move
	player_moving = movement.length_squared() > 0.01
	if player_moving:
		player_facing = movement.normalized()
	var intended_player_pos := player_pos + movement * player_speed * _weather_player_speed() * delta
	player_pos = _move_with_obstacles(player_pos, intended_player_pos, 18.0)
	player_pos.x = clampf(player_pos.x, 34.0, 1246.0)
	player_pos.y = clampf(player_pos.y, 126.0, 690.0)
	if world_camera != null and world_camera.enabled:
		world_camera.position = player_pos
	if touch_shoot_pressed:
		aim_pos = _get_touch_aim_position()
	else:
		var mouse_position := get_global_mouse_position()
		aim_pos = player_pos + (mouse_position - player_pos) * mouse_sensitivity
	if Input.is_action_just_pressed("reload"):
		_reload_weapon()
	if Input.is_action_just_pressed("shoot") or touch_shoot_pressed:
		_shoot()
	_update_bullets(delta)
	_update_zombies(delta)
	_update_particles(delta)
	upgrade_timer += delta
	if upgrade_timer >= UPGRADE_INTERVAL:
		_show_upgrade_choices()
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0 and zombies.size() < 15 + wave * 3:
		_spawn_zombie()
		spawn_timer = maxf(0.18, 0.65 - wave * 0.035)
	wave_timer += delta
	if wave_timer >= 28.0:
		wave += 1
		wave_timer = 0.0
		combo = 0
		_maybe_change_weather(true)
		_build_props()
		_spawn_wave()
	_update_hud()

func _get_touch_aim_position() -> Vector2:
	var closest_position := player_pos + player_facing * 100.0
	var closest_distance := INF
	for zombie in zombies:
		var zombie_position: Vector2 = zombie.get("pos", closest_position)
		var distance := player_pos.distance_squared_to(zombie_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_position = zombie_position
	return closest_position

func _shoot() -> void:
	if weapon_reloading:
		return
	if ammo_in_magazine <= 0:
		if status_label != null:
			status_label.text = "SIN MUNICIÓN · PULSA R"
		return
	if shoot_cooldown > 0.0:
		return
	var direction := player_pos.direction_to(aim_pos)
	if direction.length() < 0.1:
		return
	bullets.append({"pos": player_pos + direction * 24.0, "vel": direction * 820.0 * projectile_speed_multiplier, "life": 0.9, "radius": 8.0 * bullet_size_multiplier})
	shoot_cooldown = 0.12 / maxf(1.0, fire_rate_multiplier)
	ammo_in_magazine -= 1
	if ammo_in_magazine <= 0 and status_label != null:
		status_label.text = "SIN MUNICIÓN · PULSA R"
	_update_hud()
	flash_timer = 0.08
	if is_instance_valid(audio_manager):
		audio_manager.call("play_game_event", "shoot")

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet["pos"] = bullet["pos"] + bullet["vel"] * delta
		bullet["life"] = float(bullet["life"]) - delta
		var remove: bool = bullet["life"] <= 0.0 or not Rect2(0, 120, 1280, 600).has_point(bullet["pos"])
		if not remove:
			for prop in props:
				var prop_node = prop.get("node")
				if is_instance_valid(prop_node) and not prop_node.destroyed_state and prop_node.collision_rect().grow(4.0).has_point(bullet["pos"]):
					prop_node.take_damage(25.0 * score_multiplier)
					_spawn_burst(bullet["pos"], Color("f0bf6d"), 4)
					if is_instance_valid(audio_manager):
						audio_manager.call("play_game_event", "impact")
					remove = true
					break
		if not remove:
			for j in range(zombies.size() - 1, -1, -1):
				var zombie: Dictionary = zombies[j]
				var zombie_node = zombie.get("node")
				if is_instance_valid(zombie_node) and not zombie_node.is_dead and bullet["pos"].distance_to(zombie["pos"]) < float(zombie["radius"]) + float(bullet.get("radius", 8.0)):
					zombie_node.take_damage(25.0 * score_multiplier)
					if is_instance_valid(audio_manager):
						audio_manager.call("play_game_event", "zombie_hit")
					remove = true
					break
		if remove:
			bullets.remove_at(i)
		else:
			bullets[i] = bullet

func _update_zombies(delta: float) -> void:
	for i in range(zombies.size() - 1, -1, -1):
		var zombie: Dictionary = zombies[i]
		var zombie_node = zombie.get("node")
		if not is_instance_valid(zombie_node) or zombie_node.is_dead:
			continue
		var distance: float = zombie["pos"].distance_to(player_pos)
		var speed := float(zombie["speed"]) * (1.0 + wave * 0.035) * _weather_zombie_speed()
		var route_target := player_pos
		var route_index := int(zombie.get("road_target_index", -1))
		if route_index >= 0 and route_index < road_waypoints.size():
			route_target = road_waypoints[route_index]
			if zombie["pos"].distance_to(route_target) < 34.0:
				route_index += 1
				zombie["road_target_index"] = route_index if route_index < road_waypoints.size() else -1
				route_target = road_waypoints[route_index] if route_index < road_waypoints.size() else player_pos
		var desired := _steer_around_obstacles(zombie["pos"], zombie["pos"].direction_to(route_target))
		zombie_node.set_navigation_target(route_target)
		desired = zombie_node.navigation_direction(desired)
		desired = _steer_around_obstacles(zombie["pos"], desired)
		var next_zombie_pos: Vector2 = zombie["pos"] + desired * speed * delta
		zombie["pos"] = _move_with_obstacles(zombie["pos"], next_zombie_pos, float(zombie["radius"]) * 0.72)
		zombie["phase"] = float(zombie["phase"]) + delta * 5.0
		zombie_node.position = zombie["pos"]
		if distance < 30.0 and spawn_protection <= 0.0 and protection_timer <= 0.0 and phase_timer <= 0.0:
			if damage_cooldown > 0.0:
				continue
			lives -= 1
			var attack_multiplier := float(zombie.get("attack_multiplier", 1.0))
			# La noche aumenta el daño efectivo: el contacto vuelve antes a ser peligroso
			# y aplica una penalización de puntuación ligeramente mayor.
			damage_cooldown = maxf(0.55, 1.0 / attack_multiplier)
			score = maxi(0, score - int(25.0 * attack_multiplier))
			combo = 0
			_spawn_burst(player_pos, Color("e0b17a"), 8)
			if is_instance_valid(audio_manager):
				audio_manager.call("play_game_event", "player_damage")
			if lives <= 0:
				_end_game()
				return
			# El zombie sigue vivo tras golpear al jugador: se separa para que
			# permanezca visible y pueda volver a perseguirlo.
			var push_direction := player_pos.direction_to(zombie["pos"])
			if push_direction.length_squared() < 0.01:
				push_direction = Vector2.UP
			zombie["pos"] = player_pos + push_direction * 58.0
			zombie_node.position = zombie["pos"]
			zombies[i] = zombie
		else:
			zombies[i] = zombie

func _move_with_obstacles(from: Vector2, target: Vector2, radius: float) -> Vector2:
	var result := target
	for prop in props:
		var object = prop.get("node")
		if not is_instance_valid(object) or object.destroyed_state:
			continue
		var rect: Rect2 = object.collision_rect().grow(radius)
		if rect.has_point(result):
			var left_distance := absf(result.x - rect.position.x)
			var right_distance := absf(rect.end.x - result.x)
			var top_distance := absf(result.y - rect.position.y)
			var bottom_distance := absf(rect.end.y - result.y)
			var smallest := minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
			if smallest == left_distance:
				result.x = rect.position.x
			elif smallest == right_distance:
				result.x = rect.end.x
			elif smallest == top_distance:
				result.y = rect.position.y
			else:
				result.y = rect.end.y
	return result

func _steer_around_obstacles(position: Vector2, desired: Vector2) -> Vector2:
	var result := desired
	for prop in props:
		var object = prop.get("node")
		if not is_instance_valid(object) or object.destroyed_state:
			continue
		var rect: Rect2 = object.collision_rect().grow(38.0)
		if rect.has_point(position + desired * 48.0):
			var to_left := Vector2(-desired.y, desired.x)
			var to_right := -to_left
			var left_score := rect.get_center().distance_to(position + to_left * 55.0)
			var right_score := rect.get_center().distance_to(position + to_right * 55.0)
			result = (to_left if left_score > right_score else to_right).lerp(desired, 0.35).normalized()
	return result

func _on_zombie_died(zombie_node) -> void:
	for i in range(zombies.size() - 1, -1, -1):
		var zombie: Dictionary = zombies[i]
		if zombie.get("node") != zombie_node:
			continue
		var pos: Vector2 = zombie["pos"]
		var value := int((100 + wave * 25 + combo * 10) * score_multiplier)
		combo += 1
		kills += 1
		score += value
		_spawn_burst(pos, Color("bb2938"), 16)
		_spawn_burst(pos, Color("f0bf6d"), 4)
		if is_instance_valid(audio_manager):
			audio_manager.call("play_game_event", "zombie_death")
		_unlock_enemy_type(int(zombie["type"]))
		zombies.remove_at(i)
		return

func _unlock_enemy_type(enemy_index: int) -> void:
	if enemy_index >= 0 and enemy_index < enemy_data_list.size():
		_on_enemy_discovered(enemy_data_list[enemy_index])

func _spawn_wave() -> void:
	for i in range(3 + wave * 2):
		_spawn_zombie()
	status_label.text = "OLEADA %d: LA NOCHE EMPEORA" % wave
	if is_instance_valid(audio_manager):
		audio_manager.call("play_game_event", "wave")

func _spawn_zombie() -> void:
	if road_spawn_points.is_empty():
		_build_road_spawn_points()
	var spawn_index := spawn_serial % road_spawn_points.size()
	spawn_serial += 1
	var p := road_spawn_points[spawn_index] + Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-8.0, 8.0))
	var zombie_type := rng.randi_range(0, enemy_data_list.size() - 1)
	var data = enemy_data_list[zombie_type]
	var night_bonus := _night_bonus_for_enemy(data)
	var zombie_node = zombie_scene.instantiate() if zombie_scene != null else null
	if zombie_node == null:
		return
	zombie_node.setup(data)
	if night_bonus > 0.0:
		var night_health := float(data.max_health) * (1.0 + night_bonus)
		zombie_node.current_health = night_health
		if zombie_node.health_bar != null:
			zombie_node.health_bar.max_value = night_health
			zombie_node.health_bar.value = night_health
	zombie_node.position = p
	zombie_node.died.connect(_on_zombie_died)
	add_child(zombie_node)
	var spawn_pos := p
	if weather == "niebla":
		# En niebla entran algo más cerca, pero siguen llegando por la carretera.
		spawn_pos = p.lerp(player_pos, 0.12)
		zombie_node.position = spawn_pos
	zombies.append({"pos": spawn_pos, "speed": data.speed, "radius": rng.randf_range(17.0, 24.0), "phase": rng.randf_range(0.0, 6.0), "type": zombie_type, "node": zombie_node, "data": data, "road_target_index": 0, "attack_multiplier": 1.0 + night_bonus})

func _spawn_burst(pos: Vector2, color: Color, amount: int) -> void:
	for i in range(amount):
		particles.append({"pos": pos, "vel": Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(35, 170), "life": rng.randf_range(0.25, 0.75), "color": color, "size": rng.randf_range(2.0, 6.0)})
	if particles.size() > MAX_PARTICLES:
		particles = particles.slice(particles.size() - MAX_PARTICLES)

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle["pos"] += particle["vel"] * delta
		particle["vel"] *= 0.92
		particle["life"] = float(particle["life"]) - delta
		if particle["life"] <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = particle

func _update_hud() -> void:
	score_label.text = "PUNTOS  %06d" % score
	wave_label.text = "OLEADA  %02d" % wave
	record_label.text = "RECORD  %06d" % int(_normalize_record(records.get(username, {}))["score"])
	if ammo_label != null:
		ammo_label.text = "MUNICIÓN  %02d/%02d" % [ammo_in_magazine, MAGAZINE_SIZE]
		ammo_label.modulate = Color("e85b63") if ammo_in_magazine == 0 else Color("f0bf6d")
	# Iconos SVG para que las vidas se vean igual en escritorio y Web.
	lives_label.text = "VIDAS"
	for i in range(life_icons.size()):
		life_icons[i].modulate = Color.WHITE if i < lives else Color(0.22, 0.25, 0.28, 0.85)
	if combo > 1:
		status_label.text = "COMBO x%d   +%d" % [combo, combo * 10]

func _roll_upgrade_rarity(base: Dictionary, allow_legendary: bool = true) -> Dictionary:
	var result: Dictionary = base.duplicate()
	var roll := rng.randf()
	var rarity := "COMÚN"
	if allow_legendary and roll < 0.03:
		rarity = "LEGENDARIA"
	elif roll < (0.15 if allow_legendary else 0.12):
		rarity = "ÉPICA"
	elif roll < (0.40 if allow_legendary else 0.37):
		rarity = "RARA"
	result["rarity"] = rarity
	if rarity == "LEGENDARIA":
		var legendary_names := {
			"fury": "FURIA SANGRIENTA",
			"speed": "CORREDOR FANTASMA",
			"medkit": "BLINDAJE MILITAR",
			"heavy": "MUNICIÓN DEVASTADORA",
			"survivor": "ÚLTIMO SUPERVIVIENTE"
		}
		result["title"] = legendary_names.get(str(result["id"]), result["title"])
	return result

func _upgrade_is_available(upgrade_id: String) -> bool:
	if not UPGRADE_MAX_LEVELS.has(upgrade_id):
		return false
	if upgrade_id == "medkit":
		return lives < 3 and int(upgrade_levels.get(upgrade_id, 0)) < int(UPGRADE_MAX_LEVELS[upgrade_id])
	return int(upgrade_levels.get(upgrade_id, 0)) < int(UPGRADE_MAX_LEVELS[upgrade_id])

func _unlock_evolution(upgrade_id: String) -> void:
	if UPGRADE_EVOLUTIONS.has(upgrade_id):
		evolution_unlocked[upgrade_id] = true

func _show_upgrade_choices() -> void:
	upgrade_timer = 0.0
	upgrade_pending = true
	mode = "upgrade"
	var pool: Array[Dictionary] = [
		{"id": "fury", "title": "FURIA", "description": "+25% puntos por baja"},
		{"id": "speed", "title": "PASO LIGERO", "description": "+18% velocidad de movimiento"},
		{"id": "medkit", "title": "BOTIQUÍN", "description": "+1 vida (máximo 3)"},
		{"id": "heavy", "title": "BALAS PESADAS", "description": "+30% velocidad de bala"},
		{"id": "survivor", "title": "SUPERVIVIENTE", "description": "Protección durante 3 segundos"}
	]
	var available_pool: Array[Dictionary] = []
	for base_upgrade in pool:
		if _upgrade_is_available(str(base_upgrade["id"])):
			var remaining := int(UPGRADE_MAX_LEVELS[str(base_upgrade["id"])]) - int(upgrade_levels.get(str(base_upgrade["id"]), 0))
			# Las mejoras con mas recorrido tienen mas peso; las casi maximizadas aparecen menos.
			for repeat in range(maxi(1, remaining)):
				available_pool.append(base_upgrade)
		# Una evolucion se ofrece solo de forma muy rara: 5% por oferta.
		var evolution: Dictionary = UPGRADE_EVOLUTIONS.get(str(base_upgrade["id"]), {})
		if not evolution.is_empty() and evolution_unlocked.get(str(base_upgrade["id"]), false) and not evolution_acquired.get(str(evolution["id"]), false) and rng.randf() < 0.05:
			available_pool.append({"id": evolution["id"], "base_id": base_upgrade["id"], "title": evolution["title"], "description": "EVOLUCIÓN · no mejorable", "rarity": "LEGENDARIA", "evolution": true})
	if available_pool.is_empty():
		upgrade_pending = false
		mode = "playing"
		status_label.text = "TODAS LAS MEJORAS ESTÁN AL MÁXIMO"
		return
	upgrade_options.clear()
	var has_legendary := false
	var attempts := 0
	while upgrade_options.size() < mini(3, available_pool.size()) and attempts < 100:
		attempts += 1
		var candidate: Dictionary = available_pool[rng.randi_range(0, available_pool.size() - 1)].duplicate()
		if not bool(candidate.get("evolution", false)):
			candidate = _roll_upgrade_rarity(candidate, not has_legendary)
		var candidate_rarity := str(candidate["rarity"])
		# Una legendaria fuerza que las otras cartas sean como maximo Raras.
		# Tambien impide que aparezcan dos legendarias en la misma oferta.
		if has_legendary and candidate_rarity == "ÉPICA":
			continue
		if candidate_rarity == "LEGENDARIA":
			var incompatible := false
			for previous in upgrade_options:
				if str(previous["rarity"]) == "ÉPICA" or str(previous["rarity"]) == "LEGENDARIA":
					incompatible = true
					break
			if incompatible:
				continue
			has_legendary = true
		var already_used := false
		for option in upgrade_options:
			if option["id"] == candidate["id"]:
				already_used = true
		if not already_used:
			upgrade_options.append(candidate)
	for i in range(upgrade_buttons.size()):
		upgrade_buttons[i].visible = i < upgrade_options.size()
		upgrade_buttons[i].disabled = i >= upgrade_options.size()
	if is_instance_valid(audio_manager):
		audio_manager.call("play_card_spawn")
	for i in range(upgrade_options.size()):
		var option: Dictionary = upgrade_options[i]
		var card: Button = upgrade_buttons[i]
		var art: TextureRect = card.get_node("Art")
		art.texture = upgrade_card_textures.get(option.get("base_id", option["id"]))
		card.get_node("CardTitle").text = "%s · %s" % [option["title"], option["rarity"]]
		card.get_node("CardTitle").add_theme_color_override("font_color", _rarity_color(str(option["rarity"])))
		var base_id := str(option.get("base_id", option["id"]))
		card.set_meta("upgrade_id", base_id)
		var current_level := int(upgrade_levels.get(base_id, 0))
		var max_level := int(UPGRADE_MAX_LEVELS.get(base_id, MAX_UPGRADE_LEVEL))
		var shown_level := mini(max_level, current_level + 1)
		var level_text := "MÁXIMO" if current_level >= max_level else "NIVEL %s / %s" % [_roman_level(shown_level), _roman_level(max_level)]
		var rarity_level := _rarity_level_label(str(option["rarity"]))
		card.get_node("CardDescription").text = "%s · %s\n%s" % [rarity_level, level_text, option["description"] if bool(option.get("evolution", false)) else _upgrade_description(base_id, str(option["rarity"]))]
		if current_level >= max_level:
			card.get_node("CardDescription").add_theme_color_override("font_color", Color("ffd36b"))
		else:
			card.get_node("CardDescription").add_theme_color_override("font_color", Color("e6edf0"))
		_style_upgrade_card(card, str(option["rarity"]))
		if option["rarity"] != "COMÚN":
			_spawn_burst(player_pos, _rarity_color(str(option["rarity"])), 10 if option["rarity"] == "RARA" else 18)
		card.scale = Vector2(0.72, 0.72)
		card.modulate = Color(1, 1, 1, 0.0)
		var entrance_offset := Vector2(0, 180)
		if option["rarity"] == "LEGENDARIA":
			entrance_offset = Vector2(0, -210)
		card.position = card.get_meta("base_position") + entrance_offset
		if str(option["rarity"]) != "COMÚN" and is_instance_valid(audio_manager):
			audio_manager.call("play_card_rarity", str(option["rarity"]), "appear")
	upgrade_panel.visible = true
	upgrade_overlay.visible = true
	upgrade_overlay.color.a = 0.0
	upgrade_confirm_label.visible = false
	upgrade_selecting = false
	upgrade_float_time = 0.0
	var overlay_tween := create_tween()
	overlay_tween.tween_property(upgrade_overlay, "color:a", 0.72, 0.28)
	for option in upgrade_options:
		if option["rarity"] == "LEGENDARIA":
			overlay_tween.tween_property(upgrade_overlay, "color:a", 0.9, 0.08)
			overlay_tween.tween_property(upgrade_overlay, "color:a", 0.72, 0.24)
			break
	for i in range(upgrade_buttons.size()):
		var card: Button = upgrade_buttons[i]
		var entry_tween := create_tween()
		entry_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entry_tween.tween_interval(float(i) * 0.08)
		entry_tween.parallel().tween_property(card, "position", card.get_meta("base_position"), 0.42)
		entry_tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.42)
		entry_tween.parallel().tween_property(card, "modulate", Color.WHITE, 0.24)

func _choose_upgrade(index: int) -> void:
	if not upgrade_pending or upgrade_selecting or index >= upgrade_options.size():
		return
	var selected: Dictionary = upgrade_options[index]
	upgrade_selecting = true
	upgrade_pending = false
	var selected_rarity := str(selected["rarity"])
	var selected_base_id := str(selected.get("base_id", selected["id"]))
	var chosen: Button = upgrade_buttons[index]
	chosen.z_index = 10
	if is_instance_valid(audio_manager):
		audio_manager.call("play_card_select", selected_base_id, selected_rarity)
		audio_manager.call("play_card_rarity", selected_rarity, "select")
	_spawn_burst(player_pos, _upgrade_color(selected_base_id), 28)
	for i in range(upgrade_buttons.size()):
		var card: Button = upgrade_buttons[i]
		var tween := create_tween()
		if i == index:
			tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(card, "scale", Vector2.ONE * 1.28, 0.28)
			tween.parallel().tween_property(card, "position", Vector2(287, 70), 0.28)
		else:
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(card, "modulate", Color(1, 1, 1, 0.0), 0.24)
			tween.parallel().tween_property(card, "scale", Vector2(0.55, 0.55), 0.24)
	var flash_tween := create_tween()
	flash_tween.tween_property(upgrade_overlay, "color:a", 0.88, 0.12)
	flash_tween.tween_property(upgrade_overlay, "color:a", 0.72, 0.24)
	if selected_rarity == "LEGENDARIA":
		flash_timer = 0.45
		_shake_camera(0.30, 14.0)
		if is_instance_valid(upgrade_lightning_flash):
			upgrade_lightning_flash.visible = true
			upgrade_lightning_flash.color.a = 0.0
			var lightning_tween := create_tween()
			lightning_tween.tween_property(upgrade_lightning_flash, "color:a", 0.52, 0.04)
			lightning_tween.tween_property(upgrade_lightning_flash, "color:a", 0.0, 0.26)
		flash_tween.tween_property(upgrade_overlay, "color:a", 1.0, 0.08)
		flash_tween.tween_property(upgrade_overlay, "color:a", 0.72, 0.30)
	elif selected_rarity == "ÉPICA":
		_spawn_burst(player_pos, Color("b45cff"), 38)
	elif selected_rarity == "RARA":
		_spawn_burst(player_pos, Color("36bfff"), 28)
	if selected_rarity == "LEGENDARIA":
		# El modo upgrade ya detiene la simulación; este intervalo mantiene la
		# congelación cinematográfica durante los primeros 0.3 s del impacto.
		await get_tree().create_timer(0.30).timeout
	await get_tree().create_timer(0.42).timeout
	var applied_level := _apply_upgrade(selected)
	var max_level := int(UPGRADE_MAX_LEVELS.get(selected_base_id, MAX_UPGRADE_LEVEL))
	var reached_max := not bool(selected.get("evolution", false)) and applied_level >= max_level
	if is_instance_valid(audio_manager):
		audio_manager.call("play_upgrade_sound", selected_base_id, selected_rarity, "apply")
	if selected_rarity == "LEGENDARIA" and is_instance_valid(audio_manager):
		audio_manager.call("pause_music_briefly", 0.55)
	mode = "playing"
	upgrade_panel.visible = false
	upgrade_overlay.visible = false
	var rarity_banner := "LEGENDARIA\n" if selected_rarity == "LEGENDARIA" else ""
	if reached_max:
		upgrade_confirm_label.text = rarity_banner + ("MEJORA MAXIMIZADA\n%s  ·  NIVEL %s" % [selected["title"], _roman_level(applied_level)])
	else:
		upgrade_confirm_label.text = rarity_banner + ("%s  ·  NIVEL %s" % [selected["title"], _roman_level(applied_level)])
	upgrade_confirm_label.visible = true
	upgrade_confirm_label.modulate = Color(1, 1, 1, 0.0)
	var confirm_tween := create_tween()
	confirm_tween.tween_property(upgrade_confirm_label, "modulate", Color.WHITE, 0.16)
	confirm_tween.tween_interval(0.8)
	confirm_tween.tween_property(upgrade_confirm_label, "modulate", Color(1, 1, 1, 0.0), 0.25)
	upgrade_selecting = false
	status_label.text = ("MEJORA MAXIMIZADA: %s" % selected["title"]) if reached_max else ("MEJORA OBTENIDA: %s · NIVEL %s" % [selected["title"], _roman_level(applied_level)])
	if reached_max:
		_unlock_evolution(selected_base_id)
		flash_timer = 0.55
		_spawn_burst(player_pos, Color("ffd36b"), 46)
		_play_upgrade_sound(selected_base_id, "max", "LEGENDARIA")
	_update_hud()

func _roman_level(level: int) -> String:
	var numerals := ["I", "II", "III", "IV", "V"]
	return numerals[clampi(level, 1, MAX_UPGRADE_LEVEL) - 1]

func _rarity_level_label(rarity: String) -> String:
	return "RANGO %s" % _roman_level({"COMÚN": 1, "RARA": 2, "ÉPICA": 3, "LEGENDARIA": 4}.get(rarity, 1))

func _upgrade_description(upgrade_id: String, rarity: String) -> String:
	match upgrade_id:
		"fury":
			return {"COMÚN": "+15% puntos por zombie", "RARA": "+25% puntos por zombie", "ÉPICA": "+40% puntos por zombie", "LEGENDARIA": "+75% puntos por zombie"}.get(rarity, "+15% puntos por zombie")
		"speed":
			if rarity == "LEGENDARIA":
				return "+50% velocidad · intangible 2 s"
			return {"COMÚN": "+10% velocidad", "RARA": "+18% velocidad", "ÉPICA": "+30% velocidad"}.get(rarity, "+10% velocidad")
		"medkit":
			if rarity == "LEGENDARIA":
				return "+3 vidas · curación completa"
			return {"COMÚN": "+1 vida", "RARA": "+1 vida · regeneración parcial", "ÉPICA": "+2 vidas"}.get(rarity, "+1 vida")
		"heavy":
			if rarity == "LEGENDARIA":
				return "+75% cadencia · proyectiles grandes"
			return {"COMÚN": "+15% velocidad de bala", "RARA": "+30% velocidad de bala", "ÉPICA": "+50% velocidad de bala"}.get(rarity, "+15% velocidad de bala")
		"survivor":
			var duration: String = str({"COMÚN": "1.5", "RARA": "3", "ÉPICA": "5", "LEGENDARIA": "8"}.get(rarity, "1.5"))
			return "%s s de invulnerabilidad" % duration
	return "Mejora acumulable"

func _apply_upgrade(selected: Dictionary) -> int:
	var upgrade_id := str(selected["id"])
	if bool(selected.get("evolution", false)):
		_apply_evolution(selected)
		evolution_acquired[upgrade_id] = true
		return MAX_UPGRADE_LEVEL
	var current_level := int(upgrade_levels.get(upgrade_id, 0))
	var max_level := int(UPGRADE_MAX_LEVELS.get(upgrade_id, MAX_UPGRADE_LEVEL))
	if current_level >= max_level:
		return max_level
	var next_level := current_level + 1
	upgrade_levels[upgrade_id] = next_level
	var rarity := str(selected["rarity"])

	match upgrade_id:
		"fury":
			var score_bonus: float = float({"COMÚN": 0.15, "RARA": 0.25, "ÉPICA": 0.40, "LEGENDARIA": 0.75}.get(rarity, 0.15))
			score_multiplier = minf(2.25, score_multiplier + float(score_bonus))
		"speed":
			var speed_bonus: float = float({"COMÚN": 0.10, "RARA": 0.18, "ÉPICA": 0.30, "LEGENDARIA": 0.50}.get(rarity, 0.10))
			player_speed = minf(player_base_speed * 1.72, player_speed * (1.0 + float(speed_bonus)))
			if rarity == "LEGENDARIA":
				# Corredor Fantasma: atraviesa enemigos durante 2 segundos.
				phase_timer = maxf(phase_timer, 2.0)
		"medkit":
			var healing: int = int({"COMÚN": 1, "RARA": 1, "ÉPICA": 2, "LEGENDARIA": 3}.get(rarity, 1))
			lives = mini(3, lives + int(healing))
			if rarity == "LEGENDARIA":
				# Curacion completa dentro del limite maximo de vidas.
				lives = 3
		"heavy":
			if rarity == "LEGENDARIA":
				fire_rate_multiplier = minf(4.0, fire_rate_multiplier * 1.75)
				bullet_size_multiplier = minf(2.5, bullet_size_multiplier * 1.35)
			else:
				var bullet_bonus: float = float({"COMÚN": 1.15, "RARA": 1.30, "ÉPICA": 1.50}.get(rarity, 1.15))
				projectile_speed_multiplier = minf(2.5, projectile_speed_multiplier * float(bullet_bonus))
		"survivor":
			var protection_duration: float = float({"COMÚN": 1.5, "RARA": 3.0, "ÉPICA": 5.0, "LEGENDARIA": 8.0}.get(rarity, 1.5))
			protection_timer = minf(9.0, protection_timer + float(protection_duration))
	return next_level

func _apply_evolution(selected: Dictionary) -> void:
	var base_id := str(selected.get("base_id", ""))
	match base_id:
		"fury":
			score_multiplier = minf(2.50, score_multiplier + 0.25)
		"speed":
			player_speed = minf(player_base_speed * 1.85, player_speed * 1.10)
			phase_timer = maxf(phase_timer, 3.0)
		"medkit":
			lives = 3
		"heavy":
			fire_rate_multiplier = minf(4.0, fire_rate_multiplier * 1.25)
			bullet_size_multiplier = minf(2.5, bullet_size_multiplier * 1.15)
		"survivor":
			protection_timer = minf(12.0, protection_timer + 3.0)

func _upgrade_color(upgrade_id: String) -> Color:
	match upgrade_id:
		"fury": return Color("ef4b42")
		"speed": return Color("36bfff")
		"medkit": return Color("5ee68b")
		"heavy": return Color("f1a447")
		"survivor": return Color("4d8dff")
	return Color("f0bf6d")

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"COMÚN": return Color("b9c4c7")
		"RARA": return Color("55c8ff")
		"ÉPICA": return Color("c779ff")
		"LEGENDARIA": return Color("ffbd55")
	return Color("f0bf6d")

func _end_game() -> void:
	mode = "game_over"
	player_dead = true
	player_moving = false
	if player_sprite != null:
		player_sprite.position = player_pos
		player_sprite.flip_h = false
		player_sprite.play("death")
	_save_record()
	game_over_label.text = "FIN DE LA NOCHE\nPUNTUACION  %06d\nPulsa F para volver al menú" % score
	game_over_label.visible = true
	status_label.text = "HAS CAIDO, %s" % username.to_upper()
	_update_hud()

func _draw() -> void:
	var danger := clampf(float(wave - 1) / 10.0, 0.0, 1.0)
	_draw_ground(danger)
	for bullet in bullets:
		draw_circle(bullet["pos"], float(bullet.get("radius", 8.0)) * 0.5, Color("f8d891"))
		draw_line(bullet["pos"], bullet["pos"] - bullet["vel"].normalized() * 12.0, Color(1, 0.72, 0.35, 0.45), 2.0)
	for zombie in zombies:
		if weather == "niebla" and zombie["pos"].distance_to(player_pos) > 420.0:
			continue
		_draw_zombie(zombie)
	draw_circle(player_pos + Vector2(0, 28), 24, Color(0.0, 0.0, 0.0, 0.32))
	for particle in particles:
		var alpha: float = clampf(float(particle["life"]) * 1.5, 0.0, 1.0)
		var color: Color = particle["color"]
		color.a = alpha
		draw_circle(particle["pos"], float(particle["size"]), color)
	if flash_timer > 0:
		draw_circle(player_pos + player_pos.direction_to(aim_pos) * 33.0, 14.0, Color(1.0, 0.83, 0.43, flash_timer * 8.0))
	_draw_weather_effects()

func _draw_weather_effects() -> void:
	if weather_darkness > 0.0:
		draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.015, 0.025, 0.055, weather_darkness))
	if weather == "noche":
		# Halo ambiental tenue para conservar legibilidad del jugador.
		draw_circle(player_pos, 150.0, Color(0.24, 0.34, 0.40, 0.055))
	if weather_rain_strength > 0.0:
		for i in range(58):
			var x := fmod(float(i * 83) + game_time * 145.0, WORLD_SIZE.x)
			var y := fmod(float(i * 47) + game_time * 235.0, WORLD_SIZE.y)
			draw_line(Vector2(x, y), Vector2(x - 4.0, y + 18.0), Color(0.68, 0.82, 0.9, 0.14 * weather_rain_strength), 1.0)
		# Charcos simples integrados como reflejos, no como obstáculos.
		for i in range(8):
			var puddle_x := 90.0 + float(i * 151) + sin(game_time * 0.35 + i) * 18.0
			var puddle_y := 180.0 + float((i * 83) % 430)
			draw_weather_ellipse(Vector2(puddle_x, puddle_y), Vector2(32.0, 9.0), Color(0.18, 0.35, 0.40, 0.16 * weather_rain_strength))
	if weather_fog_strength > 0.0:
		for i in range(7):
			var fog_x := fmod(float(i * 217) + game_time * (12.0 + i * 2.0), WORLD_SIZE.x + 260.0) - 130.0
			var fog_y := 160.0 + float(i * 72)
			draw_circle(Vector2(fog_x, fog_y), 110.0 + float(i * 8), Color(0.58, 0.68, 0.72, 0.045 * weather_fog_strength))
	if weather_lightning_strength > 0.0:
		draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.68, 0.86, 1.0, weather_lightning_strength * 0.16))

func draw_weather_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ground(_danger: float) -> void:
	# El suelo ya no se dibuja con primitivas: UrbanGroundTileMap es la fuente
	# visual única del escenario y evita la antigua cuadrícula azul.
	return

func _draw_prop(prop: Dictionary, danger: float) -> void:
	var p: Vector2 = prop["pos"]
	var s: float = prop["size"]
	var object = prop.get("node")
	if is_instance_valid(object) and object.destroyed_state:
		# Los restos permanecen como decoración tras la destrucción.
		draw_circle(p + Vector2(0, 5), 18 * s, Color(0.12, 0.12, 0.12, 0.6))
		draw_line(p - Vector2(16, 8) * s, p + Vector2(14, 7) * s, Color("6a5142"), 3.0)
		return
	match int(prop["type"]):
		0:
			draw_circle(p, 18 * s, Color("263c3d"))
			draw_circle(p + Vector2(0, -8) * s, 11 * s, Color("31504a"))
			draw_line(p + Vector2(0, 5), p + Vector2(0, 25), Color("5b4030"), 5 * s)
		1:
			draw_rect(Rect2(p - Vector2(29, 16) * s, Vector2(58, 32) * s), Color("34434a"))
			draw_rect(Rect2(p - Vector2(20, 10) * s, Vector2(15, 8) * s), Color("18242a"))
			draw_rect(Rect2(p + Vector2(5, -10) * s, Vector2(15, 8) * s), Color("18242a"))
			draw_circle(p + Vector2(-20, 16) * s, 5 * s, Color("15191d"))
			draw_circle(p + Vector2(20, 16) * s, 5 * s, Color("15191d"))
		2:
			draw_circle(p, 15 * s, Color("51565a"))
			draw_circle(p - Vector2(5, 3) * s, 5 * s, Color("73787a"))
		3:
			draw_rect(Rect2(p - Vector2(27, 16) * s, Vector2(54, 32) * s), Color("294b55"))
			draw_line(p - Vector2(22, 10) * s, p + Vector2(22, -10) * s, Color("7aa6a0"), 2 * s)
			draw_line(p - Vector2(22, 1) * s, p + Vector2(22, 1) * s, Color("192c32"), 2 * s)
		4:
			draw_rect(Rect2(p - Vector2(58, 21) * s, Vector2(116, 42) * s), Color("4d4c48"))
			draw_rect(Rect2(p - Vector2(46, 14) * s, Vector2(22, 9) * s), Color("18272d"))
			draw_rect(Rect2(p + Vector2(-15, -14) * s, Vector2(22, 9) * s), Color("18272d"))
			draw_rect(Rect2(p + Vector2(17, -14) * s, Vector2(22, 9) * s), Color("18272d"))
			draw_line(p - Vector2(47, 3) * s, p + Vector2(49, 3) * s, Color("b65d48"), 3 * s)
		5:
			draw_line(p - Vector2(30, 10) * s, p + Vector2(30, 10) * s, Color("a76d48"), 5 * s)
			draw_line(p - Vector2(30, 10) * s, p + Vector2(-30, 10) * s, Color("d39b61"), 3 * s)
		6:
			draw_line(p + Vector2(0, 17) * s, p + Vector2(0, -18) * s, Color("515c60"), 4 * s)
			draw_circle(p + Vector2(0, -20) * s, 7 * s, Color("e0bd6a"))
			draw_circle(p + Vector2(0, -20) * s, 13 * s, Color(0.9, 0.7, 0.25, 0.12))
		7:
			draw_line(p - Vector2(34, 0) * s, p + Vector2(34, 0) * s, Color("80644d"), 4 * s)
			for post in [-28, 0, 28]:
				draw_line(p + Vector2(post, -10) * s, p + Vector2(post, 10) * s, Color("a07a57"), 3 * s)
		8:
			draw_set_transform(p, 0.0, Vector2(1.7 * s, 0.8 * s))
			draw_circle(Vector2.ZERO, 15.0, Color(0.18, 0.35, 0.4, 0.7))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		9:
			draw_rect(Rect2(p - Vector2(20, 13) * s, Vector2(40, 26) * s), Color("5c5550"))
			draw_circle(p + Vector2(11, -7) * s, 5 * s, Color("92765d"))
		10:
			draw_rect(Rect2(p - Vector2(52, 41) * s, Vector2(104, 82) * s), Color("30383d"))
			draw_rect(Rect2(p - Vector2(40, 28) * s, Vector2(22, 15) * s), Color("131d22"))
			draw_rect(Rect2(p + Vector2(10, -28) * s, Vector2(22, 15) * s), Color("131d22"))
			draw_line(p - Vector2(48, 5) * s, p + Vector2(48, 15) * s, Color("7b4d42"), 3 * s)
		11:
			draw_line(p - Vector2(34, 13) * s, p + Vector2(34, 13) * s, Color("6d4a36"), 12 * s)
			draw_line(p - Vector2(34, 10) * s, p + Vector2(34, 10) * s, Color("9b6540"), 5 * s)
	var damage_ratio := 0.0
	if is_instance_valid(object):
		damage_ratio = 1.0 - object.current_health / maxf(1.0, object.max_health)
	if damage_ratio > 0.05:
		draw_arc(p, 25.0 * s, -PI * 0.5, -PI * 0.5 + TAU * damage_ratio, 16, Color("e4574f"), 3.0)

func _direction_index(direction: Vector2) -> int:
	if absf(direction.x) < 0.38:
		return 1 if direction.y >= 0.0 else 0
	if absf(direction.y) < 0.38:
		return 2 if direction.x >= 0.0 else 3
	if direction.x >= 0.0:
		return 6 if direction.y >= 0.0 else 4
	return 7 if direction.y >= 0.0 else 5

func _draw_player() -> void:
	if survivor_sheet != null:
		var cell_size := Vector2(survivor_sheet.get_width() / 4.0, survivor_sheet.get_height())
		var destination_size := Vector2(78, 92)
		var draw_position := player_pos + Vector2(-destination_size.x * 0.5, -destination_size.y * 0.72)
		var source_rect := Rect2(Vector2(selected_character * cell_size.x, 0), cell_size)
		draw_circle(player_pos + Vector2(0, destination_size.y * 0.26), 24, Color(0.0, 0.0, 0.0, 0.32))
		draw_texture_rect_region(survivor_sheet, Rect2(draw_position, destination_size), source_rect)
		return
	var direction := player_pos.direction_to(aim_pos)
	draw_circle(player_pos + Vector2(0, 6), 22, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(player_pos, 18, Color("e1e8df"))
	draw_circle(player_pos - Vector2(0, 9), 10, Color("f0bf6d"))
	draw_line(player_pos, player_pos + direction * 30, Color("74858d"), 8)
	draw_line(player_pos, player_pos + direction * 34, Color("d3e0dc"), 3)

func _draw_zombie(zombie: Dictionary) -> void:
	var p: Vector2 = zombie["pos"]
	var radius: float = zombie["radius"]
	var sway := sin(float(zombie["phase"])) * 3.0
	var zombie_type: int = int(zombie["type"])
	var zombie_node = zombie.get("node")
	var visual_scale: Vector2 = Vector2.ONE
	var visual_modulate: Color = Color.WHITE
	if is_instance_valid(zombie_node):
		visual_scale = zombie_node.scale
		visual_modulate = zombie_node.modulate
	var animated_sheet: Texture2D = null
	if zombie_type >= 0 and zombie_type < zombie_animation_sheets.size():
		animated_sheet = zombie_animation_sheets[zombie_type]
	if animated_sheet != null:
		var destination_size: Vector2 = Vector2(radius * 3.4, radius * 3.4) * visual_scale
		var draw_position := p + Vector2(-destination_size.x * 0.5, -destination_size.y * 0.62 + sway)
		var cell_size := Vector2(animated_sheet.get_width() / 8.0, animated_sheet.get_height() / 5.0)
		var walk_frame: int = floori(float(zombie["phase"]) * 1.6) % 8
		var source_rect := Rect2(Vector2(walk_frame * cell_size.x, cell_size.y), cell_size)
		draw_circle(p + Vector2(0, destination_size.y * 0.28), radius + 5, Color(0, 0, 0, 0.28))
		draw_texture_rect_region(animated_sheet, Rect2(draw_position, destination_size), source_rect, visual_modulate)
		return
	if zombie_sheet == null:
		draw_circle(p + Vector2(0, 6), radius + 5, Color(0, 0, 0, 0.28))
		draw_circle(p + Vector2(0, sway), radius, Color("754348"))
		return
	var destination_size: Vector2 = Vector2(radius * 3.4, radius * 3.4) * visual_scale
	var draw_position := p + Vector2(-destination_size.x * 0.5, -destination_size.y * 0.62 + sway)
	var cell_size := Vector2(zombie_sheet.get_width() / 4.0, zombie_sheet.get_height() / 3.0)
	var source_rect := Rect2(Vector2((zombie_type % 4) * cell_size.x, floori(zombie_type / 4.0) * cell_size.y), cell_size)
	draw_circle(p + Vector2(0, destination_size.y * 0.28), radius + 5, Color(0, 0, 0, 0.28))
	draw_texture_rect_region(zombie_sheet, Rect2(draw_position, destination_size), source_rect, visual_modulate)

func _load_records() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return {}
	var normalized: Dictionary = {}
	for player_name in data.keys():
		normalized[str(player_name)] = _normalize_record(data[player_name])
	return normalized

func _save_record() -> void:
	var stats := _normalize_record(records.get(username, {}))
	stats["score"] = maxi(int(stats["score"]), score)
	stats["wave"] = maxi(int(stats["wave"]), wave)
	stats["kills"] = maxi(int(stats["kills"]), kills)
	records[username] = stats
	_write_records()
	_refresh_leaderboard()

func _write_records() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(records))

func _return_to_menu(message: String) -> void:
	print("[DEBUG][MENU] _return_to_menu llamado | modo=", mode, " | transition_busy=", scene_transition_busy, " | mensaje=", message)
	# El regreso debe ser fiable incluso si un Tween anterior quedó activo o
	# fue consumido por el editor embebido. La transición de salida es opcional;
	# nunca debe impedir que el jugador vuelva al menú.
	scene_transition_busy = false
	if scene_transition_layer != null:
		scene_transition_layer.visible = false
	_return_to_menu_after_transition(message)

func _return_to_menu_after_transition(message: String) -> void:
	print("[DEBUG][MENU] _return_to_menu_after_transition ejecutado | mensaje=", message)
	mode = "menu"
	touch_move = Vector2.ZERO
	touch_shoot_pressed = false
	player_dead = false
	if player_sprite != null:
		player_sprite.stop()
		player_sprite.visible = false
	upgrade_pending = false
	if hud != null:
		hud.visible = false
	if world_parallax != null:
		world_parallax.visible = false
	if world_camera != null:
		world_camera.enabled = false
	if upgrade_panel != null:
		upgrade_panel.visible = false
	if upgrade_overlay != null:
		upgrade_overlay.visible = false
	if upgrade_confirm_label != null:
		upgrade_confirm_label.visible = false
	if bestiary != null:
		bestiary.visible = false
	if game_over_label != null:
		game_over_label.visible = false
	get_node("MenuLayer").visible = true
	print("[DEBUG][MENU] MenuLayer visible=true | modo=", mode)
	if is_instance_valid(audio_manager):
		audio_manager.call("start_menu_music")
	menu_message.text = message
	_refresh_leaderboard()

func _input(event: InputEvent) -> void:
	if rebinding_action == "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F or event.keycode == KEY_ESCAPE:
				print("[DEBUG][MENU] Evento de teclado recibido | tecla=", event.keycode, " | modo=", mode)
			# _input recibe la tecla antes que los controles de la interfaz;
			# así Escape y R siguen funcionando aunque un Button tenga el foco.
			if event.keycode == KEY_ESCAPE and mode in ["playing", "upgrade", "game_over"]:
				if not username.is_empty():
					_save_record()
				_return_to_menu("Sesion guardada. Elige otro superviviente o vuelve a entrar.")
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_F and mode in ["playing", "upgrade", "game_over"]:
				_return_to_menu("Sesion guardada. Elige otro superviviente o vuelve a entrar.")
				get_viewport().set_input_as_handled()
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed:
		_assign_input_event(event)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if rebinding_action != "":
		if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed:
			_assign_input_event(event)
		return
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_ESCAPE and mode in ["playing", "upgrade", "game_over"]:
		if not username.is_empty():
			_save_record()
		_return_to_menu("Sesion guardada. Elige otro superviviente o vuelve a entrar.")
	# R durante la partida está reservado para recargar mediante la acción
	# "reload". F y Escape gestionan el regreso al menú.
