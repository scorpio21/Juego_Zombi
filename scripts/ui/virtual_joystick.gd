extends Control

signal vector_changed(value: Vector2)
signal released

@export var radius := 68.0
@export var knob_radius := 28.0
@export var deadzone := 0.12

var _pointer_id := -1
var _value := Vector2.ZERO
var _knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius * 2.0 + 24.0, radius * 2.0 + 24.0)
	_knob = size * 0.5
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _pointer_id == -1:
		_knob = size * 0.5
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _pointer_id == -1:
			_pointer_id = event.index
			_update_from_position(event.position)
			accept_event()
		elif not event.pressed and event.index == _pointer_id:
			_reset()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		_update_from_position(event.position)
		accept_event()

func _update_from_position(position: Vector2) -> void:
	var center := size * 0.5
	var delta := position - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	var normalized := delta / radius
	if normalized.length() < deadzone:
		normalized = Vector2.ZERO
	_value = normalized
	_knob = center + delta
	vector_changed.emit(_value)
	queue_redraw()

func _reset() -> void:
	_pointer_id = -1
	_value = Vector2.ZERO
	_knob = size * 0.5
	released.emit()
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func get_value() -> Vector2:
	return _value

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center + Vector2(0.0, 8.0), radius + 8.0, Color(0.0, 0.0, 0.0, 0.30))
	draw_circle(center, radius, Color(0.025, 0.10, 0.13, 0.72))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.25, 0.86, 0.78, 0.55), 3.0, true)
	draw_arc(center, radius - 10.0, 0.0, TAU, 64, Color(0.25, 0.86, 0.78, 0.16), 2.0, true)
	draw_circle(_knob + Vector2(0.0, 4.0), knob_radius + 4.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(_knob, knob_radius, Color(0.10, 0.72, 0.67, 0.82))
	draw_arc(_knob, knob_radius, 0.0, TAU, 40, Color(0.55, 1.0, 0.92, 0.85), 2.0, true)
