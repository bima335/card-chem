extends Node

signal aura_equipped(aura: AuraCardData)
signal aura_unequipped

var active_aura: AuraCardData = null

var current_round_damage_accumulated: int = 0
var previous_round_damage_accumulated: int = 0


func _ready() -> void:
	if EventBus.has_signal("player_took_damage"):
		if not EventBus.player_took_damage.is_connected(_on_player_took_damage):
			EventBus.player_took_damage.connect(_on_player_took_damage)
			
	if EventBus.has_signal("player_dealt_damage"):
		if not EventBus.player_dealt_damage.is_connected(_on_player_dealt_damage):
			EventBus.player_dealt_damage.connect(_on_player_dealt_damage)


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
