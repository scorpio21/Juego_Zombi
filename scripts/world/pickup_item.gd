class_name PickupItem
extends Area2D

## Recurso físico recogible. No contiene lógica de inventario: solo presenta
## el objeto, su animación y sus datos para que ResourceSpawner/main lo procesen.

const ICON_PATHS := {
	"ammo": "res://assets/world/loot/ammo_world.png",
	"medkit": "res://assets/world/loot/medkit_world.png",
	"scrap": "res://assets/world/loot/scrap_world.png",
	"materials": "res://assets/world/loot/materials_world.png",
	"food": "res://assets/world/loot/food_world.png",
	"water": "res://assets/world/loot/water_world.png"
}

var resource_id := "scrap"
var amount := 1
var lifetime := 0.0
var age := 0.0
var base_y := 0.0
var phase := 0.0
var _sprite: Sprite2D
var _glow: Sprite2D
var _amount_label: Label

func _ready() -> void:
	z_index = 12
	_sprite = Sprite2D.new()
	_sprite.name = "WorldSprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true
	_sprite.position = Vector2(0.0, -10.0)
	add_child(_sprite)

	_glow = Sprite2D.new()
	_glow.name = "SoftGlow"
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow.modulate = Color(0.35, 0.95, 1.0, 0.18)
	_glow.position = _sprite.position
	_glow.z_index = -1
	add_child(_glow)

	_amount_label = Label.new()
	_amount_label.name = "Amount"
	_amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amount_label.position = Vector2(-24.0, 18.0)
	_amount_label.size = Vector2(48.0, 18.0)
	_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount_label.add_theme_font_size_override("font_size", 11)
	_amount_label.add_theme_color_override("font_color", Color("d9f4ef"))
	_amount_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_amount_label.add_theme_constant_override("shadow_offset_x", 1)
	_amount_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_amount_label)

	queue_redraw()

func setup(kind: String, quantity: int = 1, item_lifetime: float = 42.0, item_phase: float = 0.0) -> void:
	resource_id = kind.to_lower().strip_edges()
	amount = maxi(1, quantity)
	lifetime = maxf(0.0, item_lifetime)
	phase = item_phase
	base_y = position.y
	if _sprite == null:
		return
	var texture := load(str(ICON_PATHS.get(resource_id, ""))) as Texture2D
	if texture == null:
		push_warning("[PickupItem] No se pudo cargar el sprite de %s" % resource_id)
		return
	_sprite.texture = texture
	_glow.texture = texture
	var item_scale := 58.0 / maxf(float(texture.get_width()), float(texture.get_height()))
	_sprite.scale = Vector2.ONE * item_scale
	_glow.scale = _sprite.scale * 1.14
	_glow.modulate = _glow_color(resource_id)
	_amount_label.text = "+%d" % amount if amount > 1 else ""
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	var bob := sin(age * 2.4 + phase) * 3.0
	_sprite.position.y = -10.0 + bob
	_glow.position = _sprite.position
	var breathe := 1.0 + sin(age * 2.0 + phase) * 0.045
	_sprite.scale = Vector2.ONE * _base_scale() * breathe
	_glow.scale = _sprite.scale * 1.14
	if lifetime > 0.0 and age >= lifetime:
		queue_free()
	queue_redraw()

func _draw() -> void:
	# Sombra elíptica independiente del sprite para anclarlo visualmente al suelo.
	draw_set_transform(Vector2(0.0, 9.0), 0.0, Vector2(1.35, 0.42))
	draw_circle(Vector2.ZERO, 18.0, Color(0.0, 0.0, 0.0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _base_scale() -> float:
	if _sprite == null or _sprite.texture == null:
		return 1.0
	return 58.0 / maxf(float(_sprite.texture.get_width()), float(_sprite.texture.get_height()))

func _glow_color(kind: String) -> Color:
	match kind:
		"ammo": return Color(0.30, 0.85, 0.95, 0.22)
		"medkit": return Color(0.95, 0.30, 0.32, 0.20)
		"scrap": return Color(0.95, 0.65, 0.28, 0.18)
		"materials": return Color(0.85, 0.48, 0.25, 0.18)
		"food": return Color(0.78, 0.76, 0.32, 0.18)
		"water": return Color(0.28, 0.70, 0.95, 0.22)
	return Color(0.6, 0.9, 0.9, 0.18)
