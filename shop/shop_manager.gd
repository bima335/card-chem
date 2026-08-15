class_name ShopManager
extends Control

enum SellCategory { CARDS, BLESSINGS }
enum BuyCategory { CARD, COAT, BLESSING }

const DEFAULT_CARD_SELL_PRICE: int = 8
const DEFAULT_BLESSING_SELL_PRICE: int = 15
const HEAL_PRICE: int = 20
const HEAL_AMOUNT: int = 15

const CARD_DIRECTORIES: Array[String] = [
	"res://card/resources/atk",
	"res://card/resources/buff",
	"res://card/resources/debuff",
	"res://card/resources/trigger"
]
const BLESSING_DIRECTORY: String = "res://blessing/res"
const COAT_DIRECTORY: String = "res://card/coat/res"

@export var card_ui_scene: PackedScene

var available_cards: Array[CardData] = []
var available_coats: Array[CoatData] = []
var available_blessings: Array[BlessingData] = []

@onready var btn_buy: TextureButton = $Interactables/BtnBuy
@onready var btn_heal: TextureButton = $Interactables/BtnHeal
@onready var btn_sell: TextureButton = $Interactables/BtnSell
@onready var btn_leave: Button = $BtnLeave

@onready var coin_label: Label = $UI_Overlay/CoinContainer/CoinLabel
@onready var buy_panel: PanelContainer = $UI_Overlay/BuyPanel
@onready var sell_panel: PanelContainer = $UI_Overlay/SellPanel

@onready var btn_close_buy: Button = $UI_Overlay/BuyPanel/ScrollContainer/MainVBox/HeaderHBox/BtnCloseBuy
@onready var card_grid: HBoxContainer = $UI_Overlay/BuyPanel/ScrollContainer/MainVBox/CardsSection/CardGrid
@onready var coat_grid: HBoxContainer = $UI_Overlay/BuyPanel/ScrollContainer/MainVBox/CoatsSection/CoatGrid
@onready var blessing_grid: HBoxContainer = $UI_Overlay/BuyPanel/ScrollContainer/MainVBox/BlessingSection/BlessingGrid
@onready var deck_selector_overlay: PanelContainer = $UI_Overlay/BuyPanel/DeckSelectorOverlay
@onready var deck_card_grid: GridContainer = $UI_Overlay/BuyPanel/DeckSelectorOverlay/OverlayVBox/ScrollContainer/DeckCardGrid
@onready var btn_cancel_deck_select: Button = $UI_Overlay/BuyPanel/DeckSelectorOverlay/OverlayVBox/BtnCancelDeckSelect

@onready var btn_close_sell: Button = $UI_Overlay/SellPanel/MarginContainer/MainVBox/HeaderHBox/BtnCloseSell
@onready var btn_tab_cards: Button = $UI_Overlay/SellPanel/MarginContainer/MainVBox/CategoryTabs/BtnTabCards
@onready var btn_tab_blessings: Button = $UI_Overlay/SellPanel/MarginContainer/MainVBox/CategoryTabs/BtnTabBlessings
@onready var sell_card_grid: GridContainer = $UI_Overlay/SellPanel/MarginContainer/MainVBox/ScrollContainer/ContentVBox/SellCardGrid
@onready var sell_blessing_grid: HBoxContainer = $UI_Overlay/SellPanel/MarginContainer/MainVBox/ScrollContainer/ContentVBox/SellBlessingGrid
@onready var empty_notice_label: Label = $UI_Overlay/SellPanel/MarginContainer/MainVBox/EmptyNoticeLabel
@onready var sell_confirm_dialog: ConfirmationDialog = $UI_Overlay/SellConfirmDialog
@onready var buy_confirm_dialog: ConfirmationDialog = $UI_Overlay/BuyConfirmDialog
@onready var heal_confirm_dialog: ConfirmationDialog = $UI_Overlay/HealConfirmDialog

var is_shop_generated: bool = false

var pending_buy_item: Resource = null
var pending_buy_price: int = 0
var pending_buy_btn: Button = null
var pending_buy_category: BuyCategory

var pending_coat: CoatData = null
var pending_coat_slot_button: Button = null
var pending_coat_price: int = 0

var current_sell_category: SellCategory = SellCategory.CARDS
var pending_sell_item: Resource = null
var pending_sell_price: int = 0


func _ready() -> void:
	_load_all_shop_resources()
	SoundManager.play_bgm("shop")
	_update_coin_display()
	_connect_signals()


func _load_all_shop_resources() -> void:
	available_cards.clear()
	for dir_path in CARD_DIRECTORIES:
		var cards_in_dir: Array[Resource] = _load_resources_from_directory(dir_path)
		for res in cards_in_dir:
			if res is CardData:
				available_cards.append(res)

	available_blessings.clear()
	var blessings_in_dir: Array[Resource] = _load_resources_from_directory(BLEING_DIRECTORY_RESOLVED())
	for res in blessings_in_dir:
		if res is BlessingData:
			available_blessings.append(res)

	available_coats.clear()
	var coats_in_dir: Array[Resource] = _load_resources_from_directory(COAT_DIRECTORY)
	for res in coats_in_dir:
		if res is CoatData:
			available_coats.append(res)


func BLEING_DIRECTORY_RESOLVED() -> String:
	return BLESSING_DIRECTORY


func _load_resources_from_directory(path: String) -> Array[Resource]:
	var loaded_resources: Array[Resource] = []
	var dir: DirAccess = DirAccess.open(path)

	if not dir:
		push_error("Gagal membuka direktori: %s" % path)
		return loaded_resources

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			var clean_file_name: String = file_name.trim_suffix(".remap").trim_suffix(".import")
			
			if clean_file_name.ends_with(".tres") or clean_file_name.ends_with(".res"):
				var full_path: String = path.path_join(clean_file_name)
				var resource: Resource = load(full_path)
				if resource and not loaded_resources.has(resource):
					loaded_resources.append(resource)

		file_name = dir.get_next()

	dir.list_dir_end()
	return loaded_resources


func _connect_signals() -> void:
	btn_buy.pressed.connect(_on_btn_buy_pressed)
	btn_heal.pressed.connect(_on_btn_heal_pressed)
	btn_sell.pressed.connect(_on_btn_sell_pressed)
	btn_leave.pressed.connect(_on_btn_leave_pressed)

	if btn_close_buy:
		btn_close_buy.pressed.connect(func(): buy_panel.hide())
	if btn_cancel_deck_select:
		btn_cancel_deck_select.pressed.connect(func(): deck_selector_overlay.hide())

	if btn_close_sell:
		btn_close_sell.pressed.connect(func(): sell_panel.hide())
	if btn_tab_cards:
		btn_tab_cards.pressed.connect(_switch_sell_tab.bind(SellCategory.CARDS))
	if btn_tab_blessings:
		btn_tab_blessings.pressed.connect(_switch_sell_tab.bind(SellCategory.BLESSINGS))

	if sell_confirm_dialog:
		sell_confirm_dialog.confirmed.connect(_on_sell_confirmed)
		sell_confirm_dialog.canceled.connect(_on_sell_cancelled)

	if buy_confirm_dialog:
		buy_confirm_dialog.confirmed.connect(_on_buy_confirmed)
		buy_confirm_dialog.canceled.connect(_on_buy_cancelled)
	if heal_confirm_dialog:
		heal_confirm_dialog.confirmed.connect(_on_heal_confirmed)


func _update_coin_display() -> void:
	coin_label.text = "Koin: " + str(GameManager.shop_coins)
	var tween: Tween = create_tween()
	coin_label.scale = Vector2(1.3, 1.3)
	tween.tween_property(coin_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)


# ==============================================================================
# TOOLTIP GENERATION
# ==============================================================================

func _get_rarity_name(rarity_idx: int) -> String:
	match rarity_idx:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		_: return "Normal"


func _build_card_tooltip(card: CardData) -> String:
	var text: String = "%s\n" % card.card_name
	text += "Rarity: %s\n" % _get_rarity_name(int(card.rarity))
	
	var cost_list: Array[String] = []
	if card.cost_carbon > 0: cost_list.append("C: %d" % card.cost_carbon)
	if card.cost_hydrogen > 0: cost_list.append("H: %d" % card.cost_hydrogen)
	if card.cost_oxygen > 0: cost_list.append("O: %d" % card.cost_oxygen)
	if card.cost_nitrogen > 0: cost_list.append("N: %d" % card.cost_nitrogen)
	
	var cost_str: String = "Gratis" if cost_list.is_empty() else ", ".join(cost_list)
	text += "Token Cost: %s\n" % cost_str
	text += card.description
	return text


func _build_coat_tooltip(coat: CoatData) -> String:
	var type_name: String = CoatData.EffectCoatType.keys()[coat.coat_type]
	var text: String = "%s\n" % coat.coat_name
	text += "Type: %s\n" % type_name
	text += "Rarity: %s\n\n" % _get_rarity_name(int(coat.rarity))
	text += coat.description
	return text


func _build_blessing_tooltip(blessing: BlessingData) -> String:
	var text: String = "%s\n" % blessing.name
	text += "Rarity: %s\n\n" % _get_rarity_name(int(blessing.rarity))
	text += blessing.description
	return text


# ==============================================================================
# SELL LOGIC
# ==============================================================================

func _on_btn_sell_pressed() -> void:
	buy_panel.hide()
	sell_panel.show()
	_switch_sell_tab(SellCategory.CARDS)


func _switch_sell_tab(category: SellCategory) -> void:
	current_sell_category = category
	btn_tab_cards.disabled = (category == SellCategory.CARDS)
	btn_tab_blessings.disabled = (category == SellCategory.BLESSINGS)
	_refresh_sell_view()


func _refresh_sell_view() -> void:
	_clear_sell_grids()
	empty_notice_label.hide()

	match current_sell_category:
		SellCategory.CARDS:
			sell_card_grid.show()
			sell_blessing_grid.hide()
			_populate_sell_cards()
		SellCategory.BLESSINGS:
			sell_card_grid.hide()
			sell_blessing_grid.show()
			_populate_sell_blessings()


func _clear_sell_grids() -> void:
	for child in sell_card_grid.get_children():
		child.queue_free()
	for child in sell_blessing_grid.get_children():
		child.queue_free()


func _populate_sell_cards() -> void:
	var deck_cards: Array[CardData] = GameManager.player_deck
	if deck_cards.is_empty():
		empty_notice_label.text = "Deck kamu kosong!"
		empty_notice_label.show()
		return

	for card_data in deck_cards:
		var slot: VBoxContainer = VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER

		var card_ui: CardUI = card_ui_scene.instantiate() as CardUI
		slot.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
		card_ui.tooltip_text = _build_card_tooltip(card_data)

		var price: int = card_data.sell_value if card_data.sell_value > 0 else DEFAULT_CARD_SELL_PRICE
		var btn: Button = Button.new()
		btn.text = "Jual (+" + str(price) + " G)"
		btn.pressed.connect(_request_sell_confirmation.bind(card_data, price))

		slot.add_child(btn)
		sell_card_grid.add_child(slot)


func _populate_sell_blessings() -> void:
	var active_blessings: Array[BlessingData] = BlessingManager.active_blessings
	if active_blessings.is_empty():
		empty_notice_label.text = "Tidak ada Blessing Pin yang terpasang!"
		empty_notice_label.show()
		return

	for blessing in active_blessings:
		var box: VBoxContainer = VBoxContainer.new()
		box.custom_minimum_size = Vector2(160, 200)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.tooltip_text = _build_blessing_tooltip(blessing)

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(72, 72)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = blessing.icon
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var name_lbl: Label = Label.new()
		name_lbl.text = blessing.name if blessing.name != "" else "Blessing Pin"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var price: int = blessing.sell_price if blessing.sell_price > 0 else DEFAULT_BLENG_PRICE_FALLBACK(blessing)
		var btn: Button = Button.new()
		btn.text = "Jual (+" + str(price) + " G)"
		btn.pressed.connect(_request_sell_confirmation.bind(blessing, price))

		box.add_child(icon_rect)
		box.add_child(name_lbl)
		box.add_child(btn)
		sell_blessing_grid.add_child(box)


func DEFAULT_BLENG_PRICE_FALLBACK(blessing: BlessingData) -> int:
	if blessing.buy_price > 0:
		return int(blessing.buy_price * 0.5)
	return DEFAULT_BLESSING_SELL_PRICE


func _request_sell_confirmation(item: Resource, price: int) -> void:
	pending_sell_item = item
	pending_sell_price = price

	var item_name: String = ""
	if item is CardData:
		item_name = item.card_name
	elif item is BlessingData:
		item_name = item.name

	sell_confirm_dialog.dialog_text = "Apakah kamu yakin ingin menjual '%s' seharga %d Koin?" % [item_name, price]
	sell_confirm_dialog.popup_centered()


func _on_sell_confirmed() -> void:
	if pending_sell_item == null:
		return

	if pending_sell_item is CardData:
		var target_card: CardData = pending_sell_item as CardData
		GameManager.player_deck.erase(target_card)
		GameManager.add_shop_coins(pending_sell_price)
		SoundManager.play_sfx("buy_success")
	elif pending_sell_item is BlessingData:
		var target_blessing: BlessingData = pending_sell_item as BlessingData
		var success: bool = BlessingManager.unequip_blessing(target_blessing)
		if success:
			GameManager.add_shop_coins(pending_sell_price)
			SoundManager.play_sfx("buy_success")
		else:
			SoundManager.play_sfx("error")

	_reset_sell_state()
	_update_coin_display()
	_refresh_sell_view()


func _on_sell_cancelled() -> void:
	_reset_sell_state()


func _reset_sell_state() -> void:
	pending_sell_item = null
	pending_sell_price = 0


# ==============================================================================
# BUY LOGIC & CONFIRMATION
# ==============================================================================

func _on_btn_buy_pressed() -> void:
	sell_panel.hide()
	if not is_shop_generated:
		_generate_shop_stock()
		is_shop_generated = true
	buy_panel.show()


func _generate_shop_stock() -> void:
	_clear_all_buy_grids()
	_generate_cards_stock()
	_generate_coats_stock()
	_generate_blessings_stock()


func _clear_all_buy_grids() -> void:
	for c in card_grid.get_children(): c.queue_free()
	for c in coat_grid.get_children(): c.queue_free()
	for c in blessing_grid.get_children(): c.queue_free()


func _roll_rarity(common_chance: float, uncommon_chance: float, rare_chance: float) -> int:
	var total_weight: float = common_chance + uncommon_chance + rare_chance
	if total_weight <= 0.0:
		return 0

	var roll: float = randf() * total_weight
	if roll < common_chance:
		return 0 
	elif roll < (common_chance + uncommon_chance):
		return 1 
	else:
		return 2 


func _pick_item_by_rarity(pool: Array, c_chance: float, u_chance: float, r_chance: float) -> Variant:
	var rolled_rarity_idx: int = _roll_rarity(c_chance, u_chance, r_chance)
	var matching_items = pool.filter(func(item): return int(item.rarity) == rolled_rarity_idx)
	if not matching_items.is_empty():
		return matching_items.pick_random()
	return pool.pick_random()


func _generate_cards_stock() -> void:
	if available_cards.is_empty():
		return

	var current_section: SectionData = GameManager.current_section
	var chosen_cards: Array[CardData] = []
	
	var buff_utility_pool: Array[CardData] = available_cards.filter(
		func(c): return c.card_type == CardData.CardType.BUFF or c.card_type == CardData.CardType.DEBUFF
	)
	var atk_trigger_pool: Array[CardData] = available_cards.filter(
		func(c): return c.card_type == CardData.CardType.ATK or c.card_type == CardData.CardType.TRIGGER
	)
	
	if not buff_utility_pool.is_empty():
		chosen_cards.append(_pick_item_by_rarity(buff_utility_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance))
		
	for i in range(2):
		var valid_atk_pool = atk_trigger_pool.filter(func(c): return not chosen_cards.has(c))
		if not valid_atk_pool.is_empty():
			chosen_cards.append(_pick_item_by_rarity(valid_atk_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance))
			
	while chosen_cards.size() < 5:
		var remaining_pool = available_cards.filter(func(c): return not chosen_cards.has(c))
		if remaining_pool.is_empty():
			break
		chosen_cards.append(_pick_item_by_rarity(remaining_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance))

	for card in chosen_cards:
		_build_card_slot_ui(card)


func _build_card_slot_ui(card_data: CardData) -> void:
	var slot_container: VBoxContainer = VBoxContainer.new()
	slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var card_ui: CardUI = card_ui_scene.instantiate() as CardUI
	slot_container.add_child(card_ui)
	card_ui.setup(card_data)
	card_ui.is_preview = true
	
	card_ui.tooltip_text = _build_card_tooltip(card_data)
	
	var buy_btn: Button = Button.new()
	var price: int = card_data.buy_value if card_data.buy_value > 0 else 15
	buy_btn.text = "Beli (" + str(price) + " Koin)"
	buy_btn.pressed.connect(_request_buy_confirmation.bind(card_data, price, buy_btn, BuyCategory.CARD))
	
	slot_container.add_child(buy_btn)
	card_grid.add_child(slot_container)


func _generate_coats_stock() -> void:
	if available_coats.is_empty():
		var dummy_lbl = Label.new()
		dummy_lbl.text = "Tidak Ada Coat Tersedia"
		coat_grid.add_child(dummy_lbl)
		return

	var current_section: SectionData = GameManager.current_section
	var chosen_coats: Array[CoatData] = []
	var pool: Array[CoatData] = available_coats.duplicate()
	
	var count: int = mini(2, pool.size())
	for i in range(count):
		var valid_pool = pool.filter(func(c): return not chosen_coats.has(c))
		if valid_pool.is_empty():
			break
		var picked = _pick_item_by_rarity(valid_pool, current_section.coat_common_chance, current_section.coat_uncommon_chance, current_section.coat_rare_chance)
		chosen_coats.append(picked)
		_build_coat_slot_ui(picked)


func _build_coat_slot_ui(coat_data: CoatData) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(160, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.tooltip_text = _build_coat_tooltip(coat_data)
	
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(72, 72)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = coat_data.icon
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var name_lbl: Label = Label.new()
	name_lbl.text = coat_data.coat_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var buy_btn: Button = Button.new()
	var price: int = coat_data.buy_price if coat_data.buy_price > 0 else 15
	buy_btn.text = "Beli (" + str(price) + " Koin)"
	buy_btn.pressed.connect(_request_buy_confirmation.bind(coat_data, price, buy_btn, BuyCategory.COAT))
	
	box.add_child(icon_rect)
	box.add_child(name_lbl)
	box.add_child(buy_btn)
	coat_grid.add_child(box)


func _generate_blessings_stock() -> void:
	if available_blessings.is_empty():
		var dummy_lbl = Label.new()
		dummy_lbl.text = "Tidak Ada Blessing Pin Tersedia"
		blessing_grid.add_child(dummy_lbl)
		return

	var valid_blessings = available_blessings.filter(
		func(b): return not _player_has_blessing(b)
	)

	if valid_blessings.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Semua Blessing Pin Telah Dimiliki!"
		blessing_grid.add_child(empty_lbl)
		return

	var current_section: SectionData = GameManager.current_section
	var chosen_blessing = _pick_item_by_rarity(valid_blessings, current_section.blessing_common_chance, current_section.blessing_uncommon_chance, current_section.blessing_rare_chance)
	_build_blessing_slot_ui(chosen_blessing)


func _player_has_blessing(blessing: BlessingData) -> bool:
	return BlessingManager.has_blessing(blessing.id)


func _build_blessing_slot_ui(blessing: BlessingData) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(160, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.tooltip_text = _build_blessing_tooltip(blessing)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(72, 72)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = blessing.icon
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var name_lbl: Label = Label.new()
	name_lbl.text = blessing.name if blessing.name != "" else "Blessing Pin"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var buy_btn: Button = Button.new()
	var price: int = blessing.buy_price if blessing.buy_price > 0 else 25
	buy_btn.text = "Beli (" + str(price) + " Koin)"
	buy_btn.pressed.connect(_request_buy_confirmation.bind(blessing, price, buy_btn, BuyCategory.BLESSING))

	box.add_child(icon_rect)
	box.add_child(name_lbl)
	box.add_child(buy_btn)
	blessing_grid.add_child(box)


# ==============================================================================
# BUY CONFIRMATION SYSTEM
# ==============================================================================

func _request_buy_confirmation(item: Resource, price: int, btn: Button, category: BuyCategory) -> void:
	if GameManager.shop_coins < price:
		SoundManager.play_sfx("error")
		_show_insufficient_coins_feedback(btn)
		return

	if category == BuyCategory.COAT and GameManager.player_deck.is_empty():
		SoundManager.play_sfx("error")
		return

	pending_buy_item = item
	pending_buy_price = price
	pending_buy_btn = btn
	pending_buy_category = category

	var item_name: String = ""
	if item is CardData:
		item_name = item.card_name
	elif item is CoatData:
		item_name = item.coat_name
	elif item is BlessingData:
		item_name = item.name

	buy_confirm_dialog.dialog_text = "Beli '%s' seharga %d Koin?" % [item_name, price]
	buy_confirm_dialog.popup_centered()


func _on_buy_confirmed() -> void:
	if pending_buy_item == null:
		return

	match pending_buy_category:
		BuyCategory.CARD:
			var card_data: CardData = pending_buy_item as CardData
			GameManager.shop_coins -= pending_buy_price
			var new_card: CardData = card_data.duplicate(true)
			GameManager.player_deck.append(new_card)
			SaveManager.discover_card(card_data)
			EventBus.card_obtained.emit(card_data)
			_update_coin_display()
			SoundManager.play_sfx("buy_success")
			pending_buy_btn.disabled = true
			pending_buy_btn.text = "DIBELI"
			_reset_buy_state()

		BuyCategory.COAT:
			pending_coat = pending_buy_item as CoatData
			pending_coat_slot_button = pending_buy_btn
			pending_coat_price = pending_buy_price
			_reset_buy_state()
			_open_deck_selector_for_coat()

		BuyCategory.BLESSING:
			var blessing: BlessingData = pending_buy_item as BlessingData
			var success: bool = BlessingManager.equip_blessing(blessing)
			if success:
				GameManager.shop_coins -= pending_buy_price
				_update_coin_display()
				SaveManager.unlock_blessing(blessing)
				SoundManager.play_sfx("buy_success")
				pending_buy_btn.disabled = true
				pending_buy_btn.text = "DIBELI"
			else:
				SoundManager.play_sfx("error")
				_show_blessing_failed_feedback(pending_buy_btn)
			_reset_buy_state()


func _on_buy_cancelled() -> void:
	_reset_buy_state()


func _reset_buy_state() -> void:
	pending_buy_item = null
	pending_buy_price = 0
	pending_buy_btn = null


# ==============================================================================
# COAT DECK SELECTOR
# ==============================================================================

func _open_deck_selector_for_coat() -> void:
	for child in deck_card_grid.get_children():
		child.queue_free()

	var available_deck_cards: Array[CardData] = GameManager.player_deck.filter(
		func(card: CardData): return card.coat_data == null
	)

	if available_deck_cards.is_empty():
		SoundManager.play_sfx("error")
		return

	for card_data in available_deck_cards:
		var card_ui: CardUI = card_ui_scene.instantiate() as CardUI
		deck_card_grid.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
		card_ui.tooltip_text = _build_card_tooltip(card_data)
		card_ui.pressed.connect(_on_card_selected_for_coat.bind(card_data))

	deck_selector_overlay.show()


func _on_card_selected_for_coat(target_card: CardData) -> void:
	if pending_coat == null:
		return

	if pending_coat.coat_type == CoatData.EffectCoatType.UNSTABLE and target_card.card_type != CardData.CardType.ATK:
		SoundManager.play_sfx("error")
		return

	GameManager.shop_coins -= pending_coat_price
	target_card.coat_data = pending_coat

	if pending_coat.coat_type == CoatData.EffectCoatType.CLONE:
		GameManager.player_deck.append(target_card.duplicate(true))

	SaveManager.discover_coat(pending_coat)
	SaveManager.save_game()

	_update_coin_display()
	SoundManager.play_sfx("buy_success")

	if pending_coat_slot_button:
		pending_coat_slot_button.disabled = true
		pending_coat_slot_button.text = "DIBELI"

	deck_selector_overlay.hide()
	pending_coat = null
	pending_coat_slot_button = null
	pending_coat_price = 0


func _show_insufficient_coins_feedback(target_control: Control) -> void:
	var orig_color: Color = coin_label.modulate
	var tween: Tween = create_tween().set_parallel(true)
	
	coin_label.modulate = Color.RED
	tween.tween_property(coin_label, "modulate", orig_color, 0.4)
	
	var orig_pos: Vector2 = target_control.position
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(target_control, "position", orig_pos + Vector2(-6, 0), 0.05)
	shake_tween.tween_property(target_control, "position", orig_pos + Vector2(6, 0), 0.05)
	shake_tween.tween_property(target_control, "position", orig_pos, 0.05)


func _show_blessing_failed_feedback(target_btn: Button) -> void:
	var orig_text: String = target_btn.text
	target_btn.text = "SLOT FULL!"
	
	var tween: Tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): 
		if is_instance_valid(target_btn) and not target_btn.disabled:
			target_btn.text = orig_text
	)


func _on_btn_heal_pressed() -> void:
	if GameManager.player_current_hp >= GameManager.player_max_hp:
		SoundManager.play_sfx("error")
		return

	if GameManager.shop_coins < HEAL_PRICE:
		SoundManager.play_sfx("error")
		_show_insufficient_coins_feedback(btn_heal)
		return

	heal_confirm_dialog.dialog_text = "Heal %d HP dengan %d coin?" % [HEAL_AMOUNT, HEAL_PRICE]
	heal_confirm_dialog.popup_centered()


func _on_heal_confirmed() -> void:
	if GameManager.shop_coins >= HEAL_PRICE and GameManager.player_current_hp < GameManager.player_max_hp:
		GameManager.shop_coins -= HEAL_PRICE
		GameManager.heal_player(HEAL_AMOUNT)
		_update_coin_display()
		SoundManager.play_sfx("heal_success")
	else:
		SoundManager.play_sfx("error")


func _on_btn_leave_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
