class_name BattleManager
extends Node2D

enum TurnState { PLAYER, ENEMY }
var current_state: TurnState = TurnState.PLAYER

@export var available_cards: Array[CardData] 

@onready var deck: Deck = $Deck
@onready var hand: Hand = $Hand
@onready var stage_manager: StageManager = $StageManager
@onready var player: Player = $Player

@onready var ui_manager: BattleUIManager = $Subsystems/BattleUIManager
@onready var reward_handler: BattleRewardHandler = $Subsystems/BattleRewardHandler
@onready var card_resolver: CardResolver = $Subsystems/CardResolver

var current_round: int = 1
var is_first_turn: bool = true
var current_target: EnemyBase = null

var is_selecting_effect_target: bool = false
var active_effect_choice: String = ""

func _ready() -> void:
	SoundManager.play_bgm("battle_theme")
	_connect_signals()
	
	current_round = 1
	is_first_turn = true
	player.reset_for_battle()
	_prepare_starting_deck()

func _connect_signals() -> void:
	ui_manager.end_turn_button.pressed.connect(_on_end_turn_pressed)
	ui_manager.deck_visual.pressed.connect(func(): ui_manager.show_card_viewer(deck.cards, "SISA KARTU DECK", is_selecting_effect_target))
	ui_manager.discard_visual.pressed.connect(func(): ui_manager.show_card_viewer(deck.discard_pile, "TUMPUKAN BUANGAN", is_selecting_effect_target))
	ui_manager.card_clicked_in_viewer.connect(_on_card_selected_for_effect)
	
	hand.card_added_to_hand.connect(_on_card_added_to_hand)
	player.stats_updated.connect(ui_manager.update_player_stats)
	player.coins_updated.connect(ui_manager.update_tokens)
	
	stage_manager.enemy_turn_ended.connect(_start_player_turn)
	stage_manager.wave_cleared.connect(_on_wave_cleared)
	stage_manager.round_won.connect(_on_round_won)
	
	EventBus.enemy_selected.connect(_on_enemy_selected)
	EventBus.enemy_died.connect(_on_enemy_died)
	
	reward_handler.effect_target_requested.connect(_on_effect_target_requested)

func _prepare_starting_deck() -> void:
	if GameManager.player_deck.is_empty():
		for i in range(15):
			if not available_cards.is_empty():
				GameManager.player_deck.append(available_cards.pick_random())

	# PERBAIKAN: Duplikasi Resource kartu agar perubahan di Battle tidak mengacak-acak GameManager secara permanen
	for card in GameManager.player_deck:
		var card_copy = card.duplicate(true) as CardData
		deck.add_card(card_copy)
		
	_start_player_turn()

func _start_player_turn() -> void:
	current_state = TurnState.PLAYER
	ui_manager.end_turn_button.disabled = true
	
	if is_first_turn:
		is_first_turn = false
	else:
		player.gain_tokens(current_round)
		current_round += 1
	
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
		real_card_ui.pressed.connect(_play_card.bind(real_card_ui, new_card_data))
	)

func _play_card(clicked_ui: CardUI, card_data: CardData) -> void:
	if current_state != TurnState.PLAYER:
		ui_manager.reject_play(clicked_ui)
		return

	if not player.can_afford(card_data):
		ui_manager.reject_play(clicked_ui)
		return

	# PERBAIKAN: Menyesuaikan signature eksekusi CardResolver yang baru
	var success = card_resolver.execute_card_logic(card_data, player, current_target, stage_manager)
	
	if success:
		hand.remove_card(card_data)
		deck.add_to_discard(card_data)
		clicked_ui.queue_free()
	else:
		ui_manager.reject_play(clicked_ui)

func _discard_hand_to_deck() -> void:
	for card in hand.cards_in_hand:
		deck.add_to_discard(card)
	hand.cards_in_hand.clear()
	ui_manager.clear_hand_visuals()

func _on_end_turn_pressed() -> void:
	if current_state != TurnState.PLAYER: return
	
	current_state = TurnState.ENEMY
	ui_manager.end_turn_button.disabled = true

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

func _on_wave_cleared() -> void:
	_discard_hand_to_deck()
	_start_player_turn()

func _on_round_won() -> void:
	ui_manager.end_turn_button.disabled = true
	await get_tree().create_timer(1.5).timeout
	reward_handler.show_reward_screen()

func _on_effect_target_requested(effect_name: String) -> void:
	active_effect_choice = effect_name
	is_selecting_effect_target = true
	ui_manager.show_card_viewer(GameManager.player_deck, "PILIH 1 KARTU UNTUK DIBERIKAN COAT: " + effect_name, true)

func _on_card_selected_for_effect(target_card: CardData) -> void:
	if is_selecting_effect_target:
		is_selecting_effect_target = false
		reward_handler.apply_effect_to_card(target_card, active_effect_choice)
		active_effect_choice = ""
