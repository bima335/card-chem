class_name CardResolver
extends Node

func execute_card_logic(card_data: CardData, player: Player, current_target: EnemyBase, stage_manager: StageManager, active_reactions: Array[AilmentReaction]) -> bool:
	match card_data.tipe:
		CardData.tipe_kartu.SHIELD:
			player.gain_shield(card_data.effect_amount)
			return true
			
		CardData.tipe_kartu.ATTACK:
			var targets: Array[EnemyBase] = []
			
			if card_data.is_multi_target:
				for child in stage_manager.get_children():
					if child is EnemyBase and not child.is_queued_for_deletion():
						targets.append(child)
			else:
				if current_target == null or not is_instance_valid(current_target):
					return false
				targets.append(current_target)
			
			_process_attack_targets(targets, card_data, player, stage_manager, active_reactions)
			return true
			
	return false

func _process_attack_targets(targets: Array[EnemyBase], card_data: CardData, player: Player, stage_manager: StageManager, active_reactions: Array[AilmentReaction]) -> void:
	for target in targets:
		var final_damage = player.base_damage + card_data.effect_amount
		var reaction_occurred: bool = false
		var incoming_el = card_data.attack_ailment
		
		if incoming_el != StatusAilment.ailment_type.None:
			for reaction_rule in active_reactions:
				if incoming_el == reaction_rule.incoming_element and target.has_status(reaction_rule.existing_element):
					final_damage = reaction_rule.execute(target, stage_manager, final_damage)
					reaction_occurred = true
					break
		
		target.take_damage(final_damage)
		
		if not reaction_occurred and card_data.status_to_apply != null:
			target.apply_status(card_data.status_to_apply, card_data.status_to_apply.duration)
