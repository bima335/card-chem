class_name WindFall
extends Control

@export var card_ui_scene: PackedScene

@onready var texture_button: TextureRect = $TextureButton
@onready var claim_button: Button = $TextureButton/ClaimButton
@onready var skip_button: Button = $TextureButton/SkipButton
@onready var reward_display_anchor: CenterContainer = %RewardDisplayAnchor

@onready var deck_backdrop: ColorRect = %DeckBackDrop
@onready var deck_view_panel: PanelContainer = %DeckViewPanel
@onready var title_label: Label = %TitleLabel
@onready var card_grid: GridContainer = %CardGrid
@onready var close_button: Button = %CloseButton

signal effect_target_requested(coat_data: CoatData)

enum ItemType { CARD, COAT }

var available_cards: Array[CardData] = []
var available_coats: Array[CoatData] = []

var _generated_reward: Resource = null
var _generated_type: ItemType
var _active_coat: CoatData = null

const CARD_FOLDERS: Array[String] = [
	"res://card/resources/atk/",
	"res://card/resources/buff/",
	"res://card/resources/debuff/",
	"res://card/resources/trigger/"
]

const COAT_FOLDER: String = "res://card/coat/res/"

const RARITY_WEIGHTS: Dictionary = {
	2: 60.0,
	1: 30.0,
	0: 10.0
}

func _ready() -> void:
	_connect_signals()
	_load_resources_from_disk()
	_generate_random_reward()

func _connect_signals() -> void:
	if claim_button and not claim_button.pressed.is_connected(_on_claim_button_pressed):
		claim_button.pressed.connect(_on_claim_button_pressed)
	if skip_button and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)
	if close_button and not close_button.pressed.is_connected(_on_close_deck_pressed):
		close_button.pressed.connect(_on_close_deck_pressed)

func _load_resources_from_disk() -> void:
	for folder_path in CARD_FOLDERS:
		var loaded_resources = _load_all_resources_in_folder(folder_path)
		for res in loaded_resources:
			if res is CardData:
				available_cards.append(res)
				
	var loaded_coats = _load_all_resources_in_folder(COAT_FOLDER)
	for res in loaded_coats:
		if res is CoatData:
			available_coats.append(res)

func _load_all_resources_in_folder(folder_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".tres") or file_name.ends_with(".remap"):
					var clean_file_name = file_name.replace(".remap", "")
					var full_path = folder_path + clean_file_name
					var res = ResourceLoader.load(full_path)
					if res and not resources.has(res):
						resources.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("[WindFall] Gagal membuka folder: " + folder_path)
		
	return resources

func _generate_random_reward() -> void:
	_generated_type = ItemType.CARD if randf() < 0.5 else ItemType.COAT
	var rolled_rarity: int = _roll_rarity()

	if _generated_type == ItemType.CARD:
		_generated_reward = _pick_item_by_rarity(available_cards, rolled_rarity)
	else:
		_generated_reward = _pick_item_by_rarity(available_coats, rolled_rarity)

	_render_reward_ui()

func _roll_rarity() -> int:
	var total_weight: float = 0.0
	for weight in RARITY_WEIGHTS.values():
		total_weight += weight

	var roll: float = randf_range(0.0, total_weight)
	var accumulated: float = 0.0

	for rarity_key in RARITY_WEIGHTS:
		accumulated += RARITY_WEIGHTS[rarity_key]
		if roll <= accumulated:
			return rarity_key

	return 2

func _pick_item_by_rarity(pool: Array, target_rarity: int) -> Resource:
	if pool.is_empty():
		return null

	var filtered_pool: Array = pool.filter(
		func(item): return ("rarity" in item) and item.rarity == target_rarity
	)

	if filtered_pool.is_empty():
		filtered_pool = pool

	return filtered_pool.pick_random()

func _render_reward_ui() -> void:
	if not reward_display_anchor:
		return

	for child in reward_display_anchor.get_children():
		child.queue_free()

	if _generated_reward == null:
		return

	if _generated_type == ItemType.CARD and card_ui_scene:
		var card_ui = card_ui_scene.instantiate() as CardUI
		reward_display_anchor.add_child(card_ui)
		card_ui.setup(_generated_reward)
		card_ui.is_preview = true
	else:
		var coat_data = _generated_reward as CoatData
		if coat_data:
			var btn = Button.new()
			btn.text = coat_data.coat_name + "\n" + coat_data.description
			btn.custom_minimum_size = Vector2(200, 280)
			reward_display_anchor.add_child(btn)

func _on_claim_button_pressed() -> void:
	if _generated_reward == null:
		_return_to_map()
		return

	if _generated_type == ItemType.CARD:
		var card_data = _generated_reward as CardData
		var new_card = card_data.duplicate(true)
		GameManager.player_deck.append(new_card)
		
		if SaveManager and SaveManager.has_method("discover_card"):
			SaveManager.discover_card(card_data)
			
		_return_to_map()
	else:
		_active_coat = _generated_reward as CoatData
		effect_target_requested.emit(_active_coat)
		_open_deck_for_coat_selection()

func _open_deck_for_coat_selection() -> void:
	texture_button.hide()
	reward_display_anchor.hide()
	
	title_label.text = "PILIH KARTU UNTUK DITEMPEL COAT:\n" + _active_coat.coat_name
	
	for child in card_grid.get_children():
		child.queue_free()
		
	if card_ui_scene == null:
		push_error("[WindFall] ERROR: card_ui_scene belum di-assign!")
		_return_to_map()
		return

	for card_data in GameManager.player_deck:
		var card_ui = card_ui_scene.instantiate() as CardUI
		card_grid.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
		
		if card_ui.has_signal("pressed"):
			card_ui.pressed.connect(_on_deck_card_selected.bind(card_data))
		elif card_ui.has_signal("gui_input"):
			card_ui.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_deck_card_selected(card_data)
			)

	deck_backdrop.show()
	deck_view_panel.show()

func _on_deck_card_selected(target_card: CardData) -> void:
	if _active_coat == null:
		return
		
	apply_coat_to_card(target_card, _active_coat)

func apply_coat_to_card(target_card: CardData, active_coat: CoatData) -> void:
	target_card.coat_data = active_coat
	
	if "coat_type" in active_coat and "CLONE" in CoatData.EffectCoatType:
		if active_coat.coat_type == CoatData.EffectCoatType.CLONE:
			var cloned_card = target_card.duplicate(true)
			GameManager.player_deck.append(cloned_card)

	if SaveManager:
		if SaveManager.has_method("discover_coat"):
			SaveManager.discover_coat(active_coat)
		if SaveManager.has_method("save_game"):
			SaveManager.save_game()
			
	_return_to_map()

func _on_close_deck_pressed() -> void:
	_return_to_map()

func _on_skip_button_pressed() -> void:
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
