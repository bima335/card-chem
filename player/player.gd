class_name Player
extends Node

signal coins_updated(oxygen: int, hydrogen: int, carbon: int, nitrogen: int)
signal stats_updated(hp: int, max_hp: int, shield: int, damage: int)

const MAX_TOKEN: int = 7

@export var oxygen: int = 0
@export var hydrogen: int = 0
@export var carbon: int = 0
@export var nitrogen: int = 0

@export var max_hp: int = GameManager.player_max_hp
var current_hp: int = GameManager.player_current_hp
var shield: int = 0
@export var base_damage: int = 0

func _ready() -> void:
	if not EventBus.player_took_damage.is_connected(take_damage):
		EventBus.player_took_damage.connect(take_damage)

func reset_for_battle() -> void:
	shield = 0
	carbon = 3
	hydrogen = 3
	oxygen = 3
	nitrogen = 3
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
	stats_updated.emit(current_hp, max_hp, shield, base_damage)

func add_tokens(c: int, h: int, o: int, n: int) -> void:
	carbon = clampi(carbon + c, 0, MAX_TOKEN)
	hydrogen = clampi(hydrogen + h, 0, MAX_TOKEN)
	oxygen = clampi(oxygen + o, 0, MAX_TOKEN)
	nitrogen = clampi(nitrogen + n, 0, MAX_TOKEN)
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)

func gain_tokens(amount:int):
	carbon = clampi(carbon + amount, 0, MAX_TOKEN)
	hydrogen = clampi(hydrogen + amount, 0, MAX_TOKEN)
	oxygen = clampi(oxygen + amount, 0, MAX_TOKEN)
	nitrogen = clampi(nitrogen + amount, 0, MAX_TOKEN)
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)

func gain_shield(amount: int) -> void:
	shield += amount
	stats_updated.emit(current_hp, max_hp, shield, base_damage)

func take_damage(amount: int) -> void:
	var actual_damage = amount - shield
	if actual_damage > 0:
		shield = 0
		current_hp -= actual_damage
	else:
		shield -= amount
		
	current_hp = clampi(current_hp, 0, max_hp)
	GameManager.player_current_hp = current_hp
	stats_updated.emit(current_hp, max_hp, shield, base_damage)
	
	if current_hp <= 0:
		print("HP Habis! GAME OVER!")

func heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	GameManager.player_current_hp = current_hp
	stats_updated.emit(current_hp, max_hp, shield, base_damage)

func can_afford(card: CardData) -> bool:
	return oxygen >= card.cost_oxygen and hydrogen >= card.cost_hydrogen and carbon >= card.cost_carbon and nitrogen >= card.cost_nitrogen

func pay_for_card(card: CardData) -> void:
	carbon = clampi(carbon - card.cost_carbon, 0, MAX_TOKEN)
	hydrogen = clampi(hydrogen - card.cost_hydrogen, 0, MAX_TOKEN)
	oxygen = clampi(oxygen - card.cost_oxygen, 0, MAX_TOKEN)
	nitrogen = clampi(nitrogen - card.cost_nitrogen, 0, MAX_TOKEN)
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
