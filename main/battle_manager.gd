class_name BattleManager
extends Node2D

enum TurnState { PLAYER, ENEMY }
var current_state: TurnState = TurnState.PLAYER
@onready var battle_background: TextureRect = $BattleBackground
const CARD_CARBON_SHIELD: CardData = preload("uid://b1nye4430c7yv")
const CARD_NITRIC_OXIDE: CardData = preload("uid://c7egfvnqlhxde")
const CARD_OXYGEN_GAS: CardData = preload("uid://1rhiulfq30o5")
const CARD_HYDROGEN_PEROXIDE: CardData = preload("uid://db0cc88e3ktnj")
const CARD_CARBON_DIOXIDE: CardData = preload("uid://ck43wj6i8k0f0")

@export var available_cards: Array[CardData] 

@export var default_blessing: BlessingData
#@export var default_aura_1:  AuraCardData

@onready var deck: Deck = $Deck
@onready var hand: Hand = $Hand
@onready var stage_manager: StageManager = $StageManager
@onready var player: Player = $Player

@onready var ui_manager: BattleUIManager = $Subsystems/BattleUIManager
@onready var reward_handler: BattleRewardHandler = $Subsystems/BattleRewardHandler
@onready var card_resolver: CardResolver = $Subsystems/CardResolver

var is_first_turn: bool = true
var current_target: EnemyBase = null
var active_effect_choice: CoatData = null
var is_selecting_effect_target: bool = false
var accumulated_gold: int = 0
@export var aura_1: AuraCardData
@export var aura_2: AuraCardData

@export var blessing_1: BlessingData
@export var blessing_2: BlessingData
@export var blessing_3: BlessingData

func _ready() -> void:
	_setup_background()
	_play_battle_music()
	_connect_signals()
	#BlessingManager.equip_blessing(default_blessing)
	#AuraManager.equip_aura(default_aura_1)
	#AuraManager.equip_aura(aura_1, 0)
	#AuraManager.equip_aura(aura_2, 1)
	#
	#BlessingManager.equip_blessing(blessing_1)
	#BlessingManager.equip_blessing(blessing_2)
	#BlessingManager.equip_blessing(blessing_3)
	
	accumulated_gold = 0
	GameManager.reset_round()
	is_first_turn = true
	player.reset_for_battle()
	BlessingManager.apply_passive_effects(hand)
	_prepare_starting_deck()
	
	EventBus.enemy_killed.connect(_on_boss_killed_check_voice)
	
func _on_boss_killed_check_voice(_enemy: EnemyBase, is_boss: bool) -> void:
	if not is_boss:
		return

	if GameManager.is_gold_boss:
		SoundManager.stop_voice()
		SoundManager.play_voice_once("aurum_end")
		return

	if not GameManager.current_section:
		return
		
	var section_name: String = GameManager.current_section.section_name.to_lower()
	match section_name:
		"cobalt":
			SoundManager.stop_voice()
			SoundManager.play_voice_once("cobalt_end")
		"ferrum":
			SoundManager.stop_voice()
			SoundManager.play_voice_once("ferrum_end")
		"neon":
			SoundManager.stop_voice()
			SoundManager.play_voice_once("neon_end")
		"aurum":
			SoundManager.stop_voice()
			SoundManager.play_voice_once("aurum_end")
	
func _connect_signals() -> void:
	ui_manager.end_turn_button.pressed.connect(_on_end_turn_pressed)
	ui_manager.deck_visual.pressed.connect(func(): ui_manager.show_card_viewer(deck.cards, "SISA KARTU DECK", is_selecting_effect_target))
	ui_manager.discard_visual.pressed.connect(func(): ui_manager.show_card_viewer(deck.discard_pile, "TUMPUKAN BUANGAN", is_selecting_effect_target))
	ui_manager.card_clicked_in_viewer.connect(_on_card_selected_for_effect)
	
	hand.card_added_to_hand.connect(_on_card_added_to_hand)
	player.stats_updated.connect(ui_manager.update_player_stats)
	player.coins_updated.connect(ui_manager.update_tokens)
	
	stage_manager.enemy_turn_ended.connect(_on_enemy_turn_completed)
	stage_manager.wave_cleared.connect(_on_wave_cleared)
	stage_manager.round_won.connect(_on_round_won)
	
	EventBus.enemy_selected.connect(_on_enemy_selected)
	EventBus.enemy_died.connect(_on_enemy_died)
	
	reward_handler.effect_target_requested.connect(_on_effect_target_requested)

func _setup_background() -> void:
	if not battle_background:
		return

	if GameManager.current_section and GameManager.current_section.section_wallpaper != null:
		battle_background.texture = GameManager.current_section.section_wallpaper
	else:
		push_warning("BattleManager: current_section atau section_wallpaper kosong, mempertahankan texture bawaan.")

func _prepare_starting_deck() -> void:
	if GameManager.player_deck.is_empty():
		_build_default_starting_deck()

	SaveManager.discover_cards(GameManager.player_deck)

	for card in GameManager.player_deck:
		var card_copy: CardData = card.duplicate(true) as CardData
		deck.add_card(card_copy)
		
	_start_player_turn()

func _build_default_starting_deck() -> void:
	var deck_composition: Dictionary = {
		CARD_CARBON_SHIELD: 2,
		CARD_NITRIC_OXIDE: 1,
		CARD_OXYGEN_GAS: 1,
		CARD_HYDROGEN_PEROXIDE: 4,
		CARD_CARBON_DIOXIDE: 2
	}
	
	for card_resource: CardData in deck_composition:
		var count: int = deck_composition[card_resource]
		for i in range(count):
			GameManager.player_deck.append(card_resource)
			EventBus.card_obtained.emit(card_resource)

func _on_enemy_turn_completed() -> void:
	EventBus.round_ended.emit()
	_start_player_turn()

func _start_player_turn() -> void:
	current_state = TurnState.PLAYER
	ui_manager.end_turn_button.disabled = true
	
	if is_first_turn:
		is_first_turn = false
	else:
		GameManager.advance_round()
		
	player.set_tokens_by_round(GameManager.current_round)
	EventBus.round_started.emit(GameManager.current_round)
	
	var cards_to_draw: int = hand.max_hand_size - hand.cards_in_hand.size()
	for i in range(cards_to_draw):
		await get_tree().create_timer(0.2).timeout 
		_draw_single_card()
	
	await get_tree().create_timer(0.3).timeout 
	ui_manager.end_turn_button.disabled = false

func _draw_single_card() -> void:
	var drawn_card: CardData = deck.draw_card()
	if drawn_card != null:
		if not hand.add_card(drawn_card):
			deck.cards.append(drawn_card)

func _on_card_added_to_hand(new_card_data: CardData) -> void:
	ui_manager.animate_draw_card(new_card_data, func(real_card_ui: CardUI):
		real_card_ui.drag_ended.connect(_on_card_drag_ended.bind(new_card_data))
	)

func _on_card_drag_ended(card_ui: CardUI, drop_position: Vector2, card_data: CardData) -> void:
	if current_state != TurnState.PLAYER:
		card_ui.return_to_hand()
		return

	if _is_dropped_on_discard(drop_position):
		_manual_discard_card(card_ui, card_data)
		return

	if card_data.card_type == CardData.CardType.BUFF:
		var hovered_enemy = _get_enemy_at_position(drop_position)
		if hovered_enemy != null:
			ui_manager.reject_play(card_ui)
			card_ui.return_to_hand()
			return

	var target_enemy = _get_enemy_at_position(drop_position)
	if target_enemy == null:
		target_enemy = current_target

	_play_card_with_target(card_ui, card_data, target_enemy)

func _play_card_with_target(clicked_ui: CardUI, card_data: CardData, target: EnemyBase) -> void:
	if not player.can_afford(card_data):
		ui_manager.reject_play(clicked_ui)
		clicked_ui.return_to_hand()
		return

	var success = card_resolver.execute_card_logic(card_data, player, target, stage_manager)
	
	if success:
		hand.remove_card(card_data)
		
		if _should_exhaust_card(card_data):
			print("Kartu dengan Coat Purify hancur dan tidak masuk ke Discard Pile!")
		else:
			deck.add_to_discard(card_data)
			
		clicked_ui.queue_free()
		ui_manager.arrange_hand()
	else:
		ui_manager.reject_play(clicked_ui)
		clicked_ui.return_to_hand()

func _manual_discard_card(card_ui: CardUI, card_data: CardData) -> void:
	hand.remove_card(card_data)
	deck.add_to_discard(card_data)
	card_ui.queue_free()
	ui_manager.arrange_hand()
	
	player.add_random_token(1)
	
	EventBus.card_manually_discarded.emit(card_data)

func _is_dropped_on_discard(drop_position: Vector2) -> bool:
	var discard_rect = ui_manager.discard_visual.get_global_rect()
	return discard_rect.has_point(drop_position)

func _get_enemy_at_position(pos: Vector2) -> EnemyBase:
	for child in stage_manager.get_children():
		if child is EnemyBase and is_instance_valid(child) and not child.is_queued_for_deletion():
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = pos
			query.collide_with_areas = true
			var results = space_state.intersect_point(query)
			
			for result in results:
				if result.collider.get_parent() == child:
					return child
	return null

func _play_card(clicked_ui: CardUI, card_data: CardData) -> void:
	if current_state != TurnState.PLAYER:
		ui_manager.reject_play(clicked_ui)
		return

	if not player.can_afford(card_data):
		ui_manager.reject_play(clicked_ui)
		return

	var success = card_resolver.execute_card_logic(card_data, player, current_target, stage_manager)
	
	if success:
		hand.remove_card(card_data)
		
		if _should_exhaust_card(card_data):
			print("Kartu dengan Coat Purify hancur dan tidak masuk ke Discard Pile!")
		else:
			deck.add_to_discard(card_data)
			
		clicked_ui.queue_free()
		ui_manager.arrange_hand()
	else:
		ui_manager.reject_play(clicked_ui)

func _should_exhaust_card(card_data: CardData) -> bool:
	if card_data.coat_data != null:
		if card_data.coat_data.coat_type == CoatData.EffectCoatType.PURIFY:
			return true
	return false

func _discard_hand_to_deck() -> void:
	var remaining_cards: Array[CardData] = []
	var cards_to_discard: Array[CardData] = []

	for card in hand.cards_in_hand:
		var coat: CoatData = card.coat_data
		
		if coat and (coat.coat_type == CoatData.EffectCoatType.CRYSTALIZED or coat.is_retained):
			remaining_cards.append(card)
			
			if coat.retain_shield_bonus > 0:
				_apply_crystalized_shield(coat.retain_shield_bonus)
		else:
			cards_to_discard.append(card)

	for card in cards_to_discard:
		deck.add_to_discard(card)

	hand.cards_in_hand = remaining_cards
	hand.hand_updated.emit(hand.cards_in_hand.size(), hand.max_hand_size)

	_update_hand_ui_after_discard(cards_to_discard)

func _apply_crystalized_shield(amount: int) -> void:
	if player.has_method("add_shield"):
		player.add_shield(amount)
	elif player.has_method("gain_shield"):
		player.gain_shield(amount)
	elif "shield" in player:
		player.shield += amount
		player.stats_updated.emit()

func _update_hand_ui_after_discard(discarded_cards: Array[CardData]) -> void:
	if ui_manager.has_method("remove_discarded_card_visuals"):
		ui_manager.remove_discarded_card_visuals(discarded_cards)
	else:
		_default_clean_discarded_ui(discarded_cards)

func _default_clean_discarded_ui(discarded_cards: Array[CardData]) -> void:
	var hand_container: Node = ui_manager.hand_container if "hand_container" in ui_manager else null
	if not hand_container:
		return

	for child in hand_container.get_children():
		if child is CardUI and child.data in discarded_cards:
			child.queue_free()

	ui_manager.arrange_hand()

func _on_end_turn_pressed() -> void:
	if current_state != TurnState.PLAYER: return
	
	current_state = TurnState.ENEMY
	ui_manager.end_turn_button.disabled = true

	AuraManager.prepare_next_round_accumulator()

	_deselect_current_enemy()
	_discard_hand_to_deck()
	stage_manager.execute_enemies_turn()

func _deselect_current_enemy() -> void:
	current_target = null
	EventBus.enemy_selected.emit(null)

func _on_enemy_selected(enemy: EnemyBase) -> void:
	current_target = enemy

func _on_enemy_died(dead_enemy: EnemyBase) -> void:
	if current_target == dead_enemy:
		current_target = null
		
	if dead_enemy and dead_enemy.stats:
		accumulated_gold += dead_enemy.stats.gold_out

func _on_wave_cleared() -> void:
	_discard_hand_to_deck()
	GameManager.reset_round()
	_start_player_turn()

func _on_round_won() -> void:
	ui_manager.end_turn_button.disabled = true
	if accumulated_gold > 0:
		GameManager.add_shop_coins(accumulated_gold)

	if GameManager.current_floor >= 15 and GameManager.active_event_type == MapNodeData.NodeType.BOSS:
		await get_tree().create_timer(1.0).timeout
		_trigger_victory()
		return

	await get_tree().create_timer(1.5).timeout
	
	ui_manager.clear_hand_visuals()
	ui_manager.set_battle_hud_visible(false)
	
	reward_handler.show_reward_screen()

func _trigger_victory() -> void:

	SaveManager.reset_run_data()
	
	get_tree().paused = true
	var recap_scene = load("res://ui/recap/recap_ui.tscn")
	if recap_scene:
		var recap_instance = recap_scene.instantiate() as RecapUI
		get_tree().root.add_child(recap_instance)
		recap_instance.setup_recap(true)
		queue_free()
	
	

func _on_effect_target_requested(chosen_coat: CoatData) -> void:
	active_effect_choice = chosen_coat
	is_selecting_effect_target = true

	var uncoated_cards = GameManager.player_deck.filter(
		func(card: CardData): return card.coat_data == null
	)
	
	ui_manager.show_card_viewer(uncoated_cards, "PILIH 1 KARTU UNTUK DIBERIKAN COAT: " + chosen_coat.coat_name, true)

func _on_card_selected_for_effect(target_card: CardData) -> void:
	if is_selecting_effect_target:
		is_selecting_effect_target = false
		reward_handler.apply_effect_to_card(target_card, active_effect_choice)
		active_effect_choice = null

func _play_battle_music() -> void:
	if GameManager.is_gold_boss == true:
		SoundManager.play_bgm("aurum")
		_play_aurum_voice()
		return
	if GameManager.active_event_type != MapNodeData.NodeType.BOSS:
		SoundManager.play_bgm("battle")
		return

	if GameManager.current_section == null:
		push_warning("Boss battle tidak memiliki current_section!")
		SoundManager.play_bgm("battle")
		return

	var section_name: String = GameManager.current_section.section_name.to_lower()

	match section_name:
		"ferrum":
			SoundManager.play_bgm("ferrum")
			_play_ferrum_voice()

		"cobalt":
			SoundManager.play_bgm("cobalt")
			_play_cobalt_voice()

		"section neon":
			SoundManager.play_bgm("neon")
			_play_neon_voice()

		"aurum":
			SoundManager.play_bgm("aurum")
			_play_aurum_voice()

		_:
			push_warning("Musik boss belum ditemukan untuk section: " + section_name)
			SoundManager.play_bgm("battle")

func _play_ferrum_voice() -> void:
	if not GameManager.ferrum_intro_seen:
		GameManager.ferrum_intro_seen = true
		SoundManager.play_voice_once("ferrum_intro", func():
			SoundManager.play_random_voice_playlist("ferrum_main")
		)
	else:
		SoundManager.play_random_voice_playlist("ferrum_main")

func _play_cobalt_voice() -> void:
	if not GameManager.cobalt_intro_seen:
		GameManager.cobalt_intro_seen = true
		SoundManager.play_voice_once("cobalt_intro", func():
			SoundManager.play_random_voice_playlist("cobalt_main")
		)
	else:
		SoundManager.play_random_voice_playlist("cobalt_main")

func _play_neon_voice() -> void:
	if not GameManager.neon_intro_seen:
		GameManager.neon_intro_seen = true
		SoundManager.play_voice_once("neon_intro", func():
			SoundManager.play_random_voice_playlist("neon_main")
		)
	else:
		SoundManager.play_random_voice_playlist("neon_main")
		
func _play_aurum_voice() -> void:
	if not GameManager.aurum_intro_seen:
		GameManager.aurum_intro_seen = true
		SoundManager.play_voice_once("aurum_intro", func():
			SoundManager.play_random_voice_playlist("aurum_main")
		)
	else:
		SoundManager.play_random_voice_playlist("aurum_main")


func get_discard_pile() -> Array[CardData]:
	if deck:
		return deck.discard_pile
	return []


func get_deck_cards() -> Array[CardData]:
	if deck:
		return deck.cards
	return []


func get_accumulated_gold() -> int:
	return accumulated_gold

func _trigger_defeat() -> void:

	SaveManager.reset_run_data()

	get_tree().paused = true
	var recap_scene = load("res://ui/recap/recap_ui.tscn")
	if recap_scene:
		var recap_instance = recap_scene.instantiate() as RecapUI
		get_tree().root.add_child(recap_instance)
		recap_instance.setup_recap(false) 
		queue_free()
		
	# Hapus data run juga saat kalah

func _exit_tree() -> void:
	SoundManager.stop_voice()
