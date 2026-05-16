class_name Player
extends Node

@export var oxygen: int = 10
@export var hydrogen: int = 10
@export var carbon: int = 10
@export var nitrogen: int = 10

signal coins_updated(oxygen: int, hydrogen: int, carbon: int, nitrogen: int)

func _ready() -> void:
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)

func can_afford(card: CardData) -> bool:
	return oxygen >= card.cost_oxygen and hydrogen >= card.cost_hydrogen and carbon >= card.cost_carbon and nitrogen >= card.cost_nitrogen

func pay_for_card(card: CardData):
	oxygen -= card.cost_oxygen
	hydrogen -= card.cost_hydrogen
	carbon -= card.cost_carbon
	nitrogen -= card.cost_nitrogen
	
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
