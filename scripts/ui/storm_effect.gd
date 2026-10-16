extends Control

## Ambientación ligera de tormenta para el menú principal.
## Se dibuja detrás del título para no afectar a la interacción de los botones.

var rng := RandomNumberGenerator.new()
var lightning_timer := 3.0
var lightning_alpha := 0.0
var flash_strength := 0.0
var lightning_points := PackedVector2Array()
var intro_time := 0.0
var energy_position := -180.0
var rain := []
var smoke := [
	Vector2(110, 190), Vector2(265, 245), Vector2(875, 185),
	Vector2(1030, 285), Vector2(1180, 170), Vector2(520, 285)
]
var eyes := [
	Vector2(142, 329), Vector2(176, 350), Vector2(1035, 315),
	Vector2(1080, 348), Vector2(1150, 302)
]

func _ready() -> void:
	rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning_timer = rng.randf_range(2.5, 6.0)
	for i in range(46):
		rain.append({
		"position": Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0)),
		"speed": rng.randf_range(120.0, 230.0),
		"length": rng.randf_range(5.0, 13.0)
	})
	queue_redraw()

func _process(delta: float) -> void:
	lightning_timer -= delta
	intro_time += delta
	energy_position += delta * 260.0
	if energy_position > 820.0:
		energy_position = -180.0
	lightning_alpha = maxf(0.0, lightning_alpha - delta * 8.0)
	flash_strength = maxf(0.0, flash_strength - delta * 3.8)
	if lightning_timer <= 0.0:
		_start_lightning()
		lightning_timer = rng.randf_range(4.0, 8.0)
	for drop in rain:
		var rain_position: Vector2 = drop["position"]
		rain_position.y += float(drop["speed"]) * delta
		if rain_position.y > 730.0:
			rain_position.y = -10.0
			rain_position.x = rng.randf_range(0.0, 1280.0)
		drop["position"] = rain_position
	queue_redraw()

func get_logo_alpha() -> float:
	return clampf((intro_time - 0.72) / 0.9, 0.0, 1.0)

func _start_lightning() -> void:
	var start_x := rng.randf_range(180.0, 1120.0)
	var y := rng.randf_range(30.0, 115.0)
	lightning_points = PackedVector2Array([Vector2(start_x, y)])
	for i in range(6):
		y += rng.randf_range(32.0, 58.0)
		start_x += rng.randf_range(-42.0, 42.0)
		lightning_points.append(Vector2(start_x, y))
	lightning_alpha = 1.0
	flash_strength = 1.0

func _draw() -> void:
	# Entrada cinematográfica: comienza casi a oscuras y se abre con el primer rayo.
	var intro_dark := 1.0 - clampf(intro_time / 1.65, 0.0, 1.0)
	if intro_dark > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.01, 0.02, intro_dark * 0.82))
	if intro_time > 0.58 and intro_time < 1.08:
		var opening_flash := 1.0 - absf(intro_time - 0.74) / 0.34
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.65, 0.86, 1.0, maxf(0.0, opening_flash) * 0.15))

	# Relámpago que ilumina brevemente el cielo y la ciudad.
	if lightning_alpha > 0.0 and lightning_points.size() > 1:
		draw_polyline(lightning_points, Color(0.72, 0.9, 1.0, lightning_alpha), 3.0, true)
		draw_polyline(lightning_points, Color(0.95, 1.0, 1.0, lightning_alpha), 1.0, true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.7, 0.82, lightning_alpha * 0.10))
	if flash_strength > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.9, 1.0, flash_strength * 0.055))

	# Humo y niebla muy sutiles, sin ocultar el fondo.
	for i in range(smoke.size()):
		var p: Vector2 = smoke[i]
		var drift := sin(Time.get_ticks_msec() * 0.00035 + float(i)) * 18.0
		draw_circle(p + Vector2(drift, 0), 62.0, Color(0.04, 0.10, 0.14, 0.055))
		draw_circle(p + Vector2(drift * 0.5, 18), 40.0, Color(0.28, 0.42, 0.48, 0.035))

	# Ojos lejanos entre los edificios.
	for i in range(eyes.size()):
		var pulse := 0.35 + 0.25 * sin(Time.get_ticks_msec() * 0.003 + float(i))
		draw_circle(eyes[i], 2.0, Color(0.95, 0.08, 0.08, pulse))

	# Lluvia fina en primer plano.
	for drop in rain:
		var rain_position: Vector2 = drop["position"]
		draw_line(rain_position, rain_position + Vector2(-2.0, float(drop["length"])), Color(0.62, 0.78, 0.84, 0.16), 1.0)

	# Chispas y barrido de energía alrededor del logo.
	var sparkle_time := Time.get_ticks_msec() * 0.004
	for i in range(14):
		var sx := 340.0 + fmod(float(i * 97) + sparkle_time * (12.0 + i), 600.0)
		var sy := 142.0 + sin(sparkle_time * 0.7 + float(i)) * 35.0
		var sa := 0.18 + 0.18 * sin(sparkle_time * 1.8 + float(i))
		draw_circle(Vector2(sx, sy), 1.4, Color(0.42, 0.86, 1.0, sa))

