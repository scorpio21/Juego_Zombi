class_name Zombie
extends Node2D

signal died(zombie)

@export var enemy_data: Resource
@export var show_health_bar_delay := 0.08
@export var death_duration := 0.55

var current_health: float = 0.0
var is_dead := false
var health_bar: ProgressBar
var _health_tween: Tween
var navigation_agent: NavigationAgent2D

func setup(data) -> void:
	enemy_data = data
	current_health = float(data.max_health)
	_build_health_bar()

func _ready() -> void:
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.name = "NavigationAgent2D"
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 18.0
	navigation_agent.radius = 18.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.neighbor_distance = 120.0
	navigation_agent.max_speed = 260.0
	add_child(navigation_agent)
	if enemy_data != null:
		current_health = float(enemy_data.max_health)
	_build_health_bar()

func set_navigation_target(target: Vector2) -> void:
	if navigation_agent != null:
		navigation_agent.target_position = target

func navigation_direction(fallback: Vector2) -> Vector2:
	if navigation_agent == null or navigation_agent.is_navigation_finished():
		return fallback
	var next_point := navigation_agent.get_next_path_position()
	var direction := global_position.direction_to(next_point)
	return direction if direction.length_squared() > 0.01 else fallback

func _build_health_bar() -> void:
	if health_bar != null or enemy_data == null:
		return
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	# El sprite se dibuja desde los pies del enemigo; la barra debe quedar
	# anclada justo sobre la cabeza y no flotando en el escenario.
	health_bar.position = Vector2(-25, -52)
	health_bar.size = Vector2(50, 4)
	# Godot's default ProgressBar theme has a larger minimum height. Scale it
	# vertically so the in-game bar remains a thin health indicator.
	health_bar.custom_minimum_size = Vector2.ZERO
	# ProgressBar conserva una altura mínima del tema aunque su tamaño sea 4 px.
	# Esta escala la convierte en una línea fina sin alterar su anchura.
	health_bar.scale = Vector2(1.0, 0.05)
	health_bar.z_index = 8
	health_bar.min_value = 0.0
	health_bar.max_value = float(enemy_data.max_health)
	health_bar.value = current_health
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.visible = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("20272b")
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d93645")
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)
	add_child(health_bar)

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	if health_bar == null:
		_build_health_bar()
	if health_bar != null:
		health_bar.visible = true
		if _health_tween != null and _health_tween.is_valid():
			_health_tween.kill()
		_health_tween = create_tween()
		_health_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_health_tween.tween_property(health_bar, "value", current_health, 0.16)
	if current_health <= 0.0:
		die()

func get_inspection_data() -> Dictionary:
	if enemy_data == null:
		return {}
	return {
		"name": enemy_data.display_name,
		"level": enemy_data.level,
		"current_health": current_health,
		"max_health": enemy_data.max_health,
		"attack": enemy_data.attack_power,
		"defense": enemy_data.defense,
		"speed": enemy_data.speed,
		"critical_chance": enemy_data.critical_chance,
		"special_ability": enemy_data.special_ability,
		"description": enemy_data.description,
		"enemy_type": enemy_data.enemy_type,
		"experience": enemy_data.experience_reward,
		"portrait": enemy_data.portrait,
		"dead": is_dead
	}

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_process(false)
	if health_bar != null:
		health_bar.visible = false
	var death_tween := create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "scale", Vector2(1.15, 0.35), death_duration)
	death_tween.tween_property(self, "modulate", Color(0.55, 0.22, 0.22, 0.0), death_duration)
	death_tween.chain().tween_callback(_finish_death)

func _finish_death() -> void:
	died.emit(self)
	queue_free()
