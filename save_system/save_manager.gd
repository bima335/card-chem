extends Node

signal card_discovered(card_id: String)
signal blessing_unlocked(blessing_id: BlessingData.BlessingID)
signal aura_unlocked(aura_id: AuraCardData.AuraID)
signal save_completed
signal load_completed

const SAVE_PATH: String = "user://save_data.json"

const CARD_DIRECTORY_PATHS: Array[String] = [
	"res://card/resources/atk/",
	"res://card/resources/buff/",
	"res://card/resources/debuff/",
	"res://card/resources/trigger/"
]

const BLESSING_DIRECTORY_PATH: String = "res://blessing/res/"
const AURA_DIRECTORY_PATH: String = "res://aura/res/"

var all_game_cards: Array[CardData] = []
var all_game_blessings: Array[BlessingData] = []
var all_game_auras: Array[AuraCardData] = []

var current_save: SaveData = SaveData.new()
var card_database: Dictionary = {}
var blessing_database: Dictionary = {}
var aura_database: Dictionary = {}


func _ready() -> void:
	_load_all_card_resources()
	_build_card_database()
	_load_all_blessing_resources()
	_build_blessing_database()
	_load_all_aura_resources()
	_build_aura_database()
	load_game()


func _load_all_card_resources() -> void:
	all_game_cards.clear()
	for folder_path in CARD_DIRECTORY_PATHS:
		_scan_and_load_card_folder(folder_path)


func _scan_and_load_card_folder(folder_path: String) -> void:
	var dir := DirAccess.open(folder_path)
	if not dir:
		push_warning("SaveManager: Folder kartu tidak ditemukan di: " + folder_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var clean_filename := file_name.trim_suffix(".remap")
				var full_path := folder_path.path_join(clean_filename)
				var card_res := ResourceLoader.load(full_path) as CardData
				if card_res and not all_game_cards.has(card_res):
					all_game_cards.append(card_res)
		file_name = dir.get_next()
		
	dir.list_dir_end()


func _build_card_database() -> void:
	card_database.clear()
	for card in all_game_cards:
		if card and not card.id.is_empty():
			card_database[card.id] = card
		else:
			push_warning("SaveManager: Ada Resource CardData tanpa ID valid!")


func _load_all_blessing_resources() -> void:
	all_game_blessings.clear()
	var dir := DirAccess.open(BLESSING_DIRECTORY_PATH)
	if not dir:
		push_warning("SaveManager: Folder blessing tidak ditemukan di: " + BLESSING_DIRECTORY_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var clean_filename := file_name.trim_suffix(".remap")
				var full_path := BLESSING_DIRECTORY_PATH.path_join(clean_filename)
				var blessing_res := ResourceLoader.load(full_path) as BlessingData
				if blessing_res and not all_game_blessings.has(blessing_res):
					all_game_blessings.append(blessing_res)
		file_name = dir.get_next()

	dir.list_dir_end()


func _build_blessing_database() -> void:
	blessing_database.clear()
	for blessing in all_game_blessings:
		if blessing:
			blessing_database[blessing.id] = blessing


func _load_all_aura_resources() -> void:
	all_game_auras.clear()
	var dir := DirAccess.open(AURA_DIRECTORY_PATH)
	if not dir:
		push_warning("SaveManager: Folder aura tidak ditemukan di: " + AURA_DIRECTORY_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var clean_filename := file_name.trim_suffix(".remap")
				var full_path := AURA_DIRECTORY_PATH.path_join(clean_filename)
				var aura_res := ResourceLoader.load(full_path) as AuraCardData
				if aura_res and not all_game_auras.has(aura_res):
					all_game_auras.append(aura_res)
		file_name = dir.get_next()

	dir.list_dir_end()


func _build_aura_database() -> void:
	aura_database.clear()
	for aura in all_game_auras:
		if aura and aura.aura_id != AuraCardData.AuraID.NONE:
			aura_database[aura.aura_id] = aura


func discover_card(card: CardData) -> void:
	if not card or card.id.is_empty():
		return

	if not current_save.discovered_card_ids.has(card.id):
		current_save.discovered_card_ids.append(card.id)
		card_discovered.emit(card.id)
		save_game()


func discover_cards(cards: Array[CardData]) -> void:
	var state_changed := false
	
	for card in cards:
		if card and not card.id.is_empty():
			if not current_save.discovered_card_ids.has(card.id):
				current_save.discovered_card_ids.append(card.id)
				card_discovered.emit(card.id)
				state_changed = true
				
	if state_changed:
		save_game()


func unlock_blessing(blessing: BlessingData) -> void:
	if not blessing:
		return

	if not current_save.owned_blessing_ids.has(blessing.id):
		current_save.owned_blessing_ids.append(blessing.id)
		blessing_unlocked.emit(blessing.id)
		save_game()


func unlock_aura(aura: AuraCardData) -> void:
	if not aura or aura.aura_id == AuraCardData.AuraID.NONE:
		return

	if not current_save.owned_aura_ids.has(aura.aura_id):
		current_save.owned_aura_ids.append(aura.aura_id)
		aura_unlocked.emit(aura.aura_id)
		save_game()


func is_blessing_unlocked(blessing_id: BlessingData.BlessingID) -> bool:
	return current_save.owned_blessing_ids.has(blessing_id)


func is_aura_unlocked(aura_id: AuraCardData.AuraID) -> bool:
	return current_save.owned_aura_ids.has(aura_id)


func get_unlocked_blessings() -> Array[BlessingData]:
	var result: Array[BlessingData] = []
	for b_id in current_save.owned_blessing_ids:
		if blessing_database.has(b_id):
			result.append(blessing_database[b_id])
	return result


func get_unlocked_auras() -> Array[AuraCardData]:
	var result: Array[AuraCardData] = []
	for a_id in current_save.owned_aura_ids:
		if aura_database.has(a_id):
			result.append(aura_database[a_id])
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
		push_error("SaveManager: Gagal menulis file save!")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: Gagal membaca file save!")
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) == OK:
		var data_dict = json.data
		if data_dict is Dictionary:
			current_save.from_dict(data_dict)
			_apply_loaded_data_to_managers()
			load_completed.emit()


func _apply_loaded_data_to_managers() -> void:
	GameManager.shop_coins = current_save.coins
	GameManager.current_floor = current_save.current_floor
	GameManager.player_current_hp = current_save.current_hp
	GameManager.player_max_hp = current_save.max_hp
	
	GameManager.player_deck.clear()
	for card_id in current_save.player_deck_ids:
		if card_database.has(card_id):
			GameManager.player_deck.append(card_database[card_id].duplicate(true))

	if BlessingManager.has_method("load_player_blessings"):
		BlessingManager.load_player_blessings(get_unlocked_blessings())
		
	if AuraManager and AuraManager.has_method("load_player_auras"):
		AuraManager.load_player_auras(get_unlocked_auras())
