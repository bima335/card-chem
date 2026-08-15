class_name BattleRewardHandler
extends Node

@export var card_ui_scene: PackedScene
@export var aura_card_ui_scene: PackedScene
@export var available_cards: Array[CardData]
@export var available_coats: Array[CoatData]

@export_group("Reward UI")
@export var reward_backdrop: ColorRect
@export var reward_title: Label
@export var reward_card_grid: HBoxContainer
@export var skip_button: Button

signal effect_target_requested(coat_data: CoatData)

const DROP_RATES_PER_SECTION: Array[Dictionary] = [
	{ 0: 60.0, 1: 35.0, 2: 15.0 },
	{ 0: 35.0, 1: 45.0, 2: 20.0 },
	{ 0: 15.0, 1: 45.0, 2: 40.0 }
]


func _ready() -> void:
	if skip_button and not skip_button.pressed.is_connected(_return_to_map):
		skip_button.pressed.connect(_return_to_map)


func show_reward_screen() -> void:
	#GameManager.shop_coins += 321
	
	for child in reward_card_grid.get_children():
		child.queue_free()
	
	match GameManager.active_event_type:
		MapNodeData.NodeType.BATTLE_NORMAL:
			_setup_normal_reward()
		MapNodeData.NodeType.BATTLE_HARD:
			_setup_hard_reward()
		MapNodeData.NodeType.BOSS: 
			_setup_boss_reward()
		_:
			reward_title.text = "VICTORY!\n"
			skip_button.show()
			skip_button.text = "Kembali ke Peta"
		
	reward_backdrop.show()


func _setup_normal_reward() -> void:
	reward_title.text = "VICTORY!\n (Total: " + str(GameManager.shop_coins) + ")\n\nPilih 1 Kartu Baru:"
	skip_button.show() 
	skip_button.text = "Lewati Kartu & Kembali ke Peta"
	
	var valid_reward_pool: Array[CardData] = available_cards.filter(func(c): return c.can_be_reward)
	var selected_cards = _pick_weighted_rewards(valid_reward_pool, 3)
	
	for card_data in selected_cards:
		var card_ui = card_ui_scene.instantiate() as CardUI
		reward_card_grid.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true 
		card_ui.pressed.connect(_on_reward_card_chosen.bind(card_data))


func _setup_hard_reward() -> void:
	reward_title.text = "HARD VICTORY!\n (Total: " + str(GameManager.shop_coins) + ")\n\nPILIH 1 EFFECT COAT UNTUK KARTUMU:"
	skip_button.hide() 
	
	if available_coats.is_empty():
		push_error("[BattleRewardHandler] ERROR: available_coats belum diisi di Inspector!")
		_return_to_map()
		return
	
	var selected_coats = _pick_weighted_rewards(available_coats, 3)
	
	for coat in selected_coats:
		_build_coat_reward_slot(coat)


func _build_coat_reward_slot(coat_data: CoatData) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(160, 200)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.tooltip_text = _build_coat_tooltip(coat_data)
	
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(150, 220)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = coat_data.icon
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var name_lbl: Label = Label.new()
	name_lbl.text = coat_data.coat_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var select_btn: Button = Button.new()
	select_btn.text = "Pilih Coat"
	select_btn.pressed.connect(_on_effect_chosen.bind(coat_data))
	
	box.add_child(icon_rect)
	box.add_child(name_lbl)
	box.add_child(select_btn)
	reward_card_grid.add_child(box)


func _build_coat_tooltip(coat: CoatData) -> String:
	var type_name: String = CoatData.EffectCoatType.keys()[coat.coat_type]
	var text: String = "%s\n" % coat.coat_name
	text += "Type: %s\n" % type_name
	text += "Rarity: %s\n\n" % _get_rarity_name(int(coat.rarity))
	text += coat.description
	return text


func _get_rarity_name(rarity_idx: int) -> String:
	match rarity_idx:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		_: return "Normal"


func _setup_boss_reward() -> void:
	reward_title.text = "BOSS DEFEATED!\n\nPILIH 1 AURA CARD:"
	skip_button.hide()
	
	var current_section: SectionData = GameManager.current_section
	
	if current_section == null or current_section.boss_aura_rewards.is_empty():
		print_debug("[RewardHandler] WARN: GameManager.current_section bernilai null atau boss_aura_rewards kosong!")
		reward_title.text = "BOSS DEFEATED!\n(Tidak ada Aura Card tersedia)"
		skip_button.show()
		skip_button.text = "Lanjut ke Peta"
		return

	var aura_pool: Array[AuraCardData] = current_section.boss_aura_rewards.duplicate()
	aura_pool.shuffle()
	
	var choice_count: int = mini(3, aura_pool.size())
	for i in range(choice_count):
		var aura_data: AuraCardData = aura_pool[i]
		
		if aura_card_ui_scene == null:
			push_error("[RewardHandler] ERROR: aura_card_ui_scene belum di-assign di Inspector!")
			return

		var aura_ui = aura_card_ui_scene.instantiate() as AuraCardUI
		reward_card_grid.add_child(aura_ui)
		aura_ui.setup(aura_data)
		aura_ui.aura_selected.connect(_on_aura_reward_chosen)


func _pick_weighted_rewards(source_pool: Array, count: int) -> Array:
	var selected_items: Array = []
	var pool_copy: Array = source_pool.duplicate()
	var section_index: int = _get_current_section_index()
	var current_rates: Dictionary = DROP_RATES_PER_SECTION[section_index]
	
	var target_count: int = mini(count, pool_copy.size())
	
	for i in range(target_count):
		if pool_copy.is_empty():
			break
			
		var rolled_rarity: int = _roll_rarity(current_rates)
		var candidate_items = pool_copy.filter(func(item): return item.rarity == rolled_rarity)
		
		if candidate_items.is_empty():
			candidate_items = pool_copy
			
		var chosen_item = candidate_items.pick_random()
		selected_items.append(chosen_item)
		pool_copy.erase(chosen_item)
		
	return selected_items


func _roll_rarity(rates: Dictionary) -> int:
	var total_weight: float = 0.0
	for weight in rates.values():
		total_weight += weight
		
	var roll: float = randf_range(0.0, total_weight)
	var accumulated_weight: float = 0.0
	
	for rarity_key in rates:
		accumulated_weight += rates[rarity_key]
		if roll <= accumulated_weight:
			return rarity_key
			
	return 0


func _get_current_section_index() -> int:
	var section_idx: int = GameManager.current_floor / 5
	return clamp(section_idx, 0, DROP_RATES_PER_SECTION.size() - 1)


func _on_aura_reward_chosen(chosen_aura: AuraCardData) -> void:
	if AuraManager:
		var equipped_successfully: bool = AuraManager.equip_aura(chosen_aura, -1)
		
		if not equipped_successfully:
			push_error("[BattleRewardHandler] Gagal memasang Aura Card!")
	
	if SaveManager:
		SaveManager.unlock_aura(chosen_aura)
		
	_return_to_map()


func _on_reward_card_chosen(chosen_card: CardData) -> void:
	var new_card = chosen_card.duplicate(true)
	GameManager.player_deck.append(new_card)
	SaveManager.discover_card(chosen_card)
	EventBus.card_obtained.emit(chosen_card)
	
	_return_to_map()


func _on_effect_chosen(chosen_coat: CoatData) -> void:
	reward_backdrop.hide()
	effect_target_requested.emit(chosen_coat)


func apply_effect_to_card(target_card: CardData, active_coat: CoatData) -> void:
	target_card.coat_data = active_coat
	
	if active_coat.coat_type == CoatData.EffectCoatType.CLONE:
		var cloned_card = target_card.duplicate(true)
		GameManager.player_deck.append(cloned_card)
		EventBus.card_obtained.emit(cloned_card)

	SaveManager.discover_coat(active_coat)
	SaveManager.save_game()
			
	_return_to_map()


func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
