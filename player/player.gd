class_name Player
extends Node

signal coins_updated(oxygen: int, hydrogen: int, carbon: int, nitrogen: int)
signal stats_updated(hp: int, max_hp: int, shield: int, damage: int)
signal stun_status_changed(is_stunned: bool)

const MAX_TOKEN: int = 7

@export var oxygen: int = 0
@export var hydrogen: int = 0
@export var carbon: int = 0
@export var nitrogen: int = 0

@export var max_hp: int = GameManager.player_max_hp
var current_hp: int = GameManager.player_current_hp
var shield: int = 0
@export var base_damage: int = 0

var is_stunned: bool = false
var stun_duration: int = 0
var active_dazzle_stacks: int = 0


func _ready() -> void:
	if EventBus.has_signal("player_damage_requested"):
		if not EventBus.player_damage_requested.is_connected(take_damage):
			EventBus.player_damage_requested.connect(take_damage)
		
	if EventBus.has_signal("siphon_token_requested"):
		EventBus.siphon_token_requested.connect(_on_siphon_token_requested)
		
	if EventBus.has_signal("player_stunned_requested"):
		EventBus.player_stunned_requested.connect(apply_stun)
		
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)
		
	if EventBus.has_signal("dazzle_stacks_changed"):
		EventBus.dazzle_stacks_changed.connect(_on_dazzle_stacks_changed)

	if AuraManager.has_signal("aura_equipped"):
		AuraManager.aura_equipped.connect(_on_aura_changed)
	if AuraManager.has_signal("aura_unequipped"):
		AuraManager.aura_unequipped.connect(_on_aura_changed)


func reset_for_battle() -> void:
	shield = 0
	carbon = 3
	hydrogen = 3
	oxygen = 3
	nitrogen = 3
	is_stunned = false
	stun_duration = 0
	active_dazzle_stacks = 0
	clamp_tokens_to_max()
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
	stats_updated.emit(current_hp, max_hp, shield, base_damage)


func apply_stun(duration: int) -> void:
	is_stunned = true
	stun_duration = max(1, duration)
	stun_status_changed.emit(true)
	EventBus.player_stunned.emit(stun_duration)


func can_take_action() -> bool:
	return not is_stunned


func _on_round_started(_current_round: int) -> void:
	if is_stunned:
		stun_duration -= 1
		if stun_duration <= 0:
			is_stunned = false
			stun_duration = 0
			stun_status_changed.emit(false)


func _on_dazzle_stacks_changed(stacks: int) -> void:
	active_dazzle_stacks = stacks


func _on_aura_changed(_aura: AuraCardData = null) -> void:
	clamp_tokens_to_max()


func get_max_oxygen() -> int:
	return MAX_TOKEN + AuraManager.get_max_token_oxygen_modifier()


func get_max_chn() -> int:
	return MAX_TOKEN + AuraManager.get_max_token_chn_modifier()


func clamp_tokens_to_max() -> void:
	var max_o: int = get_max_oxygen()
	var max_chn: int = get_max_chn()
	
	oxygen = clampi(oxygen, 0, max_o)
	carbon = clampi(carbon, 0, max_chn)
	hydrogen = clampi(hydrogen, 0, max_chn)
	nitrogen = clampi(nitrogen, 0, max_chn)
	
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func get_modified_card_cost(card: CardData) -> Dictionary:
	var base_costs = {
		"carbon": card.get_effective_cost(CardData.CostType.CARBON),
		"hydrogen": card.get_effective_cost(CardData.CostType.HYDROGEN),
		"oxygen": card.get_effective_cost(CardData.CostType.OXYGEN),
		"nitrogen": card.get_effective_cost(CardData.CostType.NITROGEN)
	}
	
	if active_dazzle_stacks > 0:
		var token_keys = ["carbon", "hydrogen", "oxygen", "nitrogen"]
		for i in range(active_dazzle_stacks):
			var random_key = token_keys.pick_random()
			base_costs[random_key] += 1
			
	return base_costs


func can_afford(card: CardData) -> bool:
	if not can_take_action():
		return false
		
	var req_c = card.get_effective_cost(CardData.CostType.CARBON)
	var req_h = card.get_effective_cost(CardData.CostType.HYDROGEN)
	var req_o = card.get_effective_cost(CardData.CostType.OXYGEN)
	var req_n = card.get_effective_cost(CardData.CostType.NITROGEN)
		
	return (carbon >= req_c and hydrogen >= req_h and oxygen >= req_o and nitrogen >= req_n)


func pay_for_card(card: CardData) -> void:
	if not can_take_action():
		return
		
	var costs = get_modified_card_cost(card)
	carbon = clampi(carbon - costs["carbon"], 0, get_max_chn())
	hydrogen = clampi(hydrogen - costs["hydrogen"], 0, get_max_chn())
	oxygen = clampi(oxygen - costs["oxygen"], 0, get_max_oxygen())
	nitrogen = clampi(nitrogen - costs["nitrogen"], 0, get_max_chn())
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func add_tokens(c: int, h: int, o: int, n: int) -> void:
	carbon = clampi(carbon + c, 0, get_max_chn())
	hydrogen = clampi(hydrogen + h, 0, get_max_chn())
	oxygen = clampi(oxygen + o, 0, get_max_oxygen())
	nitrogen = clampi(nitrogen + n, 0, get_max_chn())
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func gain_tokens(amount: int) -> void:
	carbon = clampi(carbon + amount, 0, get_max_chn())
	hydrogen = clampi(hydrogen + amount, 0, get_max_chn())
	oxygen = clampi(oxygen + amount, 0, get_max_oxygen())
	nitrogen = clampi(nitrogen + amount, 0, get_max_chn())
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func gain_shield(amount: int) -> void:
	shield += amount
	stats_updated.emit(current_hp, max_hp, shield, base_damage)


func take_damage(amount: int) -> void:
	var final_incoming_damage = AuraManager.get_modified_incoming_damage(amount)

	var actual_damage = final_incoming_damage - shield
	if actual_damage > 0:
		shield = 0
		current_hp -= actual_damage
	else:
		shield -= final_incoming_damage
		
	current_hp = clampi(current_hp, 0, max_hp)
	GameManager.player_current_hp = current_hp
	stats_updated.emit(current_hp, max_hp, shield, base_damage)
	EventBus.player_took_damage.emit(final_incoming_damage)
	
	if current_hp <= 0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	get_tree().paused = true
	
	var recap_scene = load("res://ui/recap/recap_ui.tscn")
	if recap_scene:
		var recap_instance = recap_scene.instantiate() as RecapUI
		get_tree().root.add_child(recap_instance)
		recap_instance.setup_recap(false)
		var battle_scene = owner
		if battle_scene:
			battle_scene.queue_free()


func heal(amount: int) -> void:
	current_hp = clampi(current_hp + amount, 0, max_hp)
	GameManager.player_current_hp = current_hp
	stats_updated.emit(current_hp, max_hp, shield, base_damage)


func add_random_token(amount: int = 1) -> void:
	var token_types = ["carbon", "hydrogen", "oxygen", "nitrogen"]
	var chosen_token = token_types.pick_random()
	
	match chosen_token:
		"carbon":
			carbon = clampi(carbon + amount, 0, get_max_chn())
		"hydrogen":
			hydrogen = clampi(hydrogen + amount, 0, get_max_chn())
		"oxygen":
			oxygen = clampi(oxygen + amount, 0, get_max_oxygen())
		"nitrogen":
			nitrogen = clampi(nitrogen + amount, 0, get_max_chn())
			
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func _on_siphon_token_requested(token_type: String, amount: int) -> void:
	match token_type:
		"oxygen":
			oxygen = max(0, oxygen - amount)
		"carbon":
			carbon = max(0, carbon - amount)
		"hydrogen":
			hydrogen = max(0, hydrogen - amount)
		"nitrogen":
			nitrogen = max(0, nitrogen - amount)
			
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func clean_all_debuffs() -> void:
	if is_stunned:
		is_stunned = false
		stun_duration = 0
		stun_status_changed.emit(false)

	if active_dazzle_stacks > 0:
		active_dazzle_stacks = 0
		EventBus.dazzle_stacks_changed.emit(0)
