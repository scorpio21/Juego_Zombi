extends Node2D

@export_enum("mid", "front", "weather") var layer_kind := "mid"

var elapsed := 0.0
var rng := RandomNumberGenerator.new()
var motes: Array[Dictionary] = []

func _ready() -> void:
	rng.seed = 3187 if layer_kind == "mid" else 8241
	for i in range(42 if layer_kind == "weather" else 18):
		motes.append({
			"pos": Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(120.0, 720.0)),
			"speed": rng.randf_range(6.0, 22.0),
			"size": rng.randf_range(1.0, 3.5)
		})
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	for mote in motes:
		var position: Vector2 = mote["pos"]
		position.x -= float(mote["speed"]) * delta
		if position.x < -20.0:
			position.x = 1300.0
		mote["pos"] = position
	queue_redraw()

func _draw() -> void:
	if layer_kind == "mid":
		for i in range(motes.size()):
			var p: Vector2 = motes[i]["pos"]
			var drift := sin(elapsed * 0.22 + float(i)) * 20.0
			draw_circle(p + Vector2(drift, 0), 55.0 + float(motes[i]["size"]) * 8.0, Color(0.08, 0.14, 0.16, 0.045))
			draw_circle(p + Vector2(drift + 35.0, 18), 32.0, Color(0.38, 0.46, 0.46, 0.025))
	elif layer_kind == "front":
		for i in range(motes.size()):
			var p: Vector2 = motes[i]["pos"]
			draw_circle(p, 24.0 + sin(elapsed * 0.4 + float(i)) * 5.0, Color(0.54, 0.62, 0.60, 0.035))
			if i % 3 == 0:
				draw_line(p, p + Vector2(18, 5), Color(0.2, 0.3, 0.28, 0.12), 2.0)
	else:
		for mote in motes:
			var p: Vector2 = mote["pos"]
			draw_line(p, p + Vector2(-4, 18), Color(0.67, 0.78, 0.8, 0.12), 1.0)
