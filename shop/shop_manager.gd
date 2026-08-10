class_name ShopManager
extends Control

enum ZoneType { FERRUM, COBALT, NEON }

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

@export var card_ui_scene: PackedScene
@export var available_cards: Array[CardData] = []
@export var available_blessings: Array[BlessingData] = []

const HEAL_PRICE: int = 20
const HEAL_AMOUNT: int = 15

var current_zone: ZoneType = ZoneType.FERRUM
var is_shop_generated: bool = false
var pending_coat_effect: CardData.EffectCoat = CardData.EffectCoat.NONE
var pending_coat_slot_button: Button = null
var pending_coat_price: int = 0

const COAT_DATABASE: Dictionary = {
	CardData.EffectCoat.CLONE: {"name": "Clone", "desc": "Give 1 Copy of card to deck", "price": 20},
	CardData.EffectCoat.UNSTABLE: {"name": "Unstable", "desc": "2x dmg to enemy, 1/2 self-dmg (Only ATTACK)", "price": 16},
	CardData.EffectCoat.INSULATED: {"name": "Insulated", "desc": "Prevent card from being drained", "price": 12},
	CardData.EffectCoat.CRYSTALIZED: {"name": "Crystalized", "desc": "Retain status. +1 Shield if unused", "price": 14},
	CardData.EffectCoat.PURIFY: {"name": "Purify", "desc": "Remove debuff, gain tokens, card breaks", "price": 10},
	CardData.EffectCoat.CATALYST: {"name": "Catalyst", "desc": "Reduce cost by 1 random token", "price": 13}
}


func _ready() -> void:
	SoundManager.play_bgm("shop_theme")
	_update_coin_display()
	_determine_current_zone()
	
	btn_buy.pressed.connect(_on_btn_buy_pressed)
	btn_heal.pressed.connect(_on_btn_heal_pressed)
	btn_sell.pressed.connect(_on_btn_sell_pressed)
	btn_leave.pressed.connect(_on_btn_leave_pressed)
	
	if btn_close_buy:
		btn_close_buy.pressed.connect(func(): buy_panel.hide())
	if btn_cancel_deck_select:
		btn_cancel_deck_select.pressed.connect(func(): deck_selector_overlay.hide())


func _determine_current_zone() -> void:
	var section_idx: int = GameManager.current_floor / 5
	match section_idx:
		0: current_zone = ZoneType.FERRUM
		1: current_zone = ZoneType.COBALT
		_: current_zone = ZoneType.NEON


func _update_coin_display() -> void:
	coin_label.text = "Koin: " + str(GameManager.shop_coins)
	var tween = create_tween()
	coin_label.scale = Vector2(1.3, 1.3)
	tween.tween_property(coin_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)


func _on_btn_buy_pressed() -> void:
	sell_panel.hide()
	
	if not is_shop_generated:
		_generate_shop_stock()
		is_shop_generated = true
		
	buy_panel.show()


func _generate_shop_stock() -> void:
	_clear_all_grids()
	_generate_cards_stock()
	_generate_coats_stock()
	_generate_blessings_stock()


func _clear_all_grids() -> void:
	for c in card_grid.get_children(): c.queue_free()
	for c in coat_grid.get_children(): c.queue_free()
	for c in blessing_grid.get_children(): c.queue_free()


func _generate_cards_stock() -> void:
	if available_cards.is_empty():
		return

	var chosen_cards: Array[CardData] = []
	
	var buff_utility_pool: Array[CardData] = available_cards.filter(
		func(c): return c.card_type == CardData.CardType.BUFF or c.card_type == CardData.CardType.DEBUFF
	)
	var atk_trigger_pool: Array[CardData] = available_cards.filter(
		func(c): return c.card_type == CardData.CardType.ATK or c.card_type == CardData.CardType.TRIGGER
	)
	
	if not buff_utility_pool.is_empty():
		var picked = _pick_card_by_rarity(buff_utility_pool)
		chosen_cards.append(picked)
		
	for i in range(2):
		var valid_atk_pool = atk_trigger_pool.filter(func(c): return not chosen_cards.has(c))
		if not valid_atk_pool.is_empty():
			var picked = _pick_card_by_rarity(valid_atk_pool)
			chosen_cards.append(picked)
			
	while chosen_cards.size() < 5:
		var remaining_pool = available_cards.filter(func(c): return not chosen_cards.has(c))
		if remaining_pool.is_empty():
			break
		var picked = _pick_card_by_rarity(remaining_pool)
		chosen_cards.append(picked)

	for card in chosen_cards:
		_build_card_slot_ui(card)


func _pick_card_by_rarity(pool: Array[CardData]) -> CardData:
	var target_rarity = _roll_rarity_for_current_zone()
	var matching_cards = pool.filter(func(c): return c.rarity == target_rarity)
	
	if matching_cards.is_empty():
		return pool.pick_random()
	return matching_cards.pick_random()


func _roll_rarity_for_current_zone() -> CardData.Rarity:
	var roll = randf() * 100.0
	match current_zone:
		ZoneType.FERRUM:
			if roll < 70.0: return CardData.Rarity.COMMON
			elif roll < 95.0: return CardData.Rarity.UNCOMMON
			else: return CardData.Rarity.RARE
		ZoneType.COBALT:
			if roll < 35.0: return CardData.Rarity.COMMON
			elif roll < 85.0: return CardData.Rarity.UNCOMMON
			else: return CardData.Rarity.RARE
		ZoneType.NEON:
			if roll < 15.0: return CardData.Rarity.COMMON
			elif roll < 60.0: return CardData.Rarity.UNCOMMON
			else: return CardData.Rarity.RARE
	return CardData.Rarity.COMMON


func _build_card_slot_ui(card_data: CardData) -> void:
	var slot_container = VBoxContainer.new()
	slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var card_ui = card_ui_scene.instantiate() as CardUI
	slot_container.add_child(card_ui)
	card_ui.setup(card_data)
	card_ui.is_preview = true
	
	var buy_btn = Button.new()
	var price = card_data.buy_value if card_data.buy_value > 0 else 15
	buy_btn.text = "Beli (" + str(price) + " Koin)"
	buy_btn.pressed.connect(_on_buy_card_clicked.bind(card_data, price, buy_btn))
	
	slot_container.add_child(buy_btn)
	card_grid.add_child(slot_container)


func _on_buy_card_clicked(card_data: CardData, price: int, btn: Button) -> void:
	if GameManager.shop_coins >= price:
		GameManager.shop_coins -= price
		GameManager.player_deck.append(card_data.duplicate(true))
		
		_update_coin_display()
		SoundManager.play_sfx("buy_success")
		
		btn.disabled = true
		btn.text = "DIBELI"
	else:
		SoundManager.play_sfx("error")

func _generate_coats_stock() -> void:
	var all_coats = COAT_DATABASE.keys()
	all_coats.shuffle()
	
	var coat_1: CardData.EffectCoat = all_coats[0]
	var coat_2: CardData.EffectCoat = all_coats[1]
	
	_build_coat_slot_ui(coat_1)
	_build_coat_slot_ui(coat_2)


func _build_coat_slot_ui(coat_enum: CardData.EffectCoat) -> void:
	var info = COAT_DATABASE[coat_enum]
	
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(180, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var name_lbl = Label.new()
	name_lbl.text = info["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var desc_lbl = Label.new()
	desc_lbl.text = info["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var buy_btn = Button.new()
	buy_btn.text = "Beli (" + str(info["price"]) + " Koin)"
	buy_btn.pressed.connect(_on_buy_coat_clicked.bind(coat_enum, info["price"], buy_btn))
	
	box.add_child(name_lbl)
	box.add_child(desc_lbl)
	box.add_child(buy_btn)
	coat_grid.add_child(box)


func _on_buy_coat_clicked(coat_enum: CardData.EffectCoat, price: int, btn: Button) -> void:
	if GameManager.shop_coins < price:
		SoundManager.play_sfx("error")
		return

	if GameManager.player_deck.is_empty():
		print("Deck kosong, tidak ada kartu yang bisa diberi Effect Coat!")
		SoundManager.play_sfx("error")
		return

	pending_coat_effect = coat_enum
	pending_coat_slot_button = btn
	pending_coat_price = price
	
	_open_deck_selector_for_coat()


func _open_deck_selector_for_coat() -> void:
	for child in deck_card_grid.get_children():
		child.queue_free()

	for card_data in GameManager.player_deck:
		var card_ui = card_ui_scene.instantiate() as CardUI
		deck_card_grid.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
		card_ui.pressed.connect(_on_card_selected_for_coat.bind(card_data))

	deck_selector_overlay.show()


func _on_card_selected_for_coat(target_card: CardData) -> void:
	if pending_coat_effect == CardData.EffectCoat.UNSTABLE and target_card.card_type != CardData.CardType.ATK:
		print("Unstable Coat hanya bisa dipasang pada kartu bertipe ATTACK!")
		SoundManager.play_sfx("error")
		return

	GameManager.shop_coins -= pending_coat_price
	target_card.coat = pending_coat_effect

	if pending_coat_effect == CardData.EffectCoat.CLONE:
		GameManager.player_deck.append(target_card.duplicate(true))

	_update_coin_display()
	SoundManager.play_sfx("buy_success")

	if pending_coat_slot_button:
		pending_coat_slot_button.disabled = true
		pending_coat_slot_button.text = "DIBELI"

	deck_selector_overlay.hide()
	pending_coat_effect = CardData.EffectCoat.NONE
	pending_coat_slot_button = null
	pending_coat_price = 0

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

	var chosen_blessing = valid_blessings.pick_random()
	_build_blessing_slot_ui(chosen_blessing)


func _player_has_blessing(_blessing: BlessingData) -> bool:
	return false


func _build_blessing_slot_ui(blessing: BlessingData) -> void:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(200, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_lbl = Label.new()
	name_lbl.text = blessing.name if blessing.name != "" else "Blessing Pin"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc_lbl = Label.new()
	desc_lbl.text = blessing.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var buy_btn = Button.new()
	var price = blessing.buy_price if blessing.buy_price > 0 else 25
	buy_btn.text = "Beli (" + str(price) + " Koin)"
	buy_btn.pressed.connect(_on_buy_blessing_clicked.bind(blessing, price, buy_btn))

	box.add_child(name_lbl)
	box.add_child(desc_lbl)
	box.add_child(buy_btn)
	blessing_grid.add_child(box)


func _on_buy_blessing_clicked(_blessing: BlessingData, price: int, btn: Button) -> void:
	if GameManager.shop_coins >= price:
		GameManager.shop_coins -= price
		
		
		_update_coin_display()
		SoundManager.play_sfx("buy_success")
		btn.disabled = true
		btn.text = "DIBELI"
	else:
		SoundManager.play_sfx("error")

func _on_btn_heal_pressed() -> void:
	if GameManager.shop_coins >= HEAL_PRICE:
		if GameManager.player_current_hp < GameManager.player_max_hp:
			GameManager.shop_coins -= HEAL_PRICE
			GameManager.player_current_hp = clampi(GameManager.player_current_hp + HEAL_AMOUNT, 0, GameManager.player_max_hp)
			_update_coin_display()
			SoundManager.play_sfx("heal_success")
		else:
			SoundManager.play_sfx("error")
	else:
		SoundManager.play_sfx("error")


func _on_btn_sell_pressed() -> void:
	buy_panel.hide()
	sell_panel.show()


func _on_btn_leave_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
