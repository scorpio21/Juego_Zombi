class_name ClimateManager
extends Node

signal climate_changed(climate_name: String)

@export_category("Configuración seleccionada")
@export var settings: ClimateSettings = preload("res://resources/climate/ClimateSettings_Normal.tres") ## Preset activo. Se puede cambiar desde el Inspector.

func _ready() -> void:
	if settings == null:
		settings = ClimateSettings.new()

func get_settings() -> ClimateSettings:
	return settings

func is_enabled() -> bool:
	return settings != null and settings.climate_enabled
