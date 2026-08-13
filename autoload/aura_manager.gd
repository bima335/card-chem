extends Node

signal aura_equipped(aura: AuraCardData)
signal aura_unequipped

var active_aura: AuraCardData = null

var current_round_damage_accumulated: int = 0
var previous_round_damage_accumulated: int = 0
var has_played_first_card_this_round: bool = false
var is_ferromagnetic_shield_used: bool = false
var phase_armor_shield_stacks: int = 0
var cards_played_this_round: int = 0

func _ready() -> void:
	if EventBus.has_signal("player_took_damage"):
		if not EventBus.player_took_damage.is_connected(_on_player_took_damage):
			EventBus.player_took_damage.connect(_on_player_took_damage)
			
	if EventBus.has_signal("player_dealt_damage"):
		if not EventBus.player_dealt_damage.is_connected(_on_player_dealt_damage):
			EventBus.player_dealt_damage.connect(_on_player_dealt_damage)

	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)


func _on_round_started(_current_round: int) -> void:
	has_played_first_card_this_round = false
	cards_played_this_round = 0
	_process_phase_armor_round_start(_current_round)

func is_magnetic_pull_active() -> bool:
	return active_aura != null and active_aura.aura_id == AuraCardData.AuraID.MAGNETIC_PULL


func should_trigger_magnetic_pull(is_retrigger_pass: bool) -> bool:
	if not is_retrigger_pass and is_magnetic_pull_active() and not has_played_first_card_this_round:
		has_played_first_card_this_round = true
		return true
	return false


func equip_aura(new_aura: AuraCardData) -> void:
	if active_aura != null:
		unequip_aura()
		
	active_aura = new_aura
	aura_equipped.emit(active_aura)


func unequip_aura() -> void:
	if active_aura == null:
		return
		
	active_aura = null
	reset_battle_state()
	aura_unequipped.emit()


func reset_battle_state() -> void:
	current_round_damage_accumulated = 0
	previous_round_damage_accumulated = 0
	has_played_first_card_this_round = false
	is_ferromagnetic_shield_used = false
	phase_armor_shield_stacks = 0
	cards_played_this_round = 0


func prepare_next_round_accumulator() -> void:
	previous_round_damage_accumulated = current_round_damage_accumulated
	current_round_damage_accumulated = 0


func get_modified_incoming_damage(base_damage: int) -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.RUSTED_RESILIENCE:
		var reduced: float = float(base_damage) * 0.7
		return int(floor(reduced))
	return base_damage


func _on_player_took_damage(amount: int) -> void:
	if active_aura == null:
		return
		
	if active_aura.aura_id == AuraCardData.AuraID.RUSTED_RESILIENCE:
		current_round_damage_accumulated += amount


func _on_player_dealt_damage(_amount: int, _target_enemy: EnemyBase) -> void:
	if active_aura == null:
		return
		
	if active_aura.aura_id == AuraCardData.AuraID.RUSTED_RESILIENCE:
		if previous_round_damage_accumulated > 0:
			var heal_amount: int = int(floor(float(previous_round_damage_accumulated) * 0.05))
			
			if heal_amount < 1 and previous_round_damage_accumulated > 0:
				heal_amount = 1
				
			if heal_amount > 0:
				_apply_heal_to_player(heal_amount)


func _apply_heal_to_player(amount: int) -> void:
	var player_node: Player = get_tree().get_first_node_in_group("player") as Player
	
	if player_node == null:
		var battle_manager = get_tree().current_scene
		if battle_manager and "player" in battle_manager:
			player_node = battle_manager.player as Player

	if player_node != null:
		player_node.heal(amount)
	else:
		push_error("AuraManager: Node Player tidak ditemukan! Pastikan Node Player dimasukkan ke group 'player'.")

func is_crystal_resonance_active() -> bool:
	return active_aura != null and active_aura.aura_id == AuraCardData.AuraID.CRYSTAL_RESONANCE


func get_modified_outgoing_attack_damage(base_damage: int) -> int:
	if is_crystal_resonance_active():
		var reduced_damage: float = float(base_damage) * 0.7
		return int(floor(reduced_damage))
	return base_damage

func get_total_attack_bonus(player: Player) -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.IRON_RAGE:
		if player != null:
			var hp_lost: int = max(0, player.max_hp - player.current_hp)
			var stacks: int = hp_lost / 10
			return stacks * 5
	return 0


func get_max_token_oxygen_modifier() -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.CORRODED_LIMITS:
		return -1
	return 0


func get_max_token_chn_modifier() -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.CORRODED_LIMITS:
		return 1
	return 0

func is_ferromagnetic_shield_active() -> bool:
	return active_aura != null and active_aura.aura_id == AuraCardData.AuraID.FERROMAGNETIC_SHIELD and not is_ferromagnetic_shield_used


func process_incoming_player_damage(current_hp: int, current_shield_val: int, incoming_damage: int, attacker: EnemyBase) -> Dictionary:
	var final_incoming_damage: int = get_modified_incoming_damage(incoming_damage)
	var effective_damage: int = final_incoming_damage - current_shield_val
	
	if effective_damage >= current_hp and is_ferromagnetic_shield_active():
		is_ferromagnetic_shield_used = true
		
		var new_hp: int = 1
		var new_shield: int = 0
		
		if attacker != null and is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
			attacker.take_damage(incoming_damage, false)
			EventBus.player_dealt_damage.emit(incoming_damage, attacker)
			
		EventBus.ferromagnetic_shield_triggered.emit(incoming_damage, attacker)
		
		return {
			"prevented": true,
			"new_hp": new_hp,
			"new_shield": new_shield,
			"damage_taken": current_hp - 1
		}
		
	return {
		"prevented": false,
		"final_damage": final_incoming_damage
	}

func _process_phase_armor_round_start(current_round: int) -> void:
	if active_aura == null or active_aura.aura_id != AuraCardData.AuraID.PHASE_ARMOR:
		return
		
	# Cek apakah ronde genap
	if current_round % 2 == 0:
		if phase_armor_shield_stacks < 5:
			phase_armor_shield_stacks += 1
			_apply_shield_to_player(1)


func _apply_shield_to_player(amount: int) -> void:
	var player_node: Player = get_tree().get_first_node_in_group("player") as Player
	if player_node == null:
		var battle_manager = get_tree().current_scene
		if battle_manager and "player" in battle_manager:
			player_node = battle_manager.player as Player

	if player_node != null:
		player_node.gain_shield(amount)
	else:
		push_error("AuraManager: Node Player tidak ditemukan untuk menambahkan Shield Phase Armor!")

func get_phase_armor_attack_bonus(current_round: int) -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.PHASE_ARMOR:
		if current_round % 2 != 0:
			return 3
	return 0

func is_plasma_amplifier_active() -> bool:
	return active_aura != null and active_aura.aura_id == AuraCardData.AuraID.PLASMA_AMPLIFIER

func register_card_played(player: Player) -> void:
	cards_played_this_round += 1
	
	if is_plasma_amplifier_active():
		_process_plasma_amplifier_odd_trigger(player)

func _process_plasma_amplifier_odd_trigger(player: Player) -> void:
	if cards_played_this_round > 1 and cards_played_this_round % 2 != 0:
		if player != null:
			player.add_random_token(1)

func get_plasma_amplifier_damage_modifier(base_damage: int) -> int:
	if is_plasma_amplifier_active():
		if cards_played_this_round > 0 and cards_played_this_round % 2 == 0:
			return int(floor(float(base_damage) * 1.5))
	return base_damage

func is_neon_illuminate_active() -> bool:
	return active_aura != null and active_aura.aura_id == AuraCardData.AuraID.NEON_ILLUMINATE

func process_neon_illuminate_post_damage(enemy: EnemyBase) -> void:
	if is_neon_illuminate_active() and is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
		enemy.add_exposed_stack(1)
