class_name BattleRewardHandler
extends Node

@export var card_ui_scene: PackedScene
@export var available_cards: Array[CardData]

@export_group("Reward UI")
@export var reward_backdrop: ColorRect
@export var reward_title: Label
@export var reward_card_grid: HBoxContainer
@export var skip_button: Button

signal effect_target_requested(effect_name: String)

# Gunakan _ready() agar dieksekusi otomatis oleh Godot saat node siap
func _ready() -> void:
	if skip_button:
		if not skip_button.pressed.is_connected(_return_to_map):
			skip_button.pressed.connect(_return_to_map)

func show_reward_screen() -> void:
	GameManager.shop_coins += 10
	
	for child in reward_card_grid.get_children():
		child.queue_free()
	
	match GameManager.active_event_type:
		MapNodeData.NodeType.BATTLE_NORMAL:
			_setup_normal_reward()
		MapNodeData.NodeType.BATTLE_HARD:
			_setup_hard_reward()
		_:
			reward_title.text = "VICTORY!\n+10 Shop Coins"
			skip_button.show()
			skip_button.text = "Kembali ke Peta"
		
	reward_backdrop.show()

func _setup_normal_reward() -> void:
	reward_title.text = "VICTORY!\n+10 Shop Coins (Total: " + str(GameManager.shop_coins) + ")\n\nPilih 1 Kartu Baru:"
	skip_button.show() 
	skip_button.text = "Lewati Kartu & Kembali ke Peta"
	
	var valid_reward_pool: Array[CardData] = available_cards.filter(func(c): return c.can_be_reward)
	valid_reward_pool.shuffle()
	
	var choice_count = mini(3, valid_reward_pool.size())
	for i in range(choice_count):
		var card_data = valid_reward_pool[i]
		var card_ui = card_ui_scene.instantiate() as CardUI
		reward_card_grid.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.is_preview = true 
		card_ui.pressed.connect(_on_reward_card_chosen.bind(card_data))

func _setup_hard_reward() -> void:
	reward_title.text = "HARD VICTORY!\n+10 Shop Coins (Total: " + str(GameManager.shop_coins) + ")\n\nPILIH 1 EFFECT COAT UNTUK KARTUMU:"
	skip_button.hide() 
	
	var effects = ["UNSTABLE", "INSULATED", "CLONE"]
	var effect_desc = [
		"UNSTABLE\n(2x Damage, 1/2 Self Damage)", 
		"INSULATED\n(Mencegah kartu di-drain)", 
		"CLONE\n(Gandakan kartu ke Deck)"
	]
	
	for i in range(effects.size()):
		var btn = Button.new()
		btn.text = effect_desc[i]
		btn.custom_minimum_size = Vector2(180, 250)
		btn.pressed.connect(_on_effect_chosen.bind(effects[i]))
		reward_card_grid.add_child(btn)

func _on_reward_card_chosen(chosen_card: CardData) -> void:
	GameManager.player_deck.append(chosen_card.duplicate(true))
	_return_to_map()

func _on_effect_chosen(effect_name: String) -> void:
	reward_backdrop.hide()
	effect_target_requested.emit(effect_name)

func apply_effect_to_card(target_card: CardData, active_effect: String) -> void:
	match active_effect:
		"UNSTABLE":
			target_card.coat = CardData.EffectCoat.UNSTABLE
		"INSULATED":
			target_card.coat = CardData.EffectCoat.INSULATED
		"CLONE":
			target_card.coat = CardData.EffectCoat.CLONE
			var cloned_card = target_card.duplicate(true)
			GameManager.player_deck.append(cloned_card)
			
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
