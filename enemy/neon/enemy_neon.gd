class_name EnemyNeon
extends EnemyBase

enum NeonTier { COMMON, ELITE, BOSS, MINION }

var tier: NeonTier = NeonTier.COMMON

@export var minion_stat: EnemyStat

var current_phase: int = 1
var atk_bonus_stack: int = 0
var player_korosi_stacks_applied: int = 0
var minion_counter: int = 0
var is_attacked: bool = false

var absorbed_damage: int = 0
var dazzle_stacks: int = 0
var is_forced_visible: bool = false


func _ready() -> void:
	super._ready()


func _setup_enemy() -> void:
	_sync_tier_from_stats()
	
	if EventBus.has_signal("round_ended"):
		EventBus.round_ended.connect(_on_round_ended)
		
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)
		
	if EventBus.has_signal("enemy_died"):
		EventBus.enemy_died.connect(_on_any_enemy_died)
		
	if EventBus.has_signal("force_reveal_boss_requested"):
		EventBus.force_reveal_boss_requested.connect(_on_force_reveal_requested)


func _sync_tier_from_stats() -> void:
	if stats == null:
		return
		
	match stats.tag:
		EnemyStat.EnemyTag.MINION:
			tier = NeonTier.MINION
		EnemyStat.EnemyTag.SMALL:
			tier = NeonTier.COMMON
		EnemyStat.EnemyTag.BIG:
			tier = NeonTier.ELITE
		EnemyStat.EnemyTag.BOSS:
			tier = NeonTier.BOSS


func _on_round_started(current_round: int) -> void:
	if tier == NeonTier.BOSS:
		_process_boss_round_start(current_round)
		return

	if tier == NeonTier.COMMON and current_round % 2 == 1:
		toggle_targetable(false)
	else:
		toggle_targetable(true)
		
	if tier == NeonTier.ELITE:
		is_attacked = false
		
	if current_round % 2 == 0:
		atk_bonus_stack += 1


func _on_round_ended() -> void:
	pass


func _process_boss_round_start(current_round: int) -> void:
	is_forced_visible = false
	var is_even_round: bool = (current_round % 2 == 0)
	
	if is_even_round:
		set_targetable(true)
		_execute_counter_attack()
		_apply_dazzle_stack()
	else:
		set_targetable(false)


func _execute_counter_attack() -> void:
	if absorbed_damage > 0:
		var counter_damage: int = int(absorbed_damage * 0.3)
		if counter_damage > 0:
			EventBus.player_took_damage.emit(counter_damage)
		absorbed_damage = 0


func _apply_dazzle_stack() -> void:
	dazzle_stacks += 1
	EventBus.dazzle_stacks_changed.emit(dazzle_stacks)
	
	if dazzle_stacks >= 3:
		_trigger_dazzle_burst()


func _trigger_dazzle_burst() -> void:
	var burst_damage: int = 50 
	EventBus.player_took_damage.emit(burst_damage)
	
	EventBus.player_stunned_requested.emit(1)
	dazzle_stacks = 0
	EventBus.dazzle_stacks_changed.emit(dazzle_stacks)


func _on_force_reveal_requested() -> void:
	if tier == NeonTier.BOSS and not is_targetable:
		is_forced_visible = true
		set_targetable(true)
		_apply_dazzle_stack()


func absorb_player_incoming_damage(amount: int) -> void:
	if tier == NeonTier.BOSS and not is_targetable:
		absorbed_damage += amount


func determine_next_move() -> EnemyAction:
	var action = EnemyAction.new()
	action.type = EnemyAction.ActionType.ATTACK
	
	match tier:
		NeonTier.COMMON:
			if is_targetable:
				action.amount = 10
		NeonTier.ELITE:
			action.amount = 13
		NeonTier.BOSS:
			if not is_targetable:
				action.amount = 0
			else:
				action.amount = 20
		NeonTier.MINION:
			action.amount = 5
			
	return action


func take_damage(amount: int, is_direct_attack: bool = false) -> void:
	if tier == NeonTier.BOSS and not is_targetable:
		absorb_player_incoming_damage(amount)
		return
		
	if tier == NeonTier.ELITE and not is_attacked:
		is_attacked = true
		return
		
	super.take_damage(amount, is_direct_attack)


func _on_any_enemy_died(_dead_enemy: EnemyBase) -> void:
	pass
