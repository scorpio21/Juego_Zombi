class_name Bestiary
extends Control

signal closed

var enemy_data_list: Array[Resource] = []
var unlocked_ids: Array[String] = []
var list_container: VBoxContainer
var portrait_sheet: Texture2D

func setup(data_list: Array[Resource], unlocked: Array[String]) -> void:
	enemy_data_list = data_list
	unlocked_ids = unlocked
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	portrait_sheet = load("res://assets/zombies/zombie_types_12.png") as Texture2D
	_build_ui()
	_rebuild()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.03, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(150, 55)
	panel.size = Vector2(980, 610)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101c24")
	style.border_color = Color("3d888c")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var title := Label.new()
	title.text = "BESTIARIO DE INFECTADOS"
	title.position = Vector2(34, 20)
	title.size = Vector2(700, 45)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("dcecea"))
	panel.add_child(title)
	var close := Button.new()
	close.text = "CERRAR"
	close.position = Vector2(820, 20)
	close.size = Vector2(120, 38)
	close.pressed.connect(func():
		visible = false
		closed.emit()
	)
	panel.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 78)
	scroll.size = Vector2(932, 505)
	panel.add_child(scroll)
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 10)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

func _rebuild() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	for data in enemy_data_list:
		list_container.add_child(_make_entry(data, unlocked_ids.has(data.id)))

func _make_entry(data: Resource, unlocked: bool) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(900, 118)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("182932") if unlocked else Color("111a20")
	row_style.border_color = Color("42777b") if unlocked else Color("27363b")
	row_style.set_border_width_all(1)
	row.add_theme_stylebox_override("panel", row_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(92, 92)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked and portrait_sheet != null:
		var cell := Vector2(portrait_sheet.get_width() / 4.0, portrait_sheet.get_height() / 3.0)
		var atlas := AtlasTexture.new()
		atlas.atlas = portrait_sheet
		atlas.region = Rect2(Vector2((data.sprite_index % 4) * cell.x, floori(data.sprite_index / 4.0) * cell.y), cell)
		portrait.texture = atlas
	else:
		portrait.modulate = Color(0.05, 0.07, 0.08, 1.0)
	content.add_child(portrait)
	var text := Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 15)
	if not unlocked:
		text.text = "???\n\nEncuentra este enemigo para desbloquear su ficha."
		text.add_theme_color_override("font_color", Color("7d8c91"))
	else:
		text.text = "%s  [%s]\n%s\nVida: %d   Ataque: %d   Velocidad: %.0f\nHabilidad: %s" % [data.display_name, data.rarity, data.description, data.max_health, data.attack_power, data.speed, data.special_ability]
		text.add_theme_color_override("font_color", Color("d6e7e3"))
	content.add_child(text)
	return row
