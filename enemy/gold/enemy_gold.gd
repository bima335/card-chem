class_name EnemyGold
extends EnemyBase

const STEAL_GOLD_AMOUNT: int = 100
const NO_GOLD_HP_PENALTY: int = 5
const BASE_ATTACK: int = 15
const GREED_DAMAGE_MULTIPLIER: int = 4
const GOLD_PER_HIT: int = 15
const CALL_COST: int = 200

var greed_stacks: int = 0
var stolen_coins_accumulator: int = 0
var is_enraged: bool = false


func _setup_enemy() -> void:
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)


func _on_round_started(current_round: int) -> void:
	if is_enraged:
		return

	if current_round % 2 == 1:
		_process_hoard_phase()

	if current_round % 3 == 0:
		_prompt_gambling_call()


func _process_hoard_phase() -> void:
	if GameManager.shop_coins >= STEAL_GOLD_AMOUNT:
		GameManager.shop_coins -= STEAL_GOLD_AMOUNT
		stolen_coins_accumulator += STEAL_GOLD_AMOUNT
		greed_stacks += 1
		print("Gold Boss mencuri ", STEAL_GOLD_AMOUNT, " Gold! Greed Stack: ", greed_stacks)
	elif GameManager.shop_coins > 0:
		stolen_coins_accumulator += GameManager.shop_coins
		GameManager.shop_coins = 0
		greed_stacks += 1
		print("Gold Boss mencuri sisa Gold Player! Greed Stack: ", greed_stacks)
	else:
		EventBus.player_took_damage.emit(NO_GOLD_HP_PENALTY)
		print("Gold Player habis! Gold Boss menyedot ", NO_GOLD_HP_PENALTY, " HP Player!")


func _prompt_gambling_call() -> void:
	if GameManager.shop_coins < CALL_COST:
		print("Gold tidak cukup untuk melakukan Call Judi!")
		return

	print("Opsi Call Judi Tersedia! Biaya: ", CALL_COST)


func execute_gambling_call() -> void:
	if GameManager.shop_coins < CALL_COST:
		return

	GameManager.shop_coins -= CALL_COST
	var win: bool = randf() < 0.5

	if win:
		greed_stacks = 0
		print("Judi Menang! Greed Stack Boss direset ke 0!")
	else:
		GameManager.shop_coins = 0
		if not is_enraged:
			greed_stacks += 2
		print("Judi Kalah! Gold hangus dan Greed Stack Boss bertambah!")


func determine_next_move() -> EnemyAction:
	var action: EnemyAction = EnemyAction.new()
	action.type = EnemyAction.ActionType.ATTACK
	
	var current_round: int = GameManager.current_round
	var is_payout_round: bool = (current_round % 2 == 0)

	if is_enraged or is_payout_round:
		action.amount = BASE_ATTACK + (GREED_DAMAGE_MULTIPLIER * greed_stacks)
	else:
		action.amount = 0

	return action


func take_damage(amount: int) -> void:
	if amount > 0:
		GameManager.add_shop_coins(GOLD_PER_HIT)
		print("Player menyerang Gold Boss dan mendapatkan ", GOLD_PER_HIT, " Gold!")

	super.take_damage(amount)


func _on_health_changed(new_hp: int) -> void:
	var hp_threshold: int = int(stats.max_hp * 0.3)
	if not is_enraged and new_hp <= hp_threshold:
		_enter_enrage_phase()


func _enter_enrage_phase() -> void:
	is_enraged = true
	print("Gold Boss masuk fase Enrage! Tidak ada Hoard lagi, semua serangan Payout Strike!")


func die() -> void:
	_reward_player()
	super.die()


func _reward_player() -> void:
	var total_bonus: int = GameManager.shop_coins * 2
	GameManager.add_shop_coins(total_bonus)
	print("Player menang! Total Gold berlipat ganda menjadi: ", GameManager.shop_coins)


func on_player_defeated() -> void:
	GameManager.shop_coins = 0
	print("Player kalah! Seluruh Gold hangus!")
