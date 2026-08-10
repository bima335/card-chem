extends Node

signal player_took_damage(amount: int)
signal enemy_selected(enemy_node: EnemyBase)
signal enemy_died(enemy_node: EnemyBase)
signal round_started(current_round: int)
signal round_ended
signal apply_player_status(status_name: String, duration: int, damage_per_turn: int)
signal siphon_token_requested(token_type: String, amount: int)
signal enemy_summon_requested(minion_stat: EnemyStat, amount: int)
signal dazzle_stacks_changed(current_stacks: int)
signal force_reveal_boss_requested
signal player_stunned_requested(duration: int)
signal card_played(card_data: CardData)
signal card_manually_discarded(card_data: CardData)
signal enemy_status_applied(enemy: EnemyBase, status_type: StatusAilment.AilmentType)
signal poison_explosion_triggered(source_enemy: EnemyBase)
signal burn_damage_dealt(amount: int)
signal blessing_list_changed
