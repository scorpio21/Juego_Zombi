class_name BuffIndicator
extends Node2D

## Indicadores visuales de buffs activos sobre el jugador.
## Los buffs se registran por ID y pueden ser permanentes (duration <= 0)
## o temporales (duration > 0), sin que el sistema principal conozca su UI.

const ICON_PATHS := {
	"ammo": "res://assets/ui/buffs/buff_ammo.png",
	"damage": "res://assets/ui/buffs/buff_damage.png",
	"speed": "res://assets/ui/buffs/buff_speed.png",
	"shield": "res://assets/ui/buffs/buff_shield.png",
	"heal": "res://assets/ui/buffs/buff_heal.png",
	"xp": "res://assets/ui/buffs/buff_xp.png"
}

@export var icon_size := 42.0
@export var icon_gap := 8.0
@export var anchor_height := 82.0
@export var icon_float_amplitude := 3.0

var _active: Dictionary = {}
var _order: Array[String] = []

func _ready() -> void:
	z_index = 25
	visible = false

func add_buff(buff_id: String, duration: float = -1.0) -> void:
	var normalized := buff_id.to_lower().strip_edges()
	if not ICON_PATHS.has(normalized):
		push_warning("[BuffIndicator] Buff sin icono registrado: %s" % buff_id)
		return
	if _active.has(normalized):
		var existing: Dictionary = _active[normalized]
		existing["duration"] = duration
		existing["life"] = duration
		_active[normalized] = existing
		visible = true
		return
	var texture := load(str(ICON_PATHS[normalized])) as Texture2D
	if texture == null:
		push_warning("[BuffIndicator] No se pudo cargar: %s" % ICON_PATHS[normalized])
		return
	var icon := Sprite2D.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.centered = true
	icon.z_index = 1
	icon.scale = Vector2.ONE * _texture_scale(texture)
	add_child(icon)
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.modulate = Color(0.35, 0.95, 1.0, 0.22)
	glow.scale = icon.scale * 1.16
	glow.z_index = 0
	icon.add_sibling(glow)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.85, 0.96, 1.0, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.size = Vector2(80.0, 18.0)
	label.position = Vector2(-40.0, 25.0)
	label.visible = duration > 0.0
	add_child(label)
	_active[normalized] = {
		"icon": icon,
		"glow": glow,
		"label": label,
		"duration": duration,
		"life": duration,
		"phase": float(_order.size()) * 0.8
	}
	_order.append(normalized)
	visible = true
	_layout_icons()

func remove_buff(buff_id: String) -> void:
	var normalized := buff_id.to_lower().strip_edges()
	if not _active.has(normalized):
		return
	var entry: Dictionary = _active[normalized]
	var icon: Node = entry.get("icon")
	var glow: Node = entry.get("glow")
	var label: Node = entry.get("label")
	if is_instance_valid(icon):
		icon.queue_free()
	if is_instance_valid(glow):
		glow.queue_free()
	if is_instance_valid(label):
		label.queue_free()
	_active.erase(normalized)
	_order.erase(normalized)
	_layout_icons()
	visible = not _active.is_empty()

func clear_buffs() -> void:
	for buff_id in _order.duplicate():
		remove_buff(buff_id)

func has_buff(buff_id: String) -> bool:
	return _active.has(buff_id.to_lower().strip_edges())

func _process(delta: float) -> void:
	if _active.is_empty():
		return
	var expired: Array[String] = []
	for buff_id in _order:
		var entry: Dictionary = _active[buff_id]
		var duration := float(entry["duration"])
		if duration > 0.0:
			entry["life"] = float(entry["life"]) - delta
			if float(entry["life"]) <= 0.0:
				expired.append(buff_id)
				continue
			var label: Label = entry["label"]
			label.text = "%0.1fs" % maxf(0.0, float(entry["life"]))
		var phase := float(entry["phase"]) + Time.get_ticks_msec() * 0.004
		var float_offset := sin(phase) * icon_float_amplitude
		var icon: Sprite2D = entry["icon"]
		var glow: Sprite2D = entry["glow"]
		icon.position.y = -anchor_height + float_offset
		glow.position = icon.position
		var breathe := 1.0 + sin(phase * 1.15) * 0.045
		icon.scale = Vector2.ONE * _texture_scale(icon.texture) * breathe
		glow.scale = icon.scale * 1.16
	for buff_id in expired:
		_remove_with_fade(buff_id)

func _remove_with_fade(buff_id: String) -> void:
	if not _active.has(buff_id):
		return
	var entry: Dictionary = _active[buff_id]
	var icon: Sprite2D = entry["icon"]
	var glow: Sprite2D = entry["glow"]
	var label: Label = entry["label"]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(icon, "modulate:a", 0.0, 0.22)
	tween.tween_property(glow, "modulate:a", 0.0, 0.22)
	tween.tween_property(label, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(remove_buff.bind(buff_id))

func _layout_icons() -> void:
	var count := _order.size()
	for i in range(count):
		var entry: Dictionary = _active[_order[i]]
		var icon: Sprite2D = entry["icon"]
		var glow: Sprite2D = entry["glow"]
		var label: Label = entry["label"]
		var x := (float(i) - float(count - 1) * 0.5) * (icon_size + icon_gap)
		icon.position = Vector2(x, -anchor_height)
		glow.position = icon.position
		# Cada contador sigue a su propio icono; evita que varios buffs se solapen.
		label.position = Vector2(x - 40.0, 25.0)

func _texture_scale(texture: Texture2D) -> float:
	return icon_size / maxf(float(texture.get_width()), float(texture.get_height()))
