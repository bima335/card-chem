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
	if not EventBus.player_took_damage.is_connected(take_damage):
		EventBus.player_took_damage.connect(take_damage)
		
	if EventBus.has_signal("siphon_token_requested"):
		EventBus.siphon_token_requested.connect(_on_siphon_token_requested)
		
	if EventBus.has_signal("player_stunned_requested"):
		EventBus.player_stunned_requested.connect(apply_stun)
		
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)
		
	if EventBus.has_signal("dazzle_stacks_changed"):
		EventBus.dazzle_stacks_changed.connect(_on_dazzle_stacks_changed)


func reset_for_battle() -> void:
	shield = 0
	carbon = 3
	hydrogen = 3
	oxygen = 3
	nitrogen = 3
	is_stunned = false
	stun_duration = 0
	active_dazzle_stacks = 0
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
	stats_updated.emit(current_hp, max_hp, shield, base_damage)


func apply_stun(duration: int) -> void:
	is_stunned = true
	stun_duration = max(1, duration)
	stun_status_changed.emit(true)
	print("Player terkena STUN selama ", stun_duration, " ronde!")


func can_take_action() -> bool:
	return not is_stunned


func _on_round_started(_current_round: int) -> void:
	print("duzzle: ", active_dazzle_stacks)
	if is_stunned:
		stun_duration -= 1
		if stun_duration <= 0:
			is_stunned = false
			stun_duration = 0
			stun_status_changed.emit(false)
			print("Player bebas dari efek STUN!")


func _on_dazzle_stacks_changed(stacks: int) -> void:
	active_dazzle_stacks = stacks


func get_modified_card_cost(card: CardData) -> Dictionary:
	var base_costs = {
		"carbon": card.cost_carbon,
		"hydrogen": card.cost_hydrogen,
		"oxygen": card.cost_oxygen,
		"nitrogen": card.cost_nitrogen
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
		
	var costs = get_modified_card_cost(card)
	return (oxygen >= costs["oxygen"] and 
			hydrogen >= costs["hydrogen"] and 
			carbon >= costs["carbon"] and 
			nitrogen >= costs["nitrogen"])


func pay_for_card(card: CardData) -> void:
	if not can_take_action():
		return
		
	var costs = get_modified_card_cost(card)
	carbon = clampi(carbon - costs["carbon"], 0, MAX_TOKEN)
	hydrogen = clampi(hydrogen - costs["hydrogen"], 0, MAX_TOKEN)
	oxygen = clampi(oxygen - costs["oxygen"], 0, MAX_TOKEN)
	nitrogen = clampi(nitrogen - costs["nitrogen"], 0, MAX_TOKEN)
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func add_tokens(c: int, h: int, o: int, n: int) -> void:
	carbon = clampi(carbon + c, 0, MAX_TOKEN)
	hydrogen = clampi(hydrogen + h, 0, MAX_TOKEN)
	oxygen = clampi(oxygen + o, 0, MAX_TOKEN)
	nitrogen = clampi(nitrogen + n, 0, MAX_TOKEN)
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)


func gain_tokens(amount: int) -> void:
	carbon = clampi(carbon + amount, 0, MAX_TOKEN)
	hydrogen = clampi(hydrogen + amount, 0, MAX_TOKEN)
	oxygen = clampi(oxygen + amount, 0, MAX_TOKEN)
	nitrogen = clampi(nitrogen + amount, 0, MAX_TOKEN)
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)

func get_max_oxygen() -> int:
	return MAX_TOKEN + AuraManager.get_max_token_oxygen_modifier()

func get_max_chn() -> int:
	return MAX_TOKEN + AuraManager.get_max_token_chn_modifier()

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
	
	if current_hp <= 0:
		print("HP Habis! GAME OVER!")
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
			carbon = clampi(carbon + amount, 0, MAX_TOKEN)
		"hydrogen":
			hydrogen = clampi(hydrogen + amount, 0, MAX_TOKEN)
		"oxygen":
			oxygen = clampi(oxygen + amount, 0, MAX_TOKEN)
		"nitrogen":
			nitrogen = clampi(nitrogen + amount, 0, MAX_TOKEN)
			
	coins_updated.emit(oxygen, hydrogen, carbon, nitrogen)
	print("Player mendapatkan +", amount, " token acak: ", chosen_token)

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
