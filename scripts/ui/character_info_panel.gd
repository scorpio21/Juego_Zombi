class_name CharacterInfoPanel
extends Control

signal closed

var info: Dictionary = {}
var title_label: Label
var portrait_view: TextureRect
var health_bar: ProgressBar
var details_label: Label
var description_label: Label

func _ready() -> void:
	_build_ui()
	visible = false

func show_character(character_info: Dictionary) -> void:
	info = character_info
	if title_label == null:
		_build_ui()
	_refresh()
	visible = true
	move_to_front()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := Panel.new()
	panel.name = "RpgPanel"
	panel.position = Vector2(350, 100)
	panel.size = Vector2(580, 520)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("111e28")
	panel_style.border_color = Color("8aa86d")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	title_label = Label.new()
	title_label.position = Vector2(28, 20)
	title_label.size = Vector2(420, 38)
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_color_override("font_color", Color("f0d28a"))
	panel.add_child(title_label)
	var close := Button.new()
	close.text = "CERRAR"
	close.position = Vector2(445, 20)
	close.size = Vector2(105, 36)
	close.pressed.connect(_close)
	panel.add_child(close)
	portrait_view = TextureRect.new()
	portrait_view.position = Vector2(28, 78)
	portrait_view.size = Vector2(150, 150)
	portrait_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait_view)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(210, 82)
	health_bar.size = Vector2(330, 20)
	health_bar.show_percentage = false
	var health_bg := StyleBoxFlat.new()
	health_bg.bg_color = Color("263139")
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("d53d4d")
	health_bar.add_theme_stylebox_override("background", health_bg)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	panel.add_child(health_bar)
	details_label = Label.new()
	details_label.position = Vector2(210, 116)
	details_label.size = Vector2(330, 230)
	details_label.add_theme_font_size_override("font_size", 16)
	details_label.add_theme_color_override("font_color", Color("d5e3df"))
	panel.add_child(details_label)
	description_label = Label.new()
	description_label.position = Vector2(28, 255)
	description_label.size = Vector2(512, 95)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 15)
	description_label.add_theme_color_override("font_color", Color("aabbb8"))
	panel.add_child(description_label)

func _refresh() -> void:
	var dead := bool(info.get("dead", false))
	title_label.text = "%s%s" % [str(info.get("name", "Personaje")), "  —  MUERTO" if dead else ""]
	title_label.add_theme_color_override("font_color", Color("b76b72") if dead else Color("f0d28a"))
	var max_health := float(info.get("max_health", 0.0))
	health_bar.max_value = max_health
	health_bar.value = clampf(float(info.get("current_health", 0.0)), 0.0, max_health)
	details_label.text = "Vida: %d / %d\nAtaque: %d\nDefensa: %d\nVelocidad: %.0f\nCrítico: %.0f%%\nTipo: %s\nExperiencia: %d\n\nHabilidad: %s" % [int(info.get("current_health", 0.0)), int(max_health), int(info.get("attack", 0)), int(info.get("defense", 0)), float(info.get("speed", 0.0)), float(info.get("critical_chance", 0.0)) * 100.0, str(info.get("enemy_type", "Personaje")), int(info.get("experience", 0)), str(info.get("special_ability", "Ninguna"))]
	description_label.text = str(info.get("description", "Sin descripción."))
	var portrait = info.get("portrait")
	portrait_view.texture = portrait if portrait is Texture2D else null
	portrait_view.modulate = Color(0.42, 0.42, 0.42, 1.0) if dead else Color.WHITE

func _close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()

