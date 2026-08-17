class_name SaveData
extends RefCounted

var discovered_card_ids: Array[String] = []
var owned_blessing_ids: Array[int] = []
var owned_aura_ids: Array[int] = []
var discovered_coat_ids: Array[int] = []

var coins: int = 0
var current_floor: int = 0
var current_hp: int = 100
var max_hp: int = 100

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
	discovered_card_ids.clear()
	owned_blessing_ids.clear()
	owned_aura_ids.clear()
	discovered_coat_ids.clear()
	player_deck_data.clear()

	if dict.has("discovered_card_ids") and dict["discovered_card_ids"] is Array:
		for id_entry in dict["discovered_card_ids"]:
			discovered_card_ids.append(str(id_entry))

	if dict.has("owned_blessing_ids") and dict["owned_blessing_ids"] is Array:
		for id_entry in dict["owned_blessing_ids"]:
			owned_blessing_ids.append(int(id_entry))

	if dict.has("owned_aura_ids") and dict["owned_aura_ids"] is Array:
		for id_entry in dict["owned_aura_ids"]:
			owned_aura_ids.append(int(id_entry))

	if dict.has("discovered_coat_ids") and dict["discovered_coat_ids"] is Array:
		for id_entry in dict["discovered_coat_ids"]:
			discovered_coat_ids.append(int(id_entry))

	coins = int(dict.get("coins", 0))
	current_floor = int(dict.get("current_floor", 0))
	current_hp = int(dict.get("current_hp", 100))
	max_hp = int(dict.get("max_hp", 100))

	if dict.has("player_deck_data") and dict["player_deck_data"] is Array:
		for item in dict["player_deck_data"]:
			if item is Dictionary:
				player_deck_data.append(item)
