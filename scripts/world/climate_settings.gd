class_name ClimateSettings
extends Resource

@export_category("Sistema climático")
@export var climate_enabled: bool = true ## Activa los efectos visuales y gameplay del clima.
@export var configuration_name: String = "Normal" ## Nombre visible de esta configuración.

@export_category("Duración de ciclos")
@export_range(30.0, 1800.0, 1.0, "suffix:s") var day_duration: float = 180.0 ## Duración base del periodo diurno.
@export_range(30.0, 1800.0, 1.0, "suffix:s") var night_duration: float = 120.0 ## Duración base del periodo nocturno.

@export_category("Probabilidades de clima")
@export_range(0.0, 1.0, 0.01) var rain_probability: float = 0.28 ## Probabilidad relativa de lluvia.
@export_range(0.0, 1.0, 0.01) var fog_probability: float = 0.18 ## Probabilidad relativa de niebla.
@export_range(0.0, 1.0, 0.01) var storm_probability: float = 0.12 ## Probabilidad relativa de tormenta.
@export_range(0.0, 1.0, 0.01) var wind_probability: float = 0.16 ## Probabilidad relativa de viento.
@export_range(0.0, 1.0, 0.01) var red_moon_probability: float = 0.04 ## Probabilidad relativa de luna roja.
@export_range(0.0, 1.0, 0.01) var toxic_ash_probability: float = 0.03 ## Probabilidad relativa de ceniza tóxica.
@export_range(0.0, 1.0, 0.01) var heat_wave_probability: float = 0.05 ## Probabilidad relativa de ola de calor.

@export_category("Intensidad visual")
@export_range(0.0, 2.0, 0.01) var rain_intensity: float = 1.0 ## Multiplicador visual de lluvia.
@export_range(0.0, 2.0, 0.01) var fog_intensity: float = 1.0 ## Multiplicador visual de niebla.
@export_range(0.2, 30.0, 0.1, "suffix:s") var lightning_frequency: float = 5.5 ## Tiempo medio entre relámpagos.

@export_category("Dificultad nocturna")
@export_range(0.0, 0.25, 0.001) var night_zombie_bonus: float = 0.01 ## Bonificación base de vida/daño nocturna.

@export_category("Impacto en recursos")
@export_range(0.5, 3.0, 0.05) var rain_resource_multiplier: float = 1.25 ## Más suministros de agua con lluvia.
@export_range(0.5, 3.0, 0.05) var fog_supply_multiplier: float = 1.35 ## Más suministros abandonados con niebla.
@export_range(0.5, 3.0, 0.05) var storm_material_multiplier: float = 1.50 ## Más materiales tras una tormenta.

@export_category("Transiciones")
@export_range(0.1, 10.0, 0.1, "suffix:s") var climate_transition_speed: float = 1.8 ## Duración del fundido entre climas.
@export_range(10.0, 1800.0, 1.0, "suffix:s") var min_change_interval: float = 75.0 ## Tiempo mínimo entre cambios.
@export_range(10.0, 2400.0, 1.0, "suffix:s") var max_change_interval: float = 150.0 ## Tiempo máximo entre cambios.

func duplicate_settings() -> ClimateSettings:
	return duplicate(true) as ClimateSettings
