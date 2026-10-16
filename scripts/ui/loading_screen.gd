extends Control
## Pantalla de carga real: solicita la escena principal en un hilo y mantiene
## una duración mínima para que la entrada sea legible y cinematográfica.

const MAIN_SCENE_PATH := "res://main.tscn"
const WARMUP_RESOURCE_PATH := "res://assets/world/urban_apocalypse_tileset_clean.png"
const MINIMUM_DURATION := 3.8
const TIPS := [
	"Mantén la distancia: los infectados rodean al objetivo.",
	"Las oleadas llegan por la carretera del horizonte.",
	"Busca mejoras que complementen tu estilo de supervivencia.",
	"La noche vuelve más peligrosos a los infectados.",
	"El ruido atrae a los infectados.",
	"No desperdicies munición.",
	"Explora antes de que anochezca.",
	"Las herramientas son tan importantes como las armas."
]

var elapsed := 0.0
var load_progress := [0.0]
var load_status := ResourceLoader.THREAD_LOAD_IN_PROGRESS
var loaded_scene: PackedScene
var warmup_resource: Resource
var scene_change_started := false
var tip_index := 0
var tip_timer := 0.0
var fog_material: ShaderMaterial
var bar_shine_material: ShaderMaterial
var intro_black: ColorRect
var outro_flash: ColorRect
var logo_label: Label
var dust_particles: GPUParticles2D
var progress_bar: TextureProgressBar
var progress_label: Label
var tip_label: Label
var status_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("start_loading_ambience"):
		audio.start_loading_ambience()
	if audio != null and audio.has_method("start_loading_music"):
		audio.start_loading_music()
	# Se precarga en segundo plano el atlas pesado del escenario. La escena
	# principal se instancia al terminar la duración mínima, ya con la pantalla
	# cubriéndola para evitar cualquier parpadeo.
	var request_error := ResourceLoader.load_threaded_request(WARMUP_RESOURCE_PATH, "Texture2D", false)
	if request_error != OK:
		push_warning("No se pudo iniciar la precarga de la ambientación")
		load_status = ResourceLoader.THREAD_LOAD_FAILED
	_play_intro()

func _process(delta: float) -> void:
	elapsed += delta
	tip_timer += delta
	if tip_timer >= 0.82:
		tip_timer = 0.0
		tip_index = (tip_index + 1) % TIPS.size()
		var tip_tween := create_tween()
		tip_tween.tween_property(tip_label, "modulate:a", 0.15, 0.12)
		tip_tween.tween_callback(func() -> void: tip_label.text = TIPS[tip_index])
		tip_tween.tween_property(tip_label, "modulate:a", 1.0, 0.20)
	if fog_material != null:
		fog_material.set_shader_parameter("time", elapsed)
	if bar_shine_material != null:
		bar_shine_material.set_shader_parameter("time", elapsed)
	if logo_label != null:
		var pulse := 0.94 + 0.06 * sin(elapsed * 1.8)
		logo_label.modulate = Color(0.92 + pulse * 0.08, 0.97 + pulse * 0.03, 1.0, 1.0)
	# La carga real puede terminar en milisegundos. La progresión visible se
	# distribuye por toda la duración cinematográfica para que nunca aparezca
	# clavada en 000%.
	var timeline_progress := clampf(elapsed / MINIMUM_DURATION, 0.0, 1.0)
	var actual_progress := 0.0
	if load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		load_status = ResourceLoader.load_threaded_get_status(WARMUP_RESOURCE_PATH, load_progress)
		actual_progress = clampf(float(load_progress[0]) * 100.0, 0.0, 100.0)
		status_label.text = "CARGANDO RECURSOS..."
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			warmup_resource = ResourceLoader.load_threaded_get(WARMUP_RESOURCE_PATH)
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		status_label.text = "PREPARANDO LA NOCHE..."
	var visible_progress := timeline_progress * 100.0
	visible_progress = maxf(visible_progress, actual_progress)
	if elapsed < MINIMUM_DURATION:
		visible_progress = minf(99.0, visible_progress)
	progress_bar.value = visible_progress
	progress_label.text = "%03d%%" % int(visible_progress)
	if loaded_scene == null and not scene_change_started and elapsed >= MINIMUM_DURATION:
		loaded_scene = load(MAIN_SCENE_PATH) as PackedScene
	if loaded_scene != null and not scene_change_started and elapsed >= MINIMUM_DURATION:
		_finish_loading()

func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "DestroyedCityBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.texture = load("res://assets/backgrounds/menu_apocalypse.png") as Texture2D
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var tint := ColorRect.new()
	tint.name = "NightTint"
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.005, 0.018, 0.028, 0.62)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	var fog := ColorRect.new()
	fog.name = "MovingFog"
	fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_material = ShaderMaterial.new()
	var fog_shader := Shader.new()
	fog_shader.code = "shader_type canvas_item;\nuniform float time = 0.0;\nfloat hash21(vec2 p){p=fract(p*vec2(123.34,456.21));p+=dot(p,p+45.32);return fract(p.x*p.y);}\nfloat noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);float a=hash21(i);float b=hash21(i+vec2(1.0,0.0));float c=hash21(i+vec2(0.0,1.0));float d=hash21(i+vec2(1.0,1.0));return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);}\nvoid fragment(){vec2 uv=UV;float bands=noise(vec2(uv.x*2.0-time*0.018,uv.y*5.0));float horizon=smoothstep(0.22,0.72,uv.y)*(1.0-smoothstep(0.72,1.0,uv.y));float fog_amount=smoothstep(0.48,0.78,bands)*horizon*0.22;COLOR=vec4(0.42,0.63,0.66,fog_amount);}"
	fog_material.shader = fog_shader
	fog.material = fog_material
	add_child(fog)
	var shade := ColorRect.new()
	shade.name = "CinematicShade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.22)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	logo_label = _make_label("NOCHE DE LOS INFECTADOS", Vector2(150, 190), Vector2(980, 64), 42, Color("e7f7fb"))
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.add_theme_constant_override("outline_size", 5)
	logo_label.add_theme_color_override("font_outline_color", Color(0.08, 0.48, 0.72, 0.95))
	add_child(logo_label)
	tip_label = _make_label(TIPS[0], Vector2(190, 372), Vector2(900, 34), 16, Color("d0dddd"))
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(tip_label)
	progress_bar = TextureProgressBar.new()
	progress_bar.name = "MetalLoadingBar"
	progress_bar.position = Vector2(390, 460)
	progress_bar.size = Vector2(500, 28)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.texture_under = load("res://assets/ui/stats/stat_bar_bg.png") as Texture2D
	progress_bar.texture_progress = load("res://assets/ui/stats/defense_fill.png") as Texture2D
	progress_bar.texture_over = load("res://assets/ui/stats/stat_bar_frame.png") as Texture2D
	progress_bar.nine_patch_stretch = true
	progress_bar.stretch_margin_left = 20
	progress_bar.stretch_margin_top = 8
	progress_bar.stretch_margin_right = 20
	progress_bar.stretch_margin_bottom = 8
	progress_bar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(progress_bar)
	var bar_shine := ColorRect.new()
	bar_shine.name = "MovingBarShine"
	bar_shine.position = Vector2(390, 460)
	bar_shine.size = Vector2(500, 28)
	bar_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_shine_material = ShaderMaterial.new()
	var shine_shader := Shader.new()
	shine_shader.code = "shader_type canvas_item;\nuniform float time = 0.0;\nvoid fragment(){float band=1.0-smoothstep(0.0,0.18,abs(fract(UV.x-time*0.16)-0.5)*2.0);COLOR=vec4(0.72,0.96,1.0,band*0.12);;}"
	bar_shine_material.shader = shine_shader
	bar_shine.material = bar_shine_material
	add_child(bar_shine)
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(640.0, 340.0, 0.0)
	particle_material.direction = Vector3(-0.12, -0.02, 0.0)
	particle_material.initial_velocity_min = 3.0
	particle_material.initial_velocity_max = 12.0
	particle_material.gravity = Vector3.ZERO
	particle_material.scale_min = 0.25
	particle_material.scale_max = 0.8
	dust_particles = GPUParticles2D.new()
	dust_particles.name = "FloatingDust"
	dust_particles.position = Vector2(640, 360)
	dust_particles.amount = 34
	dust_particles.lifetime = 5.0
	dust_particles.preprocess = 3.0
	dust_particles.process_material = particle_material
	var dust_image := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	dust_image.fill(Color(0.72, 0.88, 0.88, 0.22))
	dust_particles.texture = ImageTexture.create_from_image(dust_image)
	dust_particles.z_index = 2
	add_child(dust_particles)
	progress_label = _make_label("000%", Vector2(920, 458), Vector2(80, 30), 14, Color("9bd8db"))
	add_child(progress_label)
	status_label = _make_label("PREPARANDO LA NOCHE...", Vector2(300, 505), Vector2(680, 28), 13, Color("9bd8db"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	outro_flash = ColorRect.new()
	outro_flash.name = "SoftFlash"
	outro_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outro_flash.color = Color(0.62, 0.9, 1.0, 0.0)
	outro_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outro_flash)
	intro_black = ColorRect.new()
	intro_black.name = "IntroBlack"
	intro_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_black.color = Color(0.0, 0.0, 0.0, 1.0)
	intro_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(intro_black)

func _make_label(text_value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 5)
	return label

func _play_intro() -> void:
	var tween := create_tween()
	tween.tween_property(intro_black, "color", Color(0.0, 0.0, 0.0, 0.0), 1.05)

func _finish_loading() -> void:
	scene_change_started = true
	progress_bar.value = 100.0
	progress_label.text = "100%"
	status_label.text = "CARGA COMPLETADA"
	var tween := create_tween()
	tween.tween_property(outro_flash, "color", Color(0.62, 0.9, 1.0, 0.18), 0.10)
	tween.tween_property(outro_flash, "color", Color(0.62, 0.9, 1.0, 0.0), 0.28)
	tween.tween_interval(0.22)
	tween.tween_callback(_change_to_main_scene)

func _change_to_main_scene() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_loading_ambience"):
		audio.stop_loading_ambience()
	if audio != null and audio.has_method("stop_loading_music"):
		audio.stop_loading_music()
	if loaded_scene != null:
		get_tree().change_scene_to_packed(loaded_scene)

func _exit_tree() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_loading_ambience"):
		audio.stop_loading_ambience()
	if audio != null and audio.has_method("stop_loading_music"):
		audio.stop_loading_music()
