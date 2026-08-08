extends Node

signal player_took_damage(amount: int)
signal enemy_selected(enemy_node: EnemyBase)
signal enemy_died(enemy_node: EnemyBase)
signal round_started
signal round_ended
signal apply_player_status(status_name: String, duration: int, damage_per_turn: int)
signal siphon_token_requested(token_type: String, amount: int)
signal enemy_summon_requested(minion_stat: EnemyStat, amount: int)
