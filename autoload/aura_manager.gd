extends Node

signal aura_equipped(aura: AuraCardData)
signal aura_unequipped

var active_aura: AuraCardData = null

var iron_rage_bonus_damage: int = 0
var iron_rage_hp_lost_accumulator: int = 0

var last_damage_taken_from_enemy: int = 0


func _ready() -> void:
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.card_played.connect(_on_card_played)
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)


func equip_aura(new_aura: AuraCardData) -> void:
	if active_aura != null:
		unequip_aura()
		
	active_aura = new_aura
	aura_equipped.emit(active_aura)
	_apply_static_modifiers()


func unequip_aura() -> void:
	if active_aura == null:
		return
		
	_remove_static_modifiers()
	active_aura = null
	reset_battle_state()
	aura_unequipped.emit()


func reset_battle_state() -> void:
	iron_rage_bonus_damage = 0
	iron_rage_hp_lost_accumulator = 0
	last_damage_taken_from_enemy = 0

func _apply_static_modifiers() -> void:
	if active_aura == null:
		return
		
	match active_aura.aura_id:
		AuraCardData.AuraID.CORRODED_LIMITS:
			pass


func _remove_static_modifiers() -> void:
	if active_aura == null:
		return


func _on_round_started(_current_round: int) -> void:
	reset_battle_state()


func _on_player_took_damage(amount: int) -> void:
	if active_aura == null:
		return
		
	match active_aura.aura_id:
		AuraCardData.AuraID.IRON_RAGE:
			iron_rage_hp_lost_accumulator += amount
			var stacks = iron_rage_hp_lost_accumulator / 10
			iron_rage_bonus_damage = stacks * 5
			
		AuraCardData.AuraID.RUSTED_RESILIENCE:
			last_damage_taken_from_enemy = amount


func _on_card_played(card: CardData) -> void:
	if active_aura == null:
		return
		
	if active_aura.aura_id == AuraCardData.AuraID.RUSTED_RESILIENCE:
		if card.card_type == CardData.CardType.ATK and last_damage_taken_from_enemy > 0:
			var heal_amount: int = int(last_damage_taken_from_enemy * 0.05)
			if heal_amount > 0:
				var player = get_tree().get_first_node_in_group("player") as Player
				if player:
					player.heal(heal_amount)


func get_modified_incoming_damage(base_damage: int) -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.RUSTED_RESILIENCE:
		var reduced = float(base_damage) * 0.7
		return int(floor(reduced))
	return base_damage


func get_total_attack_bonus() -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.IRON_RAGE:
		return iron_rage_bonus_damage
	return 0


func get_max_token_oxygen_modifier() -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.CORRODED_LIMITS:
		return -1
	return 0


func get_max_token_chn_modifier() -> int:
	if active_aura != null and active_aura.aura_id == AuraCardData.AuraID.CORRODED_LIMITS:
		return 1
	return 0
