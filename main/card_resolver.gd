class_name CardResolver
extends Node

@export var burn_ailment: StatusAilment
@export var poison_ailment: StatusAilment
@export var toxic_ailment: StatusAilment
@export var stun_ailment: StatusAilment
@export var destabilize_ailment: StatusAilment
@export var disintegrate_ailment: StatusAilment


func execute_card_logic(card_data: CardData, player: Player, current_target: EnemyBase, stage_manager: Node) -> bool:
	if not player.can_afford(card_data):
		print("Token tidak cukup!")
		return false
		
	if not _is_target_valid(card_data, current_target, stage_manager):
		print("Target tidak valid atau belum dipilih!")
		return false

	player.pay_for_card(card_data)
	EventBus.card_played.emit(card_data)
	
	_process_coat_effects(card_data, player)
	
	match card_data.card_type:
		CardData.CardType.BUFF:
			_process_buff_card(card_data, player)
			return true
			
		CardData.CardType.ATK:
			_process_attack_card(card_data, player, current_target, stage_manager)
			return true
			
		CardData.CardType.DEBUFF:
			_process_debuff_card(card_data, current_target, stage_manager)
			return true
			
		CardData.CardType.TRIGGER:
			_process_trigger_card(card_data, player, current_target, stage_manager)
			return true
			
	return false


func _process_coat_effects(card_data: CardData, player: Player) -> void:
	if card_data.coat_data == null:
		return
		
	if card_data.coat_data.coat_type == CoatData.EffectCoatType.PURIFY:
		player.clean_all_debuffs()


func _is_target_valid(card_data: CardData, current_target: EnemyBase, stage_manager: Node) -> bool:
	if card_data.target_type == CardData.TargetType.SELF:
		return true

	if card_data.target_type == CardData.TargetType.SINGLE:
		return current_target != null and is_instance_valid(current_target) and not current_target.is_queued_for_deletion()

	if card_data.target_type == CardData.TargetType.ALL_ENEMIES:
		return _has_living_enemies(stage_manager)

	return false


func _has_living_enemies(stage_manager: Node) -> bool:
	for child in stage_manager.get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			return true
	return false


func _process_buff_card(card_data: CardData, player: Player) -> void:
	player.add_tokens(card_data.gain_carbon, card_data.gain_hydrogen, card_data.gain_oxygen, card_data.gain_nitrogen)
	if card_data.shield_amount > 0:
		player.gain_shield(card_data.shield_amount)


func _process_attack_card(card_data: CardData, player: Player, target: EnemyBase, stage_manager: Node) -> void:
	var targets = _get_targets(card_data, target, stage_manager)
	
	if card_data.shield_amount > 0:
		player.gain_shield(card_data.shield_amount)
	
	# Ambil bonus damage dari Aura (Iron Rage)
	var aura_bonus_dmg: int = AuraManager.get_total_attack_bonus(player)
	
	# Masukkan aura_bonus_dmg ke kalkulasi awal damage serangan
	var initial_dmg: int = player.base_damage + card_data.damage_amount + aura_bonus_dmg
	var final_dmg: int = initial_dmg
	
	if card_data.coat_data:
		var self_dmg = card_data.coat_data.calculate_self_damage(initial_dmg)
		if self_dmg > 0:
			player.take_damage(self_dmg)
			
		final_dmg = card_data.coat_data.apply_damage_modifier(initial_dmg)
		
	for enemy in targets:
		enemy.take_damage(final_dmg, true)
		EventBus.player_dealt_damage.emit(final_dmg, enemy)
		_apply_card_statuses(card_data, enemy)


func _process_debuff_card(card_data: CardData, target: EnemyBase, stage_manager: Node) -> void:
	var targets = _get_targets(card_data, target, stage_manager)
	for enemy in targets:
		_apply_card_statuses(card_data, enemy)


func _process_trigger_card(card_data: CardData, _player: Player, target: EnemyBase, stage_manager: Node) -> void:
	var targets = _get_targets(card_data, target, stage_manager)
	for enemy in targets:
		match card_data.trigger_element:
			StatusAilment.AilmentType.TOXIC:
				enemy.add_toxic_stack(card_data.toxic_stacks_to_apply, poison_ailment, stun_ailment, toxic_ailment)
				
			StatusAilment.AilmentType.IGNITE:
				if enemy.has_status(StatusAilment.AilmentType.OXIDIZE):
					if burn_ailment:
						enemy.apply_status(burn_ailment, burn_ailment.duration)
					enemy.remove_status(StatusAilment.AilmentType.OXIDIZE)
					
			StatusAilment.AilmentType.CORROSION:
				if enemy.has_status(StatusAilment.AilmentType.OXIDIZE):
					enemy.remove_status(StatusAilment.AilmentType.OXIDIZE)
					
					if destabilize_ailment:
						enemy.apply_status(destabilize_ailment, 1)
					else:
						var dest_status = StatusAilment.new()
						dest_status.ailment = StatusAilment.AilmentType.DESTABILIZE
						enemy.apply_status(dest_status, 1)
					
			StatusAilment.AilmentType.VOLATILE:
				if enemy.has_status(StatusAilment.AilmentType.DESTABILIZE):
					_convert_destabilize_to_disintegrate(enemy)

				if not enemy.has_status(StatusAilment.AilmentType.BURN) and not enemy.has_status(StatusAilment.AilmentType.POISON) and not enemy.has_status(StatusAilment.AilmentType.DESTABILIZE) and not enemy.has_status(StatusAilment.AilmentType.DISINTEGRATE):
					continue

				var has_poison_stack: bool = enemy.has_status(StatusAilment.AilmentType.POISON)
				var has_burn_stack: bool = enemy.has_status(StatusAilment.AilmentType.BURN)

				# Kondisi 4 & 5: Trigger Volatile pada musuh yang punya Burn atau Poison
				if has_burn_stack or has_poison_stack:
					BlessingManager.trigger_resonance_heal()
				
				if has_burn_stack:
					var splash_dmg = (enemy.burn_stacks * 70) / 3
					if stage_manager.has_method("get_adjacent_enemies"):
						var adjacent = stage_manager.get_adjacent_enemies(enemy)
						if adjacent.get("left") != null:
							adjacent["left"].take_damage(splash_dmg)
						if adjacent.get("right") != null:
							adjacent["right"].take_damage(splash_dmg)
					enemy.take_damage(enemy.burn_stacks * 70)
					enemy.burn_stacks = 0

				if has_poison_stack:
					_apply_aoe_poison_and_stun(stage_manager, 1, 1)
					
		_apply_card_statuses(card_data, enemy)


func _convert_destabilize_to_disintegrate(enemy: EnemyBase) -> void:
	var current_stacks: int = enemy.get_status_duration(StatusAilment.AilmentType.DESTABILIZE)
	if current_stacks <= 0:
		return
		
	enemy.remove_status(StatusAilment.AilmentType.DESTABILIZE)
	
	if disintegrate_ailment:
		enemy.apply_status(disintegrate_ailment, current_stacks)
	else:
		var dis_status = StatusAilment.new()
		dis_status.ailment = StatusAilment.AilmentType.DISINTEGRATE
		enemy.apply_status(dis_status, current_stacks)

	# Kondisi 6: Berhasil menyebabkan Disintegrate
	BlessingManager.trigger_resonance_heal()


func _apply_poison_and_stun(enemy: EnemyBase, poison_amount: int, stun_amount: int) -> void:
	if poison_ailment:
		enemy.apply_status(poison_ailment, poison_amount)
	else:
		var p_status = StatusAilment.new()
		p_status.ailment = StatusAilment.AilmentType.POISON
		enemy.apply_status(p_status, poison_amount)

	if stun_ailment:
		enemy.apply_status(stun_ailment, stun_amount)
	else:
		var s_status = StatusAilment.new()
		s_status.ailment = StatusAilment.AilmentType.STUN
		enemy.apply_status(s_status, stun_amount)


func _apply_aoe_poison_and_stun(stage_manager: Node, poison_amount: int, stun_amount: int) -> void:
	var all_enemies: Array[EnemyBase] = []
	if stage_manager.has_method("get_sorted_active_enemies"):
		all_enemies = stage_manager.get_sorted_active_enemies()
	else:
		for child in stage_manager.get_children():
			if child is EnemyBase and not child.is_queued_for_deletion():
				all_enemies.append(child)

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			_apply_poison_and_stun(enemy, poison_amount, stun_amount)


func _apply_card_statuses(card_data: CardData, enemy: EnemyBase) -> void:
	for status_res in card_data.statuses_to_apply:
		if status_res.ailment == StatusAilment.AilmentType.TOXIC:
			enemy.add_toxic_stack(card_data.toxic_stacks_to_apply, poison_ailment, stun_ailment, status_res)
		else:
			enemy.apply_status(status_res, status_res.duration)


func _get_targets(card_data: CardData, current_target: EnemyBase, stage_manager: Node) -> Array[EnemyBase]:
	var targets: Array[EnemyBase] = []
	if card_data.target_type == CardData.TargetType.ALL_ENEMIES:
		for child in stage_manager.get_children():
			if child is EnemyBase and not child.is_queued_for_deletion():
				targets.append(child)
	elif card_data.target_type == CardData.TargetType.SINGLE:
		if current_target != null and is_instance_valid(current_target) and not current_target.is_queued_for_deletion():
			targets.append(current_target)
	return targets
