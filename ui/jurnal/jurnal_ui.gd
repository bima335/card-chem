class_name JournalUI
extends Control

const TOTAL_CARDS_COUNT: int = 30
const TOTAL_COATS_COUNT: int = 6
const TOTAL_BLESSINGS_COUNT: int = 8
const TOTAL_AURAS_COUNT: int = 9

const CARD_UI_SCENE: PackedScene = preload("res://card/card_ui.tscn")
const COAT_UI_SCENE: PackedScene = preload("res://card/coat/coat_ui.tscn")
const BLESSING_UI_ITEM_SCENE: PackedScene = preload("res://ui/blessing/blessing_ui_item.tscn")
const AURA_CARD_UI_SCENE: PackedScene = preload("res://aura/AuraCardUI.tscn")

@export var locked_color: Color = Color(0.15, 0.15, 0.15, 0.6)
@export var unlocked_color: Color = Color.WHITE

@onready var tab_container: TabContainer = %TabContainer

# Playing Cards References
@onready var grid_container_cards: GridContainer = %GridContainer_Cards
@onready var texture_card_preview: TextureRect = %TextureRect_Preview
@onready var label_card_title: Label = %Label_CardTitle
@onready var label_card_description: RichTextLabel = %Label_CardDescription
@onready var label_card_counter: Label = %Label_CardCounter

# Effect Coat References
@onready var grid_container_coats: GridContainer = %GridContainer_Coats
@onready var texture_coat_preview: TextureRect = %TextureRect_CoatPreview
@onready var label_coat_title: Label = %Label_CoatTitle
@onready var label_coat_description: RichTextLabel = %Label_CoatDescription
@onready var label_coat_counter: Label = %Label_CoatCounter

# Blessing Tokens References
@onready var grid_container_blessings: GridContainer = %GridContainer_Blessings
@onready var texture_blessing_preview: TextureRect = %TextureRect_BlessingPreview
@onready var label_blessing_title: Label = %Label_BlessingTitle
@onready var label_blessing_description: RichTextLabel = %Label_BlessingDescription
@onready var label_blessing_counter: Label = %Label_BlessingCounter

# Aura Bosscard References
@onready var grid_container_auras: GridContainer = %GridContainer_Auras
@onready var texture_aura_preview: TextureRect = %TextureRect_AuraPreview
@onready var label_aura_title: Label = %Label_AuraTitle
@onready var label_aura_description: RichTextLabel = %Label_AuraDescription
@onready var label_aura_counter: Label = %Label_AuraCounter


func _ready() -> void:
	tab_container.tab_changed.connect(_on_tab_changed)
	_setup_playing_cards_tab()


# --- PLAYING CARDS ---

func _setup_playing_cards_tab() -> void:
	_clear_container(grid_container_cards)
	
	var discovered_ids: Array[String] = SaveManager.current_save.discovered_card_ids
	var all_cards: Array[CardData] = SaveManager.all_game_cards
	
	for card_data in all_cards:
		if not card_data:
			continue
			
		var card_ui: CardUI = CARD_UI_SCENE.instantiate() as CardUI
		grid_container_cards.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
		
		var is_discovered: bool = discovered_ids.has(card_data.id)
		
		if is_discovered:
			card_ui.set_visual_color(unlocked_color)
			card_ui.gui_input.connect(_on_card_gui_input.bind(card_data))
		else:
			card_ui.set_visual_color(locked_color)
	
	_update_card_counter(discovered_ids.size())
	_reset_card_preview_panel()


func _on_card_gui_input(event: InputEvent, card_data: CardData) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_display_card_preview(card_data)


func _display_card_preview(card_data: CardData) -> void:
	if not card_data:
		return
		
	texture_card_preview.texture = card_data.card_texture
	label_card_title.text = card_data.card_name
	label_card_description.text = _format_card_description(card_data)


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
	label_card_counter.text = "KARTU TERKUMPUL\n" + str(discovered_count) + "/" + str(TOTAL_CARDS_COUNT)


func _reset_card_preview_panel() -> void:
	texture_card_preview.texture = null
	label_card_title.text = "Pilih Kartu"
	label_card_description.text = "[i]Klik salah satu kartu yang telah ditemukan untuk melihat detailnya.[/i]"


# --- EFFECT COAT ---

func _setup_coats_tab() -> void:
	_clear_container(grid_container_coats)
	
	var discovered_ids: Array[int] = SaveManager.current_save.discovered_coat_ids
	var all_coats: Array[CoatData] = SaveManager.all_game_coats
	
	for coat_data in all_coats:
		if not coat_data or coat_data.coat_type == CoatData.EffectCoatType.NONE:
			continue
			
		var coat_ui: TextureButton = COAT_UI_SCENE.instantiate() as TextureButton
		grid_container_coats.add_child(coat_ui)
		
		# Jika TextureButton memiliki method setup / texture assignment
		if coat_ui.has_method("setup"):
			coat_ui.setup(coat_data)
		else:
			coat_ui.texture_normal = coat_data.icon
			
		var is_discovered: bool = discovered_ids.has(coat_data.coat_type)
		
		if is_discovered:
			coat_ui.modulate = unlocked_color
			coat_ui.pressed.connect(_on_coat_item_clicked.bind(coat_data))
		else:
			coat_ui.modulate = locked_color
			
	_update_coat_counter(discovered_ids.size())
	_reset_coat_preview_panel()


func _on_coat_item_clicked(coat_data: CoatData) -> void:
	_display_coat_preview(coat_data)


func _display_coat_preview(coat_data: CoatData) -> void:
	if not coat_data:
		return
		
	texture_coat_preview.texture = coat_data.icon
	label_coat_title.text = coat_data.coat_name
	label_coat_description.text = _format_coat_description(coat_data)


func _format_coat_description(coat_data: CoatData) -> String:
	var text: String = ""
	text += "[b]Deskripsi:[/b]\n" + coat_data.description + "\n\n"
	
	text += "[b]Properti Efek:[/b]\n"
	if coat_data.damage_multiplier != 1.0:
		text += "- Multiplier Damage: " + str(coat_data.damage_multiplier) + "x\n"
	if coat_data.self_damage_ratio > 0.0:
		text += "- Self Damage: " + str(coat_data.self_damage_ratio * 100.0) + "%\n"
	if coat_data.is_retained:
		text += "- Retain saat Turn End: Ya\n"
	if coat_data.retain_shield_bonus > 0:
		text += "- Shield Bonus Retain: +" + str(coat_data.retain_shield_bonus) + "\n"
	if coat_data.is_insulated:
		text += "- Efek Insulated: Aktif\n"
	if coat_data.cost_reduction_amount > 0:
		text += "- Potongan Cost: -" + str(coat_data.cost_reduction_amount) + "\n"

	text += "\n[b]Ekonomi:[/b]\n"
	text += "- Harga Beli: " + str(coat_data.buy_price) + " Gold\n"
	return text


func _update_coat_counter(discovered_count: int) -> void:
	label_coat_counter.text = "EFFECT COAT TERKUMPUL\n" + str(discovered_count) + "/" + str(TOTAL_COATS_COUNT)


func _reset_coat_preview_panel() -> void:
	texture_coat_preview.texture = null
	label_coat_title.text = "Pilih Coat"
	label_coat_description.text = "[i]Klik salah satu coat yang telah ditemukan untuk melihat detailnya.[/i]"


# --- BLESSING TOKENS ---

func _setup_blessings_tab() -> void:
	_clear_container(grid_container_blessings)
	
	var owned_ids: Array[int] = SaveManager.current_save.owned_blessing_ids
	var all_blessings: Array[BlessingData] = SaveManager.all_game_blessings
	
	for blessing_data in all_blessings:
		if not blessing_data:
			continue
			
		var blessing_item: BlessingUIItem = BLESSING_UI_ITEM_SCENE.instantiate() as BlessingUIItem
		grid_container_blessings.add_child(blessing_item)
		blessing_item.setup(blessing_data)
		
		var is_unlocked: bool = owned_ids.has(blessing_data.id)
		
		if is_unlocked:
			blessing_item.set_visual_color(unlocked_color)
			blessing_item.clicked.connect(_on_blessing_item_clicked)
		else:
			blessing_item.set_visual_color(locked_color)
			
	_update_blessing_counter(owned_ids.size())
	_reset_blessing_preview_panel()


func _on_blessing_item_clicked(blessing_data: BlessingData) -> void:
	_display_blessing_preview(blessing_data)


func _display_blessing_preview(blessing_data: BlessingData) -> void:
	if not blessing_data:
		return
		
	texture_blessing_preview.texture = blessing_data.icon
	label_blessing_title.text = blessing_data.name
	label_blessing_description.text = _format_blessing_description(blessing_data)


func _format_blessing_description(blessing_data: BlessingData) -> String:
	var text: String = ""
	text += "[b]Deskripsi:[/b]\n" + blessing_data.description + "\n\n"
	text += "[b]Ekonomi:[/b]\n"
	text += "- Harga Beli: " + str(blessing_data.buy_price) + " Gold\n"
	text += "- Harga Jual: " + str(blessing_data.sell_price) + " Gold\n"
	return text


func _update_blessing_counter(owned_count: int) -> void:
	label_blessing_counter.text = "BLESSING TERKUMPUL\n" + str(owned_count) + "/" + str(TOTAL_BLESSINGS_COUNT)


func _reset_blessing_preview_panel() -> void:
	texture_blessing_preview.texture = null
	label_blessing_title.text = "Pilih Blessing"
	label_blessing_description.text = "[i]Klik salah satu blessing yang telah didapatkan untuk melihat detailnya.[/i]"


# --- AURA BOSSCARD ---

func _setup_auras_tab() -> void:
	_clear_container(grid_container_auras)
	
	var owned_ids: Array[int] = SaveManager.current_save.owned_aura_ids
	var all_auras: Array[AuraCardData] = SaveManager.all_game_auras
	
	for aura_data in all_auras:
		if not aura_data:
			continue
			
		var aura_ui: AuraCardUI = AURA_CARD_UI_SCENE.instantiate() as AuraCardUI
		grid_container_auras.add_child(aura_ui)
		aura_ui.setup(aura_data)
		
		var is_unlocked: bool = owned_ids.has(aura_data.aura_id)
		
		if is_unlocked:
			aura_ui.set_visual_color(unlocked_color)
			aura_ui.aura_selected.connect(_on_aura_selected)
		else:
			aura_ui.set_visual_color(locked_color)
			
	_update_aura_counter(owned_ids.size())
	_reset_aura_preview_panel()


func _on_aura_selected(aura_data: AuraCardData) -> void:
	_display_aura_preview(aura_data)


func _display_aura_preview(aura_data: AuraCardData) -> void:
	if not aura_data:
		return
		
	texture_aura_preview.texture = aura_data.icon
	label_aura_title.text = aura_data.name
	label_aura_description.text = _format_aura_description(aura_data)


func _format_aura_description(aura_data: AuraCardData) -> String:
	var text: String = ""
	text += "[b]Efek Pasif Aura:[/b]\n"
	text += aura_data.description
	return text


func _update_aura_counter(owned_count: int) -> void:
	label_aura_counter.text = "AURA TERKUMPUL\n" + str(owned_count) + "/" + str(TOTAL_AURAS_COUNT)


func _reset_aura_preview_panel() -> void:
	texture_aura_preview.texture = null
	label_aura_title.text = "Pilih Aura"
	label_aura_description.text = "[i]Klik salah satu aura yang telah didapatkan untuk melihat detailnya.[/i]"


# --- UTILS ---

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_tab_changed(tab_index: int) -> void:
	match tab_index:
		0:
			_setup_playing_cards_tab()
		1:
			_setup_coats_tab()
		2:
			_setup_blessings_tab()
		3:
			_setup_auras_tab()
