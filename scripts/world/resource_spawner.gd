class_name ResourceSpawner
extends Node2D

## Generador limitado de loot. Las posiciones se calculan durante la partida;
## no requiere nodos colocados a mano en el mapa.

const PICKUP_SCENE := preload("res://scenes/world/PickupItem.tscn")
const RESOURCE_DEFINITIONS := {
	"ammo": {"max": 5, "amount": 6, "weight": 24.0},
	"medkit": {"max": 3, "amount": 1, "weight": 8.0},
	"scrap": {"max": 5, "amount": 1, "weight": 25.0},
	"materials": {"max": 5, "amount": 1, "weight": 18.0},
	"food": {"max": 3, "amount": 1, "weight": 10.0},
	"water": {"max": 3, "amount": 1, "weight": 15.0}
}

## Corredor jugable de la carretera principal. Los recursos no se generan
## mediante un rectángulo global porque eso los dejaba sobre aceras y edificios.
@export var route_start := Vector2(1000.0, 184.0)
@export var route_end := Vector2(540.0, 650.0)
@export var route_half_width := 62.0
@export var min_spawn_seconds := 5.0
@export var max_spawn_seconds := 11.0
@export var max_active_total := 12
@export var min_distance_to_player := 120.0
@export var min_distance_between_items := 86.0
@export var max_item_lifetime := 48.0
@export var candidate_attempts := 18

var _rng := RandomNumberGenerator.new()
var _spawn_timer := 0.0
var _active: Array[PickupItem] = []
var _weather := "soleado"
var _pending_requests := 0
var _pending_kind := ""

func _ready() -> void:
	_rng.randomize()
	_reset_timer()

func clear() -> void:
	for pickup in _active:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_active.clear()
	_pending_requests = 0
	_pending_kind = ""
	_reset_timer()

func tick(delta: float, player_position: Vector2, props: Array, actors: Array = []) -> void:
	_prune_invalid()
	_spawn_timer -= delta
	if _active.size() >= max_active_total:
		return
	if _pending_requests <= 0 and _spawn_timer > 0.0:
		return
	_spawn_one(player_position, props, actors)
	if _pending_requests > 0:
		_pending_requests -= 1
		if _pending_requests <= 0:
			_pending_kind = ""
	else:
		_reset_timer()

func request_spawn(amount: int, preferred_kind: String = "") -> void:
	# La solicitud se ejecuta en el siguiente frame mediante posiciones válidas;
	# sirve para que las oleadas o el clima aporten recursos sin inundar el mapa.
	_pending_requests = mini(8, _pending_requests + clampi(amount, 0, 3))
	_spawn_timer = minf(_spawn_timer, 0.05)
	if not preferred_kind.is_empty():
		_pending_kind = preferred_kind

func set_weather(value: String) -> void:
	_weather = value

func get_active_pickups() -> Array[PickupItem]:
	_prune_invalid()
	return _active.duplicate()

func remove_pickup(pickup: PickupItem) -> void:
	if not is_instance_valid(pickup):
		return
	_active.erase(pickup)
	pickup.queue_free()

func _spawn_one(player_position: Vector2, props: Array, actors: Array) -> void:
	if _active.size() >= max_active_total:
		return
	var kind := _pending_kind if not _pending_kind.is_empty() else _choose_kind()
	_pending_kind = ""
	var definition: Dictionary = RESOURCE_DEFINITIONS.get(kind, RESOURCE_DEFINITIONS["scrap"])
	if _count_kind(kind) >= int(definition["max"]):
		kind = _choose_kind()
		definition = RESOURCE_DEFINITIONS.get(kind, RESOURCE_DEFINITIONS["scrap"])
	if _count_kind(kind) >= int(definition["max"]):
		return
	for attempt in range(candidate_attempts):
		var route_direction := route_start.direction_to(route_end)
		var route_normal := Vector2(-route_direction.y, route_direction.x)
		var route_t := _rng.randf_range(0.04, 0.96)
		var route_center := route_start.lerp(route_end, route_t)
		var candidate := route_center + route_normal * _rng.randf_range(-route_half_width, route_half_width)
		candidate += route_direction * _rng.randf_range(-18.0, 18.0)
		candidate.y = maxf(candidate.y, 178.0)
		if not _is_valid_position(candidate, player_position, props, actors):
			continue
		var pickup := PICKUP_SCENE.instantiate() as PickupItem
		if pickup == null:
			return
		pickup.position = candidate
		add_child(pickup)
		pickup.setup(kind, int(definition["amount"]), max_item_lifetime, _rng.randf_range(0.0, TAU))
		_active.append(pickup)
		return

func _is_valid_position(candidate: Vector2, player_position: Vector2, props: Array, actors: Array) -> bool:
	if candidate.distance_to(player_position) < min_distance_to_player:
		return false
	for pickup in _active:
		if is_instance_valid(pickup) and candidate.distance_to(pickup.position) < min_distance_between_items:
			return false
	for actor in actors:
		var actor_position: Vector2 = actor.get("pos", Vector2.INF)
		if candidate.distance_to(actor_position) < 58.0:
			return false
	for prop in props:
		var object = prop.get("node")
		if is_instance_valid(object) and not object.destroyed_state and object.collision_rect().grow(18.0).has_point(candidate):
			return false
	return true

func _choose_kind(ignore_cap := false) -> String:
	var candidates: Array[String] = []
	var total_weight := 0.0
	for kind in RESOURCE_DEFINITIONS:
		var definition: Dictionary = RESOURCE_DEFINITIONS[kind]
		if not ignore_cap and _count_kind(kind) >= int(definition["max"]):
			continue
		var weight := float(definition["weight"])
		if _weather == "lluvia" and kind == "water":
			weight *= 2.2
		elif _weather == "tormenta" and kind == "materials":
			weight *= 2.0
		elif _weather == "niebla" and kind in ["food", "medkit"]:
			weight *= 1.7
		elif _weather == "ola_calor" and kind == "water":
			weight *= 2.0
		candidates.append(kind)
		total_weight += weight
	if candidates.is_empty():
		return "scrap"
	var roll := _rng.randf_range(0.0, total_weight)
	for kind in candidates:
		var definition: Dictionary = RESOURCE_DEFINITIONS[kind]
		var weight := float(definition["weight"])
		if _weather == "lluvia" and kind == "water": weight *= 2.2
		elif _weather == "tormenta" and kind == "materials": weight *= 2.0
		elif _weather == "niebla" and kind in ["food", "medkit"]: weight *= 1.7
		elif _weather == "ola_calor" and kind == "water": weight *= 2.0
		roll -= weight
		if roll <= 0.0:
			return kind
	return candidates.back()

func _count_kind(kind: String) -> int:
	var total := 0
	for pickup in _active:
		if is_instance_valid(pickup) and pickup.resource_id == kind:
			total += 1
	return total

func _prune_invalid() -> void:
	for i in range(_active.size() - 1, -1, -1):
		if not is_instance_valid(_active[i]):
			_active.remove_at(i)

func _reset_timer() -> void:
	_spawn_timer = _rng.randf_range(min_spawn_seconds, max_spawn_seconds)

