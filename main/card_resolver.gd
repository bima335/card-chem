class_name CardResolver
extends Node

func play_card(card: CardData, player: Player, target_enemy: EnemyBase, stage_manager: Node) -> bool:
	if not player.can_afford(card):
		print("Token tidak cukup untuk memainkan kartu ini!")
		return false

	# 1. Lakukan pembayaran token
	player.pay_for_card(card)
	
	# 2. Tangani Effect Coat: Catalyst (Mengembalikan 1 token acak)
	if card.effect_coat == CardData.EffectCoat.CATALYST:
		_apply_catalyst_coat(player)
		
	# 3. Eksekusi logika berdasarkan Tipe Kartu
	match card.card_type:
		CardData.CardType.BUFF:
			_execute_buff_card(card, player)
			
		CardData.CardType.ATK:
			_execute_attack_card(card, player, target_enemy, stage_manager)
			
		CardData.CardType.DEBUFF:
			_execute_debuff_card(card, target_enemy, stage_manager)
			
		CardData.CardType.TRIGGER:
			_execute_trigger_card(card, target_enemy, stage_manager)

	# 4. Tangani Effect Coat: Purify (Menghapus debuff player & menambah token)
	if card.effect_coat == CardData.EffectCoat.PURIFY:
		player.gain_tokens(1)

	return true

func _execute_buff_card(card: CardData, player: Player) -> void:
	if card.shield_amount > 0:
		player.gain_shield(card.shield_amount)
		
	if card.gain_carbon > 0 or card.gain_hydrogen > 0 or card.gain_oxygen > 0 or card.gain_nitrogen > 0:
		player.add_specific_tokens(card.gain_carbon, card.gain_hydrogen, card.gain_oxygen, card.gain_nitrogen)

func _execute_attack_card(card: CardData, player: Player, target_enemy: EnemyBase, stage_manager: Node) -> void:
	var calculated_damage = card.base_damage + player.base_damage
	
	# Effect Coat: Unstable (2x damage ke musuh, 1/2 self-damage ke player)
	if card.effect_coat == CardData.EffectCoat.UNSTABLE:
		calculated_damage *= 2
		var self_damage = max(1, calculated_damage / 2)
		player.take_damage(self_damage)

	var targets: Array[EnemyBase] = _resolve_targets(card, target_enemy, stage_manager)
	
	for enemy in targets:
		enemy.take_damage(calculated_damage)
		
		# Aplikasikan status/tag bawaan kartu ATK
		if card.inflict_oxidize: enemy.has_oxidize = true
		if card.inflict_corrosion: enemy.has_corrosion = true
		if card.add_toxic_stacks > 0: enemy.add_toxic_stacks(card.add_toxic_stacks, stage_manager)

func _execute_debuff_card(card: CardData, target_enemy: EnemyBase, stage_manager: Node) -> void:
	var targets: Array[EnemyBase] = _resolve_targets(card, target_enemy, stage_manager)
	
	for enemy in targets:
		if card.inflict_oxidize: enemy.has_oxidize = true
		if card.add_toxic_stacks > 0: enemy.add_toxic_stacks(card.add_toxic_stacks, stage_manager)
		if card.reduce_enemy_damage > 0:
			enemy.base_attack_power_modifier -= card.reduce_enemy_damage

func _execute_trigger_card(card: CardData, target_enemy: EnemyBase, stage_manager: Node) -> void:
	var targets: Array[EnemyBase] = _resolve_targets(card, target_enemy, stage_manager)
	
	for enemy in targets:
		if card.inflict_volatile:
			enemy.has_volatile = true
			
		if card.inflict_ignite:
			enemy.trigger_ignite(stage_manager)
			
		if card.inflict_corrosion:
			enemy.has_corrosion = true
			
		# Cek pemicuan Destabilize jika tag Oxidize & Corrosion sudah ada
		enemy.trigger_destabilize(enemy.has_volatile)

func _resolve_targets(card: CardData, target_enemy: EnemyBase, stage_manager: Node) -> Array[EnemyBase]:
	var targets: Array[EnemyBase] = []
	
	if card.target_type == CardData.TargetType.ALL_ENEMIES and stage_manager:
		for child in stage_manager.get_children():
			if child is EnemyBase and not child.is_queued_for_deletion():
				targets.append(child)
	elif target_enemy != null and is_instance_valid(target_enemy):
		targets.append(target_enemy)
		
	return targets

func _apply_catalyst_coat(player: Player) -> void:
	var element_choice = randi() % 4
	match element_choice:
		0: player.add_specific_tokens(1, 0, 0, 0)
		1: player.add_specific_tokens(0, 1, 0, 0)
		2: player.add_specific_tokens(0, 0, 1, 0)
		3: player.add_specific_tokens(0, 0, 0, 1)
