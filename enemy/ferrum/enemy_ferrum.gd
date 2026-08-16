class_name EnemyFerrum
extends EnemyBase

enum FerrumTier { COMMON, ELITE, BOSS }

var tier: FerrumTier = FerrumTier.COMMON

var rust_armor_stacks: int = 0
var max_rust_armor_stacks: int = 4
var rust_armor_durations: Array[int] = []

var current_phase: int = 1
var player_korosi_stacks_applied: int = 0

func _setup_enemy() -> void:
	_sync_tier_from_stats()
	
	if EventBus.has_signal("round_ended"):
		EventBus.round_ended.connect(_on_round_ended)
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)
		
	if tier == FerrumTier.BOSS:
		max_rust_armor_stacks = 4
	elif tier == FerrumTier.ELITE:
		max_rust_armor_stacks = 1

func _sync_tier_from_stats() -> void:
	if stats == null:
		return
		
	match stats.tag:
		EnemyStat.EnemyTag.SMALL:
			tier = FerrumTier.COMMON
		EnemyStat.EnemyTag.BIG:
			tier = FerrumTier.ELITE
		EnemyStat.EnemyTag.BOSS:
			tier = FerrumTier.BOSS

func _on_turn_started() -> void:
	print("round:", GameManager.current_round)
	if tier == FerrumTier.BOSS:
		print("Rust Armor: ", rust_armor_stacks)
	_decay_rust_armor()

	if tier == FerrumTier.BOSS and current_phase == 2:
		_siphon_oxygen(2)

func _on_round_started(current_round: int) -> void:
	print("Round dimulai:", current_round)
	if tier == FerrumTier.BOSS:
		print("Round Start Armor: ", rust_armor_stacks)

func _on_round_ended() -> void:
	print("round ended")
	if tier == FerrumTier.BOSS and current_phase == 1:
		_siphon_oxygen(1)

	var player_o_tokens = _get_player_oxygen_count()
	if player_o_tokens == 0:
		if tier == FerrumTier.BOSS or tier == FerrumTier.ELITE:
			add_rust_armor(1)

func _siphon_oxygen(amount: int) -> void:
	EventBus.siphon_token_requested.emit("oxygen", amount)
	print("Siphon: ", amount)

func _get_player_oxygen_count() -> int:
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and "oxygen" in player_node:
		return player_node.oxygen
	return 0

func add_rust_armor(amount: int) -> void:
	if rust_armor_stacks >= max_rust_armor_stacks:
		return
		
	var added = min(amount, max_rust_armor_stacks - rust_armor_stacks)
	rust_armor_stacks += added
	for i in range(added):
		rust_armor_durations.append(2)

func _decay_rust_armor() -> void:
	var to_remove: Array[int] = []
	for i in range(rust_armor_durations.size()):
		rust_armor_durations[i] -= 1
		if rust_armor_durations[i] <= 0:
			to_remove.append(i)
			
	to_remove.reverse()
	for idx in to_remove:
		rust_armor_durations.remove_at(idx)
		rust_armor_stacks = max(0, rust_armor_stacks - 1)

func _calculate_custom_damage_reduction() -> float:
	if tier == FerrumTier.BOSS or tier == FerrumTier.ELITE:
		var reduction = rust_armor_stacks * 0.20
		print(reduction)
		return min(reduction, 1.0)
	return 0.0

func determine_next_move() -> EnemyAction:
	var action = EnemyAction.new()
	action.type = EnemyAction.ActionType.ATTACK
	
	match tier:
		FerrumTier.COMMON:
			action.amount = 8
		FerrumTier.ELITE:
			if randf() < .7:
				action.amount = 11
				if current_hp <= 50:
					action.amount += 1
			else:
				_siphon_oxygen(1)
		FerrumTier.BOSS:
			var base_atk = 12
			var bonus = 4 if current_phase == 2 else 3
			action.amount = base_atk + (rust_armor_stacks * bonus)
			print ("Damage", action.amount)
	return action

func execute_move(action: EnemyAction) -> void:
	await super.execute_move(action)
	if action and action.type == EnemyAction.ActionType.ATTACK:
		player_korosi_stacks_applied += 1
		EventBus.apply_player_status.emit("KOROSI", 3, 3)

func _on_health_changed(new_hp: int) -> void:
	if tier == FerrumTier.BOSS and current_phase == 1 and new_hp <= 90:
		_enter_phase_two()

func _enter_phase_two() -> void:
	current_phase = 2
	max_rust_armor_stacks = 6

func die() -> void:
	if tier == FerrumTier.COMMON and player_korosi_stacks_applied >= 3:
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and player_node.has_method("add_tokens"):
			player_node.add_tokens(1, 0, 0, 0)
			
	await super.die()
