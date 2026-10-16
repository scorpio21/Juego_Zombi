extends Control
## Niebla procedural ligera para la pantalla de carga.
## No requiere texturas externas y funciona en Windows, Web y móvil.

@export var cloud_count := 7
@export var drift_speed := 18.0
@export var opacity := 0.16

var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for i in range(cloud_count):
		var fi := float(i)
		var radius := 105.0 + fmod(fi * 41.0, 95.0)
		var lane := fmod(fi * 0.19, 1.0)
		var x := fposmod(fi * 230.0 + elapsed * drift_speed * (0.65 + fi * 0.035), size.x + radius * 2.0) - radius
		var y := size.y * (0.18 + lane * 0.68) + sin(elapsed * 0.22 + fi * 1.7) * 18.0
		var alpha := opacity * (0.55 + 0.45 * sin(fi * 2.1 + elapsed * 0.15))
		draw_set_transform(Vector2(x, y), 0.0, Vector2(2.2, 0.48))
		draw_circle(Vector2.ZERO, radius, Color(0.35, 0.61, 0.67, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
