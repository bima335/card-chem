class_name CardResolver
extends Node

@export var burn_ailment: StatusAilment


func execute_card_logic(card_data: CardData, player: Player, current_target: EnemyBase, stage_manager: Node) -> bool:
	if not player.can_afford(card_data):
		print("Token tidak cukup!")
		return false
		
	if not _is_target_valid(card_data, current_target, stage_manager):
		print("Target tidak valid atau belum dipilih!")
		return false

	player.pay_for_card(card_data)
	EventBus.card_played.emit(card_data)
	
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
	
	var base_dmg: int = player.base_damage + card_data.damage_amount
	
	if card_data.coat_data:
		base_dmg = card_data.coat_data.apply_damage_modifier(base_dmg)
		var self_dmg = card_data.coat_data.calculate_self_damage(base_dmg)
		if self_dmg > 0:
			player.take_damage(self_dmg)
		
	for enemy in targets:
		enemy.take_damage(base_dmg)
		_apply_card_statuses(card_data, enemy)


func _process_debuff_card(card_data: CardData, target: EnemyBase, stage_manager: Node) -> void:
	var targets = _get_targets(card_data, target, stage_manager)
	for enemy in targets:
		_apply_card_statuses(card_data, enemy)


func _process_trigger_card(card_data: CardData, _player: Player, target: EnemyBase, stage_manager: Node) -> void:
	var targets = _get_targets(card_data, target, stage_manager)
	for enemy in targets:
		match card_data.trigger_element:
			StatusAilment.AilmentType.IGNITE:
				if enemy.has_status(StatusAilment.AilmentType.OXIDIZE):
					if burn_ailment:
						enemy.apply_status(burn_ailment, burn_ailment.duration)
					enemy.remove_status(StatusAilment.AilmentType.OXIDIZE)
					
			StatusAilment.AilmentType.OXIDIZE:
				if enemy.has_status(StatusAilment.AilmentType.CORROSION):
					var dest_status = StatusAilment.new()
					dest_status.ailment = StatusAilment.AilmentType.DESTABILIZE
					enemy.apply_status(dest_status, 2)
					enemy.remove_status(StatusAilment.AilmentType.CORROSION)
					
			StatusAilment.AilmentType.VOLATILE:
				if not enemy.has_status(StatusAilment.AilmentType.BURN) and not enemy.has_status(StatusAilment.AilmentType.POISON) and not enemy.has_status(StatusAilment.AilmentType.DESTABILIZE):
					continue
				var vol_status = StatusAilment.new()
				vol_status.ailment = StatusAilment.AilmentType.VOLATILE
				enemy.apply_status(vol_status, 1)
				
				if enemy.has_status(StatusAilment.AilmentType.BURN):
					var splash_dmg = (enemy.burn_stacks * 70) / 3
					if stage_manager.has_method("get_adjacent_enemies"):
						var adjacent = stage_manager.get_adjacent_enemies(enemy)
						if adjacent.get("left") != null:
							adjacent["left"].take_damage(splash_dmg)
						if adjacent.get("right") != null:
							adjacent["right"].take_damage(splash_dmg)
					enemy.take_damage(enemy.burn_stacks * 70)
					enemy.burn_stacks = 0
					
		_apply_card_statuses(card_data, enemy)


func _apply_card_statuses(card_data: CardData, enemy: EnemyBase) -> void:
	for status_res in card_data.statuses_to_apply:
		if status_res.ailment == StatusAilment.AilmentType.TOXIC:
			enemy.add_toxic_stack(1)
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
