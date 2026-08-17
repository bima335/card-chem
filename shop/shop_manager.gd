class_name ShopManager
extends Control

enum SellCategory { CARDS, BLESSINGS }
enum BuyCategory { CARD, COAT, BLESSING }

const DEFAULT_CARD_SELL_PRICE: int = 8
const DEFAULT_BLESSING_SELL_PRICE: int = 15
const HEAL_PRICE: int = 20
const HEAL_AMOUNT: int = 15

const INITIAL_REROLL_PRICE: int = 4
const REROLL_PRICE_INCREMENT: int = 4

const CARD_DIRECTORIES: Array[String] = [
	"res://card/resources/atk",
	"res://card/resources/buff",
	"res://card/resources/debuff",
	"res://card/resources/trigger"
]
const BLESSING_DIRECTORY: String = "res://blessing/res"
const COAT_DIRECTORY: String = "res://card/coat/res"

@export_group("UI Slot Scenes")
@export var card_ui_scene: PackedScene
@export var card_slot_scene: PackedScene
@export var coat_slot_scene: PackedScene
@export var blessing_slot_scene: PackedScene

@export_group("Card UI Dimensions")
@export var card_slot_size: Vector2 = Vector2(230, 330)
@export var card_display_size: Vector2 = Vector2(210, 270)

@export_group("Coat UI Dimensions")
@export var coat_slot_size: Vector2 = Vector2(170, 260)
@export var coat_icon_size: Vector2 = Vector2(150, 210)

@export_group("Blessing UI Dimensions")
@export var blessing_slot_size: Vector2 = Vector2(220, 240)
@export var blessing_icon_size: Vector2 = Vector2(150, 150)

var available_cards: Array[CardData] = []
var available_coats: Array[CoatData] = []
var available_blessings: Array[BlessingData] = []

var current_reroll_price: int = INITIAL_REROLL_PRICE

@onready var btn_buy: TextureButton = $Interactables/BtnBuy
@onready var btn_heal: TextureButton = $Interactables/BtnHeal
@onready var btn_sell: TextureButton = $Interactables/BtnSell
@onready var btn_leave: Button = $BtnLeave

@onready var buy_panel: PanelContainer = $UI_Overlay/BuyPanel
@onready var sell_panel: PanelContainer = $UI_Overlay/SellPanel
@onready var heal_panel: PanelContainer = $UI_Overlay/HealPanel

@onready var btn_reroll: Button = $UI_Overlay/BuyPanel/MarginContainer2/RerollButton
@onready var price_label: Label = $UI_Overlay/BuyPanel/MarginContainer2/RerollButton/PriceLabel
@onready var gold_label: Label = $UI_Overlay/BuyPanel/MarginContainer2/HBoxContainer/GoldLabel
@onready var hp_label: Label = $UI_Overlay/BuyPanel/MarginContainer2/HBoxContainer/HPLabel

@onready var sell_gold_label: Label = $UI_Overlay/SellPanel/MarginContainer2/HBoxContainer/SellGoldLabel
@onready var sell_hp_label: Label = $UI_Overlay/SellPanel/MarginContainer2/HBoxContainer/SellHPLabel
@onready var sell_card_grid: HBoxContainer = $UI_Overlay/SellPanel/MarginContainer/MainVBox/ScrollContainer/SellCardGrid

@onready var heal_gold_label: Label = $UI_Overlay/HealPanel/MarginContainer2/HBoxContainer/SellGoldLabel
@onready var heal_hp_label: Label = $UI_Overlay/HealPanel/MarginContainer2/HBoxContainer/SellHPLabel
@onready var pay_heal_button: Button = $UI_Overlay/HealPanel/MarginContainer2/PayHealButton
@onready var heal_cost_label: Label = $UI_Overlay/HealPanel/MarginContainer2/PayHealButton/Label

@onready var btn_close_buy: Button = $UI_Overlay/BuyPanel/MarginContainer/MainVBox/HeaderHBox/BtnCloseBuy
@onready var card_grid: HBoxContainer = $UI_Overlay/BuyPanel/MarginContainer/MainVBox/BodyHBox/LeftCardsSection/CardsScroll/CardGrid
@onready var coat_grid: HBoxContainer = $UI_Overlay/BuyPanel/MarginContainer/MainVBox/BodyHBox/RightSideVBox/CoatsSection/CoatGrid
@onready var blessing_grid: HBoxContainer = $UI_Overlay/BuyPanel/MarginContainer/MainVBox/BodyHBox/RightSideVBox/BlessingSection/BlessingGrid
@onready var deck_selector_overlay: PanelContainer = $UI_Overlay/BuyPanel/DeckSelectorOverlay
@onready var deck_card_grid: GridContainer = $UI_Overlay/BuyPanel/DeckSelectorOverlay/OverlayVBox/ScrollContainer/DeckCardGrid
@onready var btn_cancel_deck_select: Button = $UI_Overlay/BuyPanel/DeckSelectorOverlay/OverlayVBox/BtnCancelDeckSelect

@onready var btn_close_sell: Button = $UI_Overlay/SellPanel/MarginContainer/MainVBox/HeaderHBox/BtnCloseSell
@onready var empty_notice_label: Label = $UI_Overlay/SellPanel/MarginContainer/MainVBox/EmptyNoticeLabel
@onready var sell_confirm_dialog: ConfirmationDialog = $UI_Overlay/SellConfirmDialog
@onready var buy_confirm_dialog: ConfirmationDialog = $UI_Overlay/BuyConfirmDialog
@onready var heal_confirm_dialog: ConfirmationDialog = $UI_Overlay/HealConfirmDialog

var is_shop_generated: bool = false

var pending_buy_item: Resource = null
var pending_buy_price: int = 0
var pending_buy_slot: Node = null
var pending_buy_category: BuyCategory

var pending_coat: CoatData = null
var pending_coat_slot: Node = null
var pending_coat_price: int = 0

var pending_sell_item: Resource = null
var pending_sell_price: int = 0


func _ready() -> void:
	if GameManager.current_section == null:
		GameManager.update_current_section_for_floor(GameManager.current_floor)
	
	_load_all_shop_resources()
	SoundManager.play_bgm("shop")
	_connect_signals()
	
	_setup_button_juice(btn_buy)
	_setup_button_juice(btn_heal)
	_setup_button_juice(btn_sell)
	
	buy_panel.hide()
	sell_panel.hide()
	heal_panel.hide()
	
	_update_shop_header_ui()

func _setup_button_juice(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(func(): _animate_button_scale(button, Vector2(1.08, 1.08), 0.15))
	button.mouse_exited.connect(func(): _animate_button_scale(button, Vector2.ONE, 0.15))
	button.button_down.connect(func(): _animate_button_scale(button, Vector2(0.92, 0.92), 0.08))
	button.button_up.connect(func(): _animate_button_scale(button, Vector2(1.08, 1.08), 0.08))

func _animate_button_scale(button: TextureButton, target_scale: Vector2, duration: float) -> void:
	if button.has_meta("juice_tween"):
		var existing_tween: Tween = button.get_meta("juice_tween")
		if is_instance_valid(existing_tween) and existing_tween.is_valid():
			existing_tween.kill()

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, duration)
	button.set_meta("juice_tween", tween)


func _load_all_shop_resources() -> void:
	available_cards.clear()
	for dir_path in CARD_DIRECTORIES:
		var cards_in_dir: Array[Resource] = _load_resources_from_directory(dir_path)
		for res in cards_in_dir:
			if res is CardData:
				available_cards.append(res)

	available_blessings.clear()
	var blessings_in_dir: Array[Resource] = _load_resources_from_directory(BLESSING_DIRECTORY)
	for res in blessings_in_dir:
		if res is BlessingData:
			available_blessings.append(res)

	available_coats.clear()
	var coats_in_dir: Array[Resource] = _load_resources_from_directory(COAT_DIRECTORY)
	for res in coats_in_dir:
		if res is CoatData:
			available_coats.append(res)


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

	if pay_heal_button:
		pay_heal_button.pressed.connect(_on_pay_heal_button_pressed)

	if btn_reroll:
		btn_reroll.pressed.connect(_on_btn_reroll_pressed)

	if btn_close_buy:
		btn_close_buy.pressed.connect(func(): buy_panel.hide())
	if btn_cancel_deck_select:
		btn_cancel_deck_select.pressed.connect(func(): deck_selector_overlay.hide())

	if btn_close_sell:
		btn_close_sell.pressed.connect(func(): sell_panel.hide())

	if sell_confirm_dialog:
		sell_confirm_dialog.confirmed.connect(_on_sell_confirmed)
		sell_confirm_dialog.canceled.connect(_on_sell_cancelled)

	if buy_confirm_dialog:
		buy_confirm_dialog.confirmed.connect(_on_buy_confirmed)
		buy_confirm_dialog.canceled.connect(_on_buy_cancelled)

	if heal_confirm_dialog:
		heal_confirm_dialog.confirmed.connect(_on_heal_confirmed)


func _update_shop_header_ui() -> void:
	if gold_label:
		gold_label.text = "%d G" % GameManager.shop_coins
	if hp_label:
		hp_label.text = "%d/%d" % [GameManager.player_current_hp, GameManager.player_max_hp]
		
	if sell_gold_label:
		sell_gold_label.text = "%d G" % GameManager.shop_coins
	if sell_hp_label:
		sell_hp_label.text = "%d/%d" % [GameManager.player_current_hp, GameManager.player_max_hp]
		
	if heal_gold_label:
		heal_gold_label.text = "%d G" % GameManager.shop_coins
	if heal_hp_label:
		heal_hp_label.text = "%d/%d" % [GameManager.player_current_hp, GameManager.player_max_hp]
		
	if heal_cost_label:
		heal_cost_label.text = "%d G" % HEAL_PRICE
		
	if price_label:
		price_label.text = "%d G" % current_reroll_price


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
# SECTION: BUY SYSTEM & REROLL
# ==============================================================================

func _on_btn_buy_pressed() -> void:
	sell_panel.hide()
	heal_panel.hide()
	if not is_shop_generated:
		_generate_shop_stock()
		is_shop_generated = true
	_update_shop_header_ui()
	buy_panel.show()


func _on_btn_reroll_pressed() -> void:
	if GameManager.shop_coins < current_reroll_price:
		SoundManager.play_sfx("error")
		_show_insufficient_coins_feedback(btn_reroll)
		return

	GameManager.shop_coins -= current_reroll_price
	EventBus.gold_changed.emit(GameManager.shop_coins)
	
	current_reroll_price += REROLL_PRICE_INCREMENT
	
	_generate_shop_stock()
	_update_shop_header_ui()
	SoundManager.play_sfx("buy_success")


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
	if current_section == null:
		current_section = _create_fallback_section()
	
	var chosen_cards: Array[CardData] = []
	var buff_pool: Array[CardData] = available_cards.filter(func(c): return c.card_type == CardData.CardType.BUFF or c.card_type == CardData.CardType.DEBUFF)
	var atk_pool: Array[CardData] = available_cards.filter(func(c): return c.card_type == CardData.CardType.ATK or c.card_type == CardData.CardType.TRIGGER)
	
	if not buff_pool.is_empty():
		chosen_cards.append(_pick_item_by_rarity(buff_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance))
		
	for i in range(2):
		var valid_atk = atk_pool.filter(func(c): return not chosen_cards.has(c))
		if not valid_atk.is_empty():
			chosen_cards.append(_pick_item_by_rarity(valid_atk, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance))
			
	while chosen_cards.size() < 3:
		var remaining = available_cards.filter(func(c): return not chosen_cards.has(c))
		if remaining.is_empty():
			break
		chosen_cards.append(_pick_item_by_rarity(remaining, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance))

	for card in chosen_cards:
		var slot: ShopCardSlot = card_slot_scene.instantiate() as ShopCardSlot
		card_grid.add_child(slot)
		slot.set_dimensions(card_slot_size, card_display_size)
		
		var price: int = card.buy_value if card.buy_value > 0 else 15
		slot.setup(card, price, card_ui_scene, _build_card_tooltip(card), ShopCardSlot.SlotMode.BUY)
		slot.action_requested.connect(_on_slot_buy_requested.bind(BuyCategory.CARD))


func _generate_coats_stock() -> void:
	if coat_slot_scene == null:
		push_error("Error: coat_slot_scene belum di-assign pada ShopManager!")
		return

	if available_coats.is_empty():
		var dummy_lbl: Label = Label.new()
		dummy_lbl.text = "Tidak Ada Coat Tersedia"
		coat_grid.add_child(dummy_lbl)
		return

	var current_section: SectionData = GameManager.current_section
	if current_section == null:
		current_section = _create_fallback_section()
	
	var chosen_coats: Array[CoatData] = []
	var pool: Array[CoatData] = available_coats.duplicate()
	var count: int = mini(2, pool.size())
	
	for i in range(count):
		var valid_pool: Array[CoatData] = pool.filter(
			func(c: CoatData) -> bool: return not chosen_coats.has(c)
		)
		if valid_pool.is_empty():
			break
			
		var picked: CoatData = _pick_item_by_rarity(
			valid_pool, 
			current_section.coat_common_chance, 
			current_section.coat_uncommon_chance, 
			current_section.coat_rare_chance
		)
		
		if picked == null:
			continue
			
		chosen_coats.append(picked)
		
		var slot_instance = coat_slot_scene.instantiate()
		var slot: ShopItemSlot = slot_instance as ShopItemSlot
		
		if slot == null:
			push_error("Error: Root node dari coat_slot_scene bukan ShopItemSlot!")
			if is_instance_valid(slot_instance):
				slot_instance.queue_free()
			continue

		coat_grid.add_child(slot)
		slot.set_dimensions(coat_slot_size, coat_icon_size)
		
		var price: int = picked.buy_price if picked.buy_price > 0 else 15
		slot.setup(picked, price, picked.icon, _build_coat_tooltip(picked))
		slot.buy_requested.connect(_on_slot_buy_requested.bind(BuyCategory.COAT))


func _generate_blessings_stock() -> void:
	if blessing_slot_scene == null:
		push_error("Error: blessing_slot_scene belum di-assign pada ShopManager!")
		return

	if available_blessings.is_empty():
		var dummy_label: Label = Label.new()
		dummy_label.text = "Tidak Ada Blessing Pin Tersedia"
		blessing_grid.add_child(dummy_label)
		return

	var current_section: SectionData = GameManager.current_section
	if current_section == null:
		current_section = _create_fallback_section()

	var valid_blessings: Array[BlessingData] = available_blessings.filter(
		func(blessing: BlessingData) -> bool: 
			return not BlessingManager.has_blessing(blessing.id)
	)

	if valid_blessings.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Semua Blessing Pin Telah Dimiliki!"
		blessing_grid.add_child(empty_label)
		return

	var chosen_blessing: BlessingData = _pick_item_by_rarity(
		valid_blessings,
		current_section.blessing_common_chance,
		current_section.blessing_uncommon_chance,
		current_section.blessing_rare_chance
	)

	var slot_instance = blessing_slot_scene.instantiate()
	var slot: ShopItemSlot = slot_instance as ShopItemSlot
	
	if slot == null:
		push_error("Error: Root node dari blessing_slot_scene bukan ShopItemSlot!")
		if is_instance_valid(slot_instance):
			slot_instance.queue_free()
		return

	blessing_grid.add_child(slot)
	slot.set_dimensions(blessing_slot_size, blessing_icon_size)

	var price: int = chosen_blessing.buy_price if chosen_blessing.buy_price > 0 else 25
	slot.setup(chosen_blessing, price, chosen_blessing.icon, _build_blessing_tooltip(chosen_blessing))
	slot.buy_requested.connect(_on_slot_buy_requested.bind(BuyCategory.BLESSING))


func _on_slot_buy_requested(item: Resource, price: int, slot: Node, category: BuyCategory) -> void:
	if GameManager.shop_coins < price:
		SoundManager.play_sfx("error")
		_show_insufficient_coins_feedback(slot)
		return

	if category == BuyCategory.COAT and GameManager.player_deck.is_empty():
		SoundManager.play_sfx("error")
		return

	pending_buy_item = item
	pending_buy_price = price
	pending_buy_slot = slot
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
			SoundManager.play_sfx("buy_success")
			if pending_buy_slot and pending_buy_slot.has_method("mark_as_bought"):
				pending_buy_slot.mark_as_bought()
			_reset_buy_state()

		BuyCategory.COAT:
			pending_coat = pending_buy_item as CoatData
			pending_coat_slot = pending_buy_slot
			pending_coat_price = pending_buy_price
			_reset_buy_state()
			_open_deck_selector_for_coat()

		BuyCategory.BLESSING:
			var blessing: BlessingData = pending_buy_item as BlessingData
			var success: bool = BlessingManager.equip_blessing(blessing)
			if success:
				GameManager.shop_coins -= pending_buy_price
				SaveManager.unlock_blessing(blessing)
				SoundManager.play_sfx("buy_success")
				if pending_buy_slot and pending_buy_slot.has_method("mark_as_bought"):
					pending_buy_slot.mark_as_bought()
			else:
				SoundManager.play_sfx("error")
				if pending_buy_slot and pending_buy_slot.has_method("show_feedback"):
					pending_buy_slot.show_feedback("SLOT FULL!")
			_reset_buy_state()

	_update_shop_header_ui()


func _on_buy_cancelled() -> void:
	_reset_buy_state()


func _reset_buy_state() -> void:
	pending_buy_item = null
	pending_buy_price = 0
	pending_buy_slot = null


func _open_deck_selector_for_coat() -> void:
	for child in deck_card_grid.get_children():
		child.queue_free()

	var available_deck_cards: Array[CardData] = GameManager.player_deck.filter(func(card: CardData): return card.coat_data == null)
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

	SoundManager.play_sfx("buy_success")

	if pending_coat_slot and pending_coat_slot.has_method("mark_as_bought"):
		pending_coat_slot.mark_as_bought()

	deck_selector_overlay.hide()
	pending_coat = null
	pending_coat_slot = null
	pending_coat_price = 0
	
	_update_shop_header_ui()


# ==============================================================================
# SECTION: SELL SYSTEM
# ==============================================================================

func _on_btn_sell_pressed() -> void:
	buy_panel.hide()
	heal_panel.hide()
	sell_panel.show()
	_update_shop_header_ui()
	_populate_sell_cards()


func _populate_sell_cards() -> void:
	for child in sell_card_grid.get_children():
		child.queue_free()

	var deck_cards: Array[CardData] = GameManager.player_deck
	if deck_cards.is_empty():
		empty_notice_label.text = "Deck kamu kosong!"
		empty_notice_label.show()
		return

	empty_notice_label.hide()

	for card_data in deck_cards:
		var slot: ShopCardSlot = card_slot_scene.instantiate() as ShopCardSlot
		sell_card_grid.add_child(slot)
		slot.set_dimensions(card_slot_size, card_display_size)

		var sell_price: int = card_data.sell_value if card_data.sell_value > 0 else DEFAULT_CARD_SELL_PRICE
		slot.setup(card_data, sell_price, card_ui_scene, _build_card_tooltip(card_data), ShopCardSlot.SlotMode.SELL)
		slot.action_requested.connect(_on_slot_sell_requested)


func _on_slot_sell_requested(card_data: CardData, price: int, slot: ShopCardSlot) -> void:
	pending_sell_item = card_data
	pending_sell_price = price
	sell_confirm_dialog.dialog_text = "Jual kartu '%s' seharga %d Koin?" % [card_data.card_name, price]
	sell_confirm_dialog.popup_centered()


func _on_sell_confirmed() -> void:
	if pending_sell_item == null:
		return

	if pending_sell_item is CardData:
		var target_card: CardData = pending_sell_item as CardData
		GameManager.player_deck.erase(target_card)
		GameManager.add_shop_coins(pending_sell_price)
		SoundManager.play_sfx("buy_success")

	_reset_sell_state()
	_populate_sell_cards()
	_update_shop_header_ui()


func _on_sell_cancelled() -> void:
	_reset_sell_state()


func _reset_sell_state() -> void:
	pending_sell_item = null
	pending_sell_price = 0


# ==============================================================================
# SECTION: HEAL & UTILITIES
# ==============================================================================

func _on_btn_heal_pressed() -> void:
	buy_panel.hide()
	sell_panel.hide()
	_update_shop_header_ui()
	heal_panel.show()


func _on_pay_heal_button_pressed() -> void:
	if GameManager.player_current_hp >= GameManager.player_max_hp:
		SoundManager.play_sfx("error")
		return

	if GameManager.shop_coins < HEAL_PRICE:
		SoundManager.play_sfx("error")
		_show_insufficient_coins_feedback(pay_heal_button)
		return

	heal_confirm_dialog.dialog_text = "Heal %d HP dengan %d Koin?" % [HEAL_AMOUNT, HEAL_PRICE]
	heal_confirm_dialog.popup_centered()


func _on_heal_confirmed() -> void:
	if GameManager.shop_coins >= HEAL_PRICE and GameManager.player_current_hp < GameManager.player_max_hp:
		GameManager.shop_coins -= HEAL_PRICE
		GameManager.heal_player(HEAL_AMOUNT)
		SoundManager.play_sfx("heal_success")
		_update_shop_header_ui()
	else:
		SoundManager.play_sfx("error")


func _show_insufficient_coins_feedback(target_control: Control) -> void:
	var orig_color: Color = gold_label.modulate if gold_label else Color.WHITE
	var tween: Tween = create_tween().set_parallel(true)
	if gold_label:
		gold_label.modulate = Color.RED
		tween.tween_property(gold_label, "modulate", orig_color, 0.4)
	
	var orig_pos: Vector2 = target_control.position
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(target_control, "position", orig_pos + Vector2(-6, 0), 0.05)
	shake_tween.tween_property(target_control, "position", orig_pos + Vector2(6, 0), 0.05)
	shake_tween.tween_property(target_control, "position", orig_pos, 0.05)


func _on_btn_leave_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")


func _create_fallback_section() -> SectionData:
	var section = SectionData.new()
	section.cards_common_chance = 70.0
	section.cards_uncommon_chance = 25.0
	section.cards_rare_chance = 5.0
	section.coat_common_chance = 70.0
	section.coat_uncommon_chance = 25.0
	section.coat_rare_chance = 5.0
	section.blessing_common_chance = 60.0
	section.blessing_uncommon_chance = 30.0
	section.blessing_rare_chance = 10.0
	return section
