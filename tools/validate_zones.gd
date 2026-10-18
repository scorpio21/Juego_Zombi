extends SceneTree

const ZONE_SCENES := [
	"res://scenes/world/zones/forest.tscn",
	"res://scenes/world/zones/road.tscn",
	"res://scenes/world/zones/gas_station.tscn",
	"res://scenes/world/zones/town.tscn",
	"res://scenes/world/zones/hospital.tscn",
	"res://scenes/world/zones/industrial_zone.tscn",
	"res://scenes/world/zones/military_base.tscn"
]

const VALID_RESOURCES := [&"ammo", &"medkit", &"scrap", &"materials", &"food", &"water"]
const ENEMY_DATABASE_SCRIPT := preload("res://scripts/enemies/enemy_database.gd")

func _init() -> void:
	var enemy_ids: Array[String] = []
	for enemy_data in ENEMY_DATABASE_SCRIPT.all():
		enemy_ids.append(str(enemy_data.id))

	var failures := 0
	for scene_path in ZONE_SCENES:
		var scene := load(scene_path) as PackedScene
		if scene == null:
			_fail(scene_path, "no se pudo cargar la escena")
			failures += 1
			continue
		var definition := scene.instantiate()
		if definition == null:
			_fail(scene_path, "la escena no instancia un nodo de zona")
			failures += 1
			continue
		var zone_failures := _validate_zone(scene_path, definition, enemy_ids)
		failures += zone_failures
		definition.free()

	if failures == 0:
		print("[ZONE VALIDATOR] OK: %d zonas verificadas." % ZONE_SCENES.size())
	else:
		push_error("[ZONE VALIDATOR] Fallos encontrados: %d" % failures)
	quit(1 if failures > 0 else 0)

func _validate_zone(scene_path: String, definition: Node, enemy_ids: Array[String]) -> int:
	var failures := 0
	var zone_id := str(definition.get("zone_id"))
	if zone_id.is_empty():
		_fail(scene_path, "zone_id vacío")
		failures += 1
	if str(definition.get("display_name")).is_empty():
		_fail(scene_path, "display_name vacío")
		failures += 1
	if definition.get("enemy_spawn_points").is_empty():
		_fail(scene_path, "sin puntos de aparición")
		failures += 1
	if definition.get("enemy_waypoints").size() < 2:
		_fail(scene_path, "faltan waypoints de enemigos")
		failures += 1
	if definition.get("navigation_boundary").size() < 3:
		_fail(scene_path, "límite de navegación incompleto")
		failures += 1
	if not FileAccess.file_exists(str(definition.get("backdrop_path"))):
		_fail(scene_path, "backdrop inexistente: %s" % definition.get("backdrop_path"))
		failures += 1
	if not FileAccess.file_exists(str(definition.get("exit_sprite_path"))):
		_fail(scene_path, "sprite de salida inexistente: %s" % definition.get("exit_sprite_path"))
		failures += 1
	for enemy_id in definition.get("enemy_pool"):
		if str(enemy_id) not in enemy_ids:
			_fail(scene_path, "enemigo inexistente en pool: %s" % enemy_id)
			failures += 1
	for resource_id in definition.get("resource_preferences"):
		if StringName(str(resource_id)) not in VALID_RESOURCES:
			_fail(scene_path, "recurso inexistente en preferencias: %s" % resource_id)
			failures += 1
	var secondary_region := int(definition.get("secondary_prop_region"))
	if secondary_region < 0 or secondary_region > 7:
		_fail(scene_path, "región secundaria fuera del atlas: %d" % secondary_region)
		failures += 1
	var reward_kind := str(definition.get("secondary_prop_reward"))
	if not reward_kind.is_empty() and StringName(reward_kind) not in VALID_RESOURCES:
		_fail(scene_path, "recompensa de contenedor inexistente: %s" % reward_kind)
		failures += 1
	if not reward_kind.is_empty() and int(definition.get("secondary_prop_reward_amount")) <= 0:
		_fail(scene_path, "contenedor con recompensa de cantidad no válida")
		failures += 1
	return failures

func _fail(scene_path: String, message: String) -> void:
	push_error("[ZONE VALIDATOR] %s: %s" % [scene_path, message])
