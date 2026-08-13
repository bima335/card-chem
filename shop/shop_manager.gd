class_name ShopManager
extends Control

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
@export var available_coats: Array[CoatData] = []
@export var available_blessings: Array[BlessingData] = []

const HEAL_PRICE: int = 20
const HEAL_AMOUNT: int = 15

var is_shop_generated: bool = false
var pending_coat: CoatData = null
var pending_coat_slot_button: Button = null
var pending_coat_price: int = 0


func _ready() -> void:
	SoundManager.play_bgm("shop_theme")
	_update_coin_display()
	
	btn_buy.pressed.connect(_on_btn_buy_pressed)
	btn_heal.pressed.connect(_on_btn_heal_pressed)
	btn_sell.pressed.connect(_on_btn_sell_pressed)
	btn_leave.pressed.connect(_on_btn_leave_pressed)
	
	if btn_close_buy:
		btn_close_buy.pressed.connect(func(): buy_panel.hide())
	if btn_cancel_deck_select:
		btn_cancel_deck_select.pressed.connect(func(): deck_selector_overlay.hide())


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
		var picked = _pick_item_by_rarity(buff_utility_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance)
		chosen_cards.append(picked)
		
	for i in range(2):
		var valid_atk_pool = atk_trigger_pool.filter(func(c): return not chosen_cards.has(c))
		if not valid_atk_pool.is_empty():
			var picked = _pick_item_by_rarity(valid_atk_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance)
			chosen_cards.append(picked)
			
	while chosen_cards.size() < 5:
		var remaining_pool = available_cards.filter(func(c): return not chosen_cards.has(c))
		if remaining_pool.is_empty():
			break
		var picked = _pick_item_by_rarity(remaining_pool, current_section.cards_common_chance, current_section.cards_uncommon_chance, current_section.cards_rare_chance)
		chosen_cards.append(picked)

	for card in chosen_cards:
		_build_card_slot_ui(card)


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


func _pick_item_by_rarity(pool: Array, c_chance: float, u_chance: float, r_chance: float) -> Variant:
	var rolled_rarity_idx: int = _roll_rarity(c_chance, u_chance, r_chance)
	
	var matching_items = pool.filter(func(item): return int(item.rarity) == rolled_rarity_idx)
	
	if not matching_items.is_empty():
		return matching_items.pick_random()
	
	return pool.pick_random()



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
		var new_card = card_data.duplicate(true)
		GameManager.player_deck.append(new_card)
		SaveManager.discover_card(card_data)
		EventBus.card_obtained.emit(card_data)
		_update_coin_display()
		SoundManager.play_sfx("buy_success")
		
		btn.disabled = true
		btn.text = "DIBELI"
	else:
		SoundManager.play_sfx("error")


func _build_coat_slot_ui(coat_data: CoatData) -> void:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(180, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var name_lbl = Label.new()
	name_lbl.text = coat_data.coat_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var desc_lbl = Label.new()
	desc_lbl.text = coat_data.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var buy_btn = Button.new()
	var price = coat_data.buy_price if coat_data.buy_price > 0 else 15
	buy_btn.text = "Beli (" + str(price) + " Koin)"
	buy_btn.pressed.connect(_on_buy_coat_clicked.bind(coat_data, price, buy_btn))
	
	box.add_child(name_lbl)
	box.add_child(desc_lbl)
	box.add_child(buy_btn)
	coat_grid.add_child(box)


func _on_buy_coat_clicked(coat_data: CoatData, price: int, btn: Button) -> void:
	if GameManager.shop_coins < price:
		SoundManager.play_sfx("error")
		return

	if GameManager.player_deck.is_empty():
		SoundManager.play_sfx("error")
		return

	pending_coat = coat_data
	pending_coat_slot_button = btn
	pending_coat_price = price
	
	_open_deck_selector_for_coat()


func _open_deck_selector_for_coat() -> void:
	for child in deck_card_grid.get_children():
		child.queue_free()

	var available_deck_cards = GameManager.player_deck.filter(
		func(card: CardData): return card.coat_data == null
	)

	for card_data in available_deck_cards:
		var card_ui = card_ui_scene.instantiate() as CardUI
		deck_card_grid.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true
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


func _player_has_blessing(blessing: BlessingData) -> bool:
	return BlessingManager.has_blessing(blessing.id)


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


func _on_buy_blessing_clicked(blessing: BlessingData, price: int, btn: Button) -> void:
	if GameManager.shop_coins < price:
		SoundManager.play_sfx("error")
		_show_insufficient_coins_feedback(btn)
		return

	var success: bool = BlessingManager.equip_blessing(blessing)
	
	if success:
		GameManager.shop_coins -= price
		_update_coin_display()
		SaveManager.unlock_blessing(blessing)
		SoundManager.play_sfx("buy_success")
		btn.disabled = true
		btn.text = "DIBELI"
	else:
		SoundManager.play_sfx("error")
		_show_blessing_failed_feedback(btn)


func _show_insufficient_coins_feedback(target_btn: Button) -> void:
	var orig_color: Color = coin_label.modulate
	var tween: Tween = create_tween().set_parallel(true)
	
	coin_label.modulate = Color.RED
	tween.tween_property(coin_label, "modulate", orig_color, 0.4)
	
	var orig_pos: Vector2 = target_btn.position
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(target_btn, "position", orig_pos + Vector2(-6, 0), 0.05)
	shake_tween.tween_property(target_btn, "position", orig_pos + Vector2(6, 0), 0.05)
	shake_tween.tween_property(target_btn, "position", orig_pos, 0.05)


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
