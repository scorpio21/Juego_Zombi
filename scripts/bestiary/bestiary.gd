class_name Bestiary
extends Control

signal closed

var enemy_data_list: Array[Resource] = []
var unlocked_ids: Array[String] = []
var list_container: VBoxContainer
var portrait_sheet: Texture2D
var panel: Panel
var title_label: Label
var close_button: Button
var scroll: ScrollContainer
var touch_dragging := false
var touch_last_position := Vector2.ZERO

func setup(data_list: Array[Resource], unlocked: Array[String]) -> void:
	enemy_data_list = data_list
	unlocked_ids = unlocked
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	portrait_sheet = load("res://assets/zombies/zombie_types_12.png") as Texture2D
	_build_ui()
	_rebuild()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.03, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101c24")
	style.border_color = Color("3d888c")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	title_label = Label.new()
	title_label.text = "BESTIARIO DE INFECTADOS"
	title_label.add_theme_color_override("font_color", Color("dcecea"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_label)
	close_button = Button.new()
	close_button.text = "CERRAR"
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(func():
		visible = false
		closed.emit()
	)
	panel.add_child(close_button)
	scroll = ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.gui_input.connect(_on_scroll_gui_input)
	panel.add_child(scroll)
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 10)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(list_container)

func _layout_ui() -> void:
	if not is_instance_valid(panel) or not is_instance_valid(scroll):
		return
	var viewport_size := get_viewport_rect().size
	var margin_x := clampf(viewport_size.x * 0.045, 16.0, 64.0)
	var margin_y := clampf(viewport_size.y * 0.06, 14.0, 36.0)
	var panel_width := minf(980.0, maxf(300.0, viewport_size.x - margin_x * 2.0))
	var panel_height := minf(610.0, maxf(260.0, viewport_size.y - margin_y * 2.0))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = panel_height * 0.5
	var side_margin := clampf(panel_width * 0.035, 16.0, 34.0)
	title_label.position = Vector2(side_margin, 16.0)
	title_label.size = Vector2(maxf(120.0, panel_width - side_margin * 2.0 - 140.0), 42.0)
	title_label.add_theme_font_size_override("font_size", 26 if panel_width >= 700.0 else 20)
	close_button.position = Vector2(panel_width - side_margin - 116.0, 16.0)
	close_button.size = Vector2(116.0, 38.0)
	scroll.position = Vector2(side_margin, 70.0)
	scroll.size = Vector2(maxf(120.0, panel_width - side_margin * 2.0), maxf(120.0, panel_height - 88.0))

func _rebuild() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	for data in enemy_data_list:
		list_container.add_child(_make_entry(data, unlocked_ids.has(data.id)))

func _make_entry(data: Resource, unlocked: bool) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 118)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_dragging = event.pressed
		touch_last_position = event.position
		accept_event()
	elif event is InputEventScreenDrag and touch_dragging:
		var delta_y := event.position.y - touch_last_position.y
		touch_last_position = event.position
		var max_scroll := maxi(0, list_container.size.y - scroll.size.y)
		scroll.scroll_vertical = clampi(scroll.scroll_vertical - int(delta_y), 0, max_scroll)
		accept_event()
