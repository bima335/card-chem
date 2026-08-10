class_name EnemyGold
extends EnemyBase

var stolen_coins: int = 0


func _setup_enemy() -> void:
	_steal_player_coins()


func _steal_player_coins() -> void:
	stolen_coins = GameManager.shop_coins
	GameManager.shop_coins = 0
	print("Enemy Gold mencuri ", stolen_coins, " gold milik Player!")


func determine_next_move() -> EnemyAction:
	var action: EnemyAction = EnemyAction.new()
	action.type = EnemyAction.ActionType.ATTACK
	action.amount = 10
	return action


func die() -> void:
	_reward_player()
	super.die()


func _reward_player() -> void:
	var reward_coins: int = stolen_coins * 2
	GameManager.shop_coins += reward_coins
	print("Enemy Gold dikalahkan! Player mendapatkan ", reward_coins, " gold (2x lipat)!")
