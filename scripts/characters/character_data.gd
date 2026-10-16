class_name CharacterData
extends Resource

@export var id: String = "character"
@export var display_name: String = "Personaje"
@export var description: String = ""
@export var level: int = 1
@export var max_health: int = 100
@export var attack_power: int = 10
@export var defense: int = 0
@export var speed: float = 100.0
@export var attack_range: float = 180.0
@export_range(0.0, 1.0, 0.01) var critical_chance: float = 0.05
@export var special_ability: String = "Ninguna"
@export var portrait: Texture2D

