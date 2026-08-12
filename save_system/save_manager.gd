extends Node

signal card_discovered(card_id: String)
signal save_completed
signal load_completed

const SAVE_PATH: String = "user://save_data.json"

# Seluruh database kartu yang ada di dalam game (Resource CardData)
@export var all_game_cards: Array[CardData] = []

var current_save: SaveData = SaveData.new()
var card_database: Dictionary = {}


func _ready() -> void:
	_build_card_database()
	load_game()


func _build_card_database() -> void:
	card_database.clear()
	for card in all_game_cards:
		if card and not card.id.is_empty():
			card_database[card.id] = card
		else:
			push_warning("SaveManager: Kartu tanpa ID valid ditemukan!")


func discover_card(card: CardData) -> void:
	if not card or card.id.is_empty():
		return

	if not current_save.discovered_card_ids.has(card.id):
		current_save.discovered_card_ids.append(card.id)
		card_discovered.emit(card.id)
		save_game()


func discover_cards(cards: Array[CardData]) -> void:
	var new_discovery: bool = false
	for card in cards:
		if card and not card.id.is_empty():
			if not current_save.discovered_card_ids.has(card.id):
				current_save.discovered_card_ids.append(card.id)
				card_discovered.emit(card.id)
				new_discovery = true
	
	if new_discovery:
		save_game()


func is_card_discovered(card_id: String) -> bool:
	return current_save.discovered_card_ids.has(card_id)


func get_discovered_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in current_save.discovered_card_ids:
		if card_database.has(card_id):
			result.append(card_database[card_id])
	return result


func save_game() -> void:
	current_save.coins = GameManager.shop_coins
	current_save.current_floor = GameManager.current_floor
	current_save.current_hp = GameManager.player_current_hp
	current_save.max_hp = GameManager.player_max_hp
	
	current_save.player_deck_ids.clear()
	for card in GameManager.player_deck:
		if card and not card.id.is_empty():
			current_save.player_deck_ids.append(card.id)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(current_save.to_dict(), "\t")
		file.store_string(json_string)
		file.close()
		save_completed.emit()
	else:
		push_error("SaveManager: Gagal membuka file simpan untuk ditulis! Error: " + str(FileAccess.get_open_error()))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: Gagal membaca file simpan! Error: " + str(FileAccess.get_open_error()))
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result == OK:
		var data_dict = json.data
		if data_dict is Dictionary:
			current_save.from_dict(data_dict)
			_apply_loaded_data_to_managers()
			load_completed.emit()
	else:
		push_error("SaveManager: Parsing JSON gagal di baris " + str(json.get_error_line()) + ": " + json.get_error_message())


func _apply_loaded_data_to_managers() -> void:
	GameManager.shop_coins = current_save.coins
	GameManager.current_floor = current_save.current_floor
	GameManager.player_current_hp = current_save.current_hp
	GameManager.player_max_hp = current_save.max_hp
	
	GameManager.player_deck.clear()
	for card_id in current_save.player_deck_ids:
		if card_database.has(card_id):
			GameManager.player_deck.append(card_database[card_id].duplicate(true))
