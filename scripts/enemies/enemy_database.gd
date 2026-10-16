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
