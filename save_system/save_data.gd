class_name SaveData
extends RefCounted

var discovered_card_ids: Array[String] = []

var coins: int = 0
var current_floor: int = 0
var current_hp: int = 1000
var max_hp: int = 1000
var player_deck_ids: Array[String] = []


func to_dict() -> Dictionary:
	return {
		"discovered_card_ids": discovered_card_ids,
		"coins": coins,
		"current_floor": current_floor,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"player_deck_ids": player_deck_ids
	}


func from_dict(dict: Dictionary) -> void:
	if dict.has("discovered_card_ids"):
		discovered_card_ids.assign(dict["discovered_card_ids"])
	if dict.has("coins"):
		coins = int(dict["coins"])
	if dict.has("current_floor"):
		current_floor = int(dict["current_floor"])
	if dict.has("current_hp"):
		current_hp = int(dict["current_hp"])
	if dict.has("max_hp"):
		max_hp = int(dict["max_hp"])
	if dict.has("player_deck_ids"):
		player_deck_ids.assign(dict["player_deck_ids"])
