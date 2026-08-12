class_name JournalUI
extends Control

const TOTAL_CARDS_COUNT: int = 30
const CARD_UI_SCENE: PackedScene = preload("res://card/card_ui.tscn")

@export var locked_color: Color = Color(0.15, 0.15, 0.15, 0.6)
@export var unlocked_color: Color = Color.WHITE

@onready var tab_container: TabContainer = %TabContainer
@onready var grid_container: GridContainer = %GridContainer_Cards

@onready var texture_preview: TextureRect = %TextureRect_Preview
@onready var label_title: Label = %Label_CardTitle
@onready var label_description: RichTextLabel = %Label_CardDescription
@onready var label_counter: Label = %Label_CardCounter


func _ready() -> void:
	tab_container.tab_changed.connect(_on_tab_changed)
	_setup_playing_cards_tab()


func _setup_playing_cards_tab() -> void:
	_clear_grid_container()
	
	var discovered_ids: Array[String] = SaveManager.current_save.discovered_card_ids
	var all_cards: Array[CardData] = SaveManager.all_game_cards
	
	for card_data in all_cards:
		if not card_data:
			continue
			
		var card_ui: CardUI = CARD_UI_SCENE.instantiate() as CardUI
		grid_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
		
		var is_discovered: bool = discovered_ids.has(card_data.id)
		
		if is_discovered:
			card_ui.modulate = unlocked_color
			card_ui.gui_input.connect(_on_card_gui_input.bind(card_data))
		else:
			card_ui.modulate = locked_color
	
	_update_card_counter(discovered_ids.size())
	_reset_preview_panel()


func _clear_grid_container() -> void:
	for child in grid_container.get_children():
		child.queue_free()


func _on_card_gui_input(event: InputEvent, card_data: CardData) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_display_card_preview(card_data)


func _display_card_preview(card_data: CardData) -> void:
	if not card_data:
		return
		
	texture_preview.texture = card_data.card_texture
	label_title.text = card_data.card_name
	
	var desc_text: String = _format_card_description(card_data)
	label_description.text = desc_text


func _format_card_description(card_data: CardData) -> String:
	var text: String = ""
	
	var rarity_str: String = CardData.Rarity.keys()[card_data.rarity]
	var type_str: String = CardData.CardType.keys()[card_data.card_type]
	
	text += "[b]Rarity:[/b] " + rarity_str + "\n"
	text += "[b]Type:[/b] " + type_str + "\n"
	text += "[b]Target:[/b] " + CardData.TargetType.keys()[card_data.target_type] + "\n\n"
	
	text += "[b]Cost:[/b] "
	var costs: Array[String] = []
	if card_data.cost_carbon > 0: costs.append("C: " + str(card_data.cost_carbon))
	if card_data.cost_hydrogen > 0: costs.append("H: " + str(card_data.cost_hydrogen))
	if card_data.cost_oxygen > 0: costs.append("O: " + str(card_data.cost_oxygen))
	if card_data.cost_nitrogen > 0: costs.append("N: " + str(card_data.cost_nitrogen))
	
	if costs.is_empty():
		text += "Gratis\n"
	else:
		text += ", ".join(costs) + "\n"
		
	text += "\n[b]Statistik & Efek:[/b]\n"
	if card_data.damage_amount > 0:
		text += "- Damage: " + str(card_data.damage_amount) + "\n"
	if card_data.shield_amount > 0:
		text += "- Shield: " + str(card_data.shield_amount) + "\n"
		
	text += "\n[b]Ekonomi:[/b]\n"
	text += "- Harga Beli: " + str(card_data.buy_value) + " Gold\n"
	text += "- Harga Jual: " + str(card_data.sell_value) + " Gold\n"
	
	return text


func _update_card_counter(discovered_count: int) -> void:
	label_counter.text = "KARTU TERKUMPUL\n" + str(discovered_count) + "/" + str(TOTAL_CARDS_COUNT)


func _reset_preview_panel() -> void:
	texture_preview.texture = null
	label_title.text = "Pilih Kartu"
	label_description.text = "[i]Klik salah satu kartu yang telah ditemukan untuk melihat detailnya.[/i]"


func _on_tab_changed(tab_index: int) -> void:
	var tab_title: String = tab_container.get_tab_title(tab_index)
	if tab_index == 0:
		_setup_playing_cards_tab()
