class_name EnemyGold
extends EnemyBase

var greed_stacks: int = 0
@export var greed_resource: StatusAilment
var is_enraged: bool = _is_in_enrage_phase()

func _ready() -> void:
	super._ready()
	GameManager.is_gold_boss = true
	if EventBus.player_dealt_damage.is_connected(_on_player_dealt_damage):
		return
	EventBus.player_dealt_damage.connect(_on_player_dealt_damage)

func determine_next_move() -> EnemyAction:
	var action = EnemyAction.new()
	action.type = EnemyAction.ActionType.ATTACK
	if GameManager.current_round %2 == 0:
		action.amount = 13
	else:
		_execute_hoard()
	return action


#func execute_move(action: EnemyAction) -> void:
	#if is_stunned:
		#end_turn_process()
		#return
#
	#var is_enraged: bool = _is_in_enrage_phase()
	#var is_odd_round: bool = (GameManager.current_round % 2 != 0)
#
	#if not is_enraged and is_odd_round:
		#_execute_hoard()
	#else:
		#_execute_payout_strike()
#
	#end_turn_process()

func take_damage(amount: int, is_direct_attack: bool = false) -> void:
	super.take_damage(amount, is_direct_attack)
	_is_in_enrage_phase()
	print(_is_in_enrage_phase())

func die() -> void:
	_apply_victory_reward()
	super.die()

func _execute_hoard() -> void:
	var current_coins: int = GameManager.shop_coins
	var steal_amount: int = min(7, current_coins)
	var remaining_steal: int = 7 - steal_amount

	if steal_amount > 0:
		GameManager.shop_coins -= steal_amount
		EventBus.gold_changed.emit(GameManager.shop_coins)

	if current_coins < 7:
		EventBus.player_damage_requested.emit(5, self)
		EventBus.gold_changed.emit(0)

	if not _is_in_enrage_phase():
		if greed_resource != null:
			if not has_status(StatusAilment.AilmentType.GREED):
				apply_status(greed_resource, 1, 1)
			else:
				add_status_stacks(StatusAilment.AilmentType.GREED, 1)
		greed_stacks += 1
		print("Add greed stacks")

func _execute_payout_strike() -> void:
	var total_damage: int = 7 + (4 * greed_stacks)
	EventBus.player_damage_requested.emit(total_damage, self)

func _is_in_enrage_phase() -> bool:
	if stats == null or stats.max_hp <= 0:
		return false
	return (float(current_hp) / float(stats.max_hp)) < 0.3

func _on_player_dealt_damage(_amount: int, target_enemy: EnemyBase) -> void:
	if target_enemy == self:
		GameManager.add_shop_coins(3)

func _apply_victory_reward() -> void:
	var bonus_reward: int = (10 + GameManager.shop_coins) * 2
	GameManager.add_shop_coins(bonus_reward)
