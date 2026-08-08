class_name EnemyCobalt
extends EnemyBase

enum CobaltTier { COMMON, ELITE, BOSS, MINION }

var tier: CobaltTier = CobaltTier.COMMON

@export var minion_stat: EnemyStat

var current_phase: int = 1
var round_counter: int = 1
var atk_bonus_stack: int = 0
var player_korosi_stacks_applied: int = 0
var minion_counter: int = 0

func _ready() -> void:
	super._ready()
	if tier == CobaltTier.ELITE and round_counter == 1:
		summon_minions(2)

func _setup_enemy() -> void:
	_sync_tier_from_stats()
	
	if EventBus.has_signal("round_ended"):
		EventBus.round_ended.connect(_on_round_ended)
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)
	if EventBus.has_signal("enemy_died"):
		EventBus.enemy_died.connect(_on_any_enemy_died)
		
	#if tier == FerrumTier.BOSS:
		#max_rust_armor_stacks = 4
	#elif tier == FerrumTier.ELITE:
		#max_rust_armor_stacks = 1

func _sync_tier_from_stats() -> void:
	if stats == null:
		return
		
	match stats.tag:
		EnemyStat.EnemyTag.MINION:
			tier = CobaltTier.MINION
		EnemyStat.EnemyTag.SMALL:
			tier = CobaltTier.COMMON
		EnemyStat.EnemyTag.BIG:
			tier = CobaltTier.ELITE
		EnemyStat.EnemyTag.BOSS:
			tier = CobaltTier.BOSS

func _on_turn_started() -> void:
	print("round:", round_counter)
	round_counter += 1


func _on_round_started():
	print("Round dimulai")
	if CobaltTier.ELITE:
		print("Elit datang")
	if CobaltTier.MINION:
		print("Minion datang")
	print("Minion: ", minion_counter)
	
#buff common
	if round_counter % 2 == 0:
		atk_bonus_stack += 1
#summon (elite)
	
		

func _on_round_ended() -> void:
	print("round ended")

func determine_next_move() -> EnemyAction:
	var action = EnemyAction.new()
	action.type = EnemyAction.ActionType.ATTACK
	
	match tier:
		CobaltTier.COMMON:
			action.amount = 5 + (2 * atk_bonus_stack)
		CobaltTier.ELITE:
			action.amount = 8
		CobaltTier.BOSS:
			if round_counter % 3 == 0 and CobaltTier.BOSS and minion_counter > 0:
				action.amount = 3 * minion_counter
			else:
				action.amount = 0
		CobaltTier.MINION:
			action.amount = 0
	return action

func execute_move(action: EnemyAction) -> void:
	super.execute_move(action)
	if action and action.type == EnemyAction.ActionType.ATTACK:
		player_korosi_stacks_applied += 1
		EventBus.apply_player_status.emit("KOROSI", 3, 3)

func _on_any_enemy_died(dead_enemy: EnemyBase) -> void:
	if CobaltTier.MINION:
		minion_counter -=1

func _enter_phase_two() -> void:
	current_phase = 2

func _calculate_custom_damage_reduction() -> float:
	if minion_counter > 0 and CobaltTier.ELITE:
		return 1
	if minion_counter > 0 and CobaltTier.BOSS:
		return 1
	return 0.0

func summon_minions(amount: int = 1) -> void:
	if minion_stat == null:
		push_warning("EnemyCobalt: minion_stat belum diatur di Inspector!")
		return
		
	EventBus.enemy_summon_requested.emit(minion_stat, amount)
	minion_counter += amount
