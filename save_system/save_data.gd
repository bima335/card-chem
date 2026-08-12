class_name SaveData
extends RefCounted

var discovered_card_ids: Array[String] = []
var owned_blessing_ids: Array[int] = []
var owned_aura_ids: Array[int] = []
var discovered_coat_ids: Array[int] = []

var coins: int = 0
var current_floor: int = 0
var current_hp: int = 1000
var max_hp: int = 1000

# Menyimpan pasangan kartu dan coat, contoh: [{"card_id": "atk_slash", "coat_id": 2}]
var player_deck_data: Array[Dictionary] = []


func to_dict() -> Dictionary:
	return {
		"discovered_card_ids": discovered_card_ids,
		"owned_blessing_ids": owned_blessing_ids,
		"owned_aura_ids": owned_aura_ids,
		"discovered_coat_ids": discovered_coat_ids,
		"coins": coins,
		"current_floor": current_floor,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"player_deck_data": player_deck_data
	}


func from_dict(dict: Dictionary) -> void:
	if dict.has("discovered_card_ids"):
		discovered_card_ids.assign(dict["discovered_card_ids"])
	if dict.has("owned_blessing_ids"):
		owned_blessing_ids.assign(dict["owned_blessing_ids"])
	if dict.has("owned_aura_ids"):
		owned_aura_ids.assign(dict["owned_aura_ids"])
	if dict.has("discovered_coat_ids"):
		discovered_coat_ids.assign(dict["discovered_coat_ids"])
	if dict.has("coins"):
		coins = int(dict["coins"])
	if dict.has("current_floor"):
		current_floor = int(dict["current_floor"])
	if dict.has("current_hp"):
		current_hp = int(dict["current_hp"])
	if dict.has("max_hp"):
		max_hp = int(dict["max_hp"])
	if dict.has("player_deck_data"):
		player_deck_data.assign(dict["player_deck_data"])
