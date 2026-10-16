class_name DestructibleObject
extends Node2D

signal destroyed(object)
signal damaged(object, ratio)

@export var object_type := "car"
@export var max_health := 100.0
@export var blocks_navigation := true
@export var explosive := false

var current_health := 100.0
var collision_size := Vector2(42, 32)
var destroyed_state := false
var _body: StaticBody2D

func setup(kind: String, health: float, size: Vector2, is_explosive := false) -> void:
	object_type = kind
	max_health = health
	current_health = health
	collision_size = size
	explosive = is_explosive
	_build_collision()
	queue_redraw()

func _build_collision() -> void:
	if _body != null:
		_body.queue_free()
	_body = StaticBody2D.new()
	_body.name = "ObstacleCollision"
	_body.collision_layer = 4
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = collision_size
	shape.shape = rectangle
	_body.add_child(shape)
	add_child(_body)

func take_damage(amount: float) -> void:
	if destroyed_state or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(self, current_health / maxf(1.0, max_health))
	queue_redraw()
	if current_health <= 0.0:
		_destroy()

func _destroy() -> void:
	if destroyed_state:
		return
	destroyed_state = true
	if _body != null:
		_body.set_deferred("collision_layer", 0)
		_body.set_deferred("collision_mask", 0)
	destroyed.emit(self)
	queue_redraw()

func collision_rect() -> Rect2:
	return Rect2(global_position - collision_size * 0.5, collision_size)

func _draw() -> void:
	if destroyed_state:
		return
	var damage_ratio := 1.0 - current_health / maxf(1.0, max_health)
	var s := clampf(1.0 - damage_ratio * 0.12, 0.88, 1.0)
	if damage_ratio > 0.18:
		draw_line(Vector2(-collision_size.x * 0.3, -collision_size.y * 0.25), Vector2(collision_size.x * 0.18, collision_size.y * 0.20), Color(0.08, 0.04, 0.04, damage_ratio), 2.0)
	if damage_ratio > 0.48:
		draw_line(Vector2(collision_size.x * 0.22, -collision_size.y * 0.32), Vector2(-collision_size.x * 0.15, collision_size.y * 0.30), Color(0.02, 0.02, 0.02, damage_ratio), 2.0)
	if damage_ratio > 0.75:
		draw_circle(Vector2.ZERO, 4.0, Color(0.08, 0.08, 0.08, 0.8))
