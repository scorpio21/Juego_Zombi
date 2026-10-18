class_name ZoneDefinition
extends Node2D

## Configuración de una zona. La lógica de oleadas permanece en main.gd;
## cada escena aporta sus propios puntos de entrada, salida y clima.

@export var zone_id := "zone"
@export var display_name := "ZONA"
@export var exit_position := Vector2(1110, 620)
@export var enemy_spawn_points: PackedVector2Array = PackedVector2Array()
@export var enemy_waypoints: PackedVector2Array = PackedVector2Array()
@export var navigation_boundary: PackedVector2Array = PackedVector2Array()
@export_range(-1, 7, 1) var secondary_prop_region := -1
@export var secondary_prop_position := Vector2.ZERO
@export var secondary_prop_kind := ""
@export var secondary_prop_health := 180.0
@export var secondary_prop_size := Vector2(96, 80)
@export var secondary_prop_reward := ""
@export_range(0, 3, 1) var secondary_prop_reward_amount := 0
@export var resource_route_start := Vector2(1000, 184)
@export var resource_route_end := Vector2(540, 650)
@export var weather_bias: Array[String] = ["soleado", "lluvia", "niebla"]
@export_range(1.0, 2.5, 0.05) var difficulty_multiplier := 1.0
@export_file("*.jpg", "*.png") var backdrop_path := ""
@export_file("*.png") var exit_sprite_path := "res://assets/world/zones/zone_exit.png"
@export var enemy_pool: PackedStringArray = PackedStringArray()
@export var resource_preferences: PackedStringArray = PackedStringArray()
