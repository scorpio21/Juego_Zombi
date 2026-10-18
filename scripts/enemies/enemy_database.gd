class_name EnemyDatabase
extends RefCounted

const ENEMY_DATA_SCRIPT = preload("res://scripts/enemies/enemy_data.gd")

static func all() -> Array[Resource]:
	var result: Array[Resource] = []
	result.append(_make("worker", "Zombi trabajador", "Conserva parte de su uniforme y avanza sin detenerse.", 90, 8, 56.0, "Ninguna", "Común", 0))
	result.append(_make("police", "Zombi policía", "Más resistente gracias a su equipo de protección.", 150, 14, 52.0, "Armadura ligera", "Poco común", 1))
	result.append(_make("soldier", "Zombi soldado", "Entrenamiento militar convertido en una amenaza letal.", 190, 20, 64.0, "Resistencia al daño", "Raro", 2))
	result.append(_make("construction", "Zombi de construcción", "Su casco y herramientas todavía le sirven como defensa.", 220, 18, 43.0, "Golpe pesado", "Poco común", 3))
	result.append(_make("scientist", "Zombi científico", "Una mutación experimental altera su comportamiento.", 120, 12, 70.0, "Explosión tóxica", "Raro", 4))
	result.append(_make("nurse", "Zombi enfermero", "Su uniforme oculta una criatura sorprendentemente veloz.", 105, 10, 78.0, "Regeneración", "Poco común", 5))
	result.append(_make("civilian", "Civil infectado", "El tipo más frecuente entre los supervivientes caídos.", 80, 7, 60.0, "Ninguna", "Común", 6))
	result.append(_make("burned", "Zombi quemado", "El fuego no consiguió detenerlo, pero sí deformarlo.", 170, 16, 48.0, "Inmune al fuego", "Raro", 7))
	result.append(_make("toxic", "Zombi tóxico", "Su cuerpo libera fluidos contaminantes al ser herido.", 135, 15, 58.0, "Nube venenosa", "Raro", 8))
	result.append(_make("mutant", "Zombi mutante", "Una masa de músculos y huesos desarrollada por la infección.", 300, 28, 45.0, "Furia", "Épico", 9))
	result.append(_make("armored", "Zombi blindado", "El blindaje improvisado convierte cada encuentro en un duelo.", 360, 24, 38.0, "Armadura pesada", "Épico", 10))
	result.append(_make("runner", "Zombi corredor", "Su metabolismo alterado lo hace difícil de apuntar.", 75, 13, 108.0, "Velocidad extrema", "Raro", 11))
	result.append(_make_zone_variant("forest_stalker", "Acechador del bosque", "Se camufla entre la vegetación y ataca desde los márgenes del camino.", 145, 15, 86.0, "Emboscada", "Raro", 11, "forest", Color("b7d47a")))
	result.append(_make_zone_variant("road_raider", "Saqueador de carretera", "Conserva restos de protección y embiste por la carretera abandonada.", 175, 19, 62.0, "Carga brutal", "Raro", 6, "road", Color("8ea9b4")))
	result.append(_make_zone_variant("gas_burner", "Quemado de la gasolinera", "Los vapores y el fuego lo han convertido en una amenaza inestable.", 245, 24, 52.0, "Explosión incendiaria", "Épico", 7, "gas_station", Color("f0a05b")))
	result.append(_make_zone_variant("town_howler", "Aullador del pueblo", "Su chillido desorienta a los supervivientes y atrae a otros infectados.", 155, 18, 76.0, "Alarido", "Raro", 8, "town", Color("a8b2bd")))
	result.append(_make_zone_variant("hospital_carrier", "Portador del hospital", "Una infección resistente mantiene su cuerpo activo pese a las heridas.", 210, 21, 68.0, "Regeneración", "Épico", 5, "hospital", Color("c7d6c8")))
	result.append(_make_zone_variant("industrial_brute", "Bruto industrial", "Su cuerpo se ha endurecido entre maquinaria y residuos tóxicos.", 430, 32, 42.0, "Golpe demoledor", "Épico", 10, "industrial_zone", Color("d18a62")))
	result.append(_make_zone_variant("military_elite", "Élite infectado", "Mantiene disciplina y resistencia de combate incluso después de la infección.", 500, 36, 56.0, "Blindaje táctico", "Legendario", 2, "military_base", Color("91a9d1")))
	result.append(_make_zone_variant("forest_skinned_runner", "Corredor desollado", "Un infectado veloz que atraviesa el bosque con una carrera irregular y agresiva.", 82, 14, 132.0, "Carrera desgarradora", "Raro", 12, "forest", Color.WHITE))
	result.append(_make_zone_variant("infected_lumberjack", "Leñador infectado", "Conserva un hacha rota y una fuerza cuerpo a cuerpo capaz de derribar a un superviviente.", 285, 30, 44.0, "Golpe de hacha", "Épico", 13, "forest", Color.WHITE))
	result.append(_make_zone_variant("forest_beast", "Bestia del bosque", "Una masa de raíces, carne y huesos que resiste grandes cantidades de daño.", 520, 38, 36.0, "Embestida brutal", "Legendario", 14, "forest", Color.WHITE))
	return result

static func by_id(enemy_id: String) -> Resource:
	for data in all():
		if data.id == enemy_id:
			return data
	return null

static func _make(enemy_id: String, title: String, text: String, health: int, attack: int, move_speed: float, ability: String, rarity_name: String, index: int) -> Resource:
	var data = ENEMY_DATA_SCRIPT.new()
	data.id = enemy_id
	data.display_name = title
	data.description = text
	data.max_health = health
	data.attack_power = attack
	data.speed = move_speed
	data.defense = maxi(0, health / 30)
	data.critical_chance = 0.05 + float(index % 4) * 0.02
	data.special_ability = ability
	data.rarity = rarity_name
	data.sprite_index = index
	data.enemy_type = "Zombie"
	data.experience_reward = 10 + index * 5
	data.level = 1 + index / 4
	return data

static func _make_zone_variant(enemy_id: String, title: String, text: String, health: int, attack: int, move_speed: float, ability: String, rarity_name: String, sprite_index: int, zone_id: String, tint: Color) -> Resource:
	var data = _make(enemy_id, title, text, health, attack, move_speed, ability, rarity_name, sprite_index)
	data.zone_id = zone_id
	data.visual_tint = tint
	return data
