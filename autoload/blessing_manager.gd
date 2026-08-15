extends Node

const MAX_SLOTS: int = 3
var active_blessings: Array[BlessingData] = []
var cards_played_this_turn: int = 0

var _last_player_damage_dealt: int = 0

func _ready() -> void:
	_connect_event_bus()

func _connect_event_bus() -> void:
	EventBus.round_started.connect(_on_round_started)
	EventBus.card_played.connect(_on_card_played)
	EventBus.card_manually_discarded.connect(_on_card_manually_discarded)
	EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
	EventBus.poison_explosion_triggered.connect(_on_poison_explosion_triggered)
	EventBus.burn_damage_dealt.connect(_on_burn_damage_dealt)
	EventBus.player_dealt_damage.connect(_on_player_dealt_damage)
	EventBus.player_stunned.connect(_on_player_stunned)

func equip_blessing(blessing: BlessingData) -> bool:
	if active_blessings.size() >= MAX_SLOTS:
		return false
	
	if has_blessing(blessing.id):
		return false

	active_blessings.append(blessing)
	_on_blessing_added(blessing)
	RecapManager.track_blessing_acquired(blessing)
	EventBus.blessing_list_changed.emit()
	return true

func unequip_blessing(blessing: BlessingData) -> bool:
	if blessing in active_blessings:
		active_blessings.erase(blessing)
		_on_blessing_removed(blessing)
		EventBus.blessing_list_changed.emit()
		return true
	return false

func has_blessing(id: BlessingData.BlessingID) -> bool:
	for b in active_blessings:
		if b.id == id:
			return true
	return false

func clear_all_blessings() -> void:
	for b in active_blessings.duplicate():
		unequip_blessing(b)

func _on_player_stunned(_duration: int) -> void:
	if has_blessing(BlessingData.BlessingID.STAND_PROUD):
		var player = _get_player_node()
		if player:
			player.gain_shield(3)

func apply_passive_effects(hand_node: Hand) -> void:
	if not hand_node:
		return
		
	var bonus_hand_size: int = 0
	if has_blessing(BlessingData.BlessingID.A_HELPING_HAND):
		bonus_hand_size += 1
		
	hand_node.set_max_hand_size(5 + bonus_hand_size)

func _on_blessing_added(blessing: BlessingData) -> void:
	match blessing.id:
		BlessingData.BlessingID.A_HELPING_HAND:
			_update_hand_capacity(+1)

func _on_blessing_removed(blessing: BlessingData) -> void:
	match blessing.id:
		BlessingData.BlessingID.A_HELPING_HAND:
			_update_hand_capacity(-1)

func _update_hand_capacity(change: int) -> void:
	var hand_node = get_tree().root.find_child("Hand", true, false) as Hand
	if hand_node:
		hand_node.set_max_hand_size(hand_node.max_hand_size + change)

func _get_player_node() -> Player:
	return get_tree().root.find_child("Player", true, false) as Player

func _on_round_started(_round_nr: int) -> void:
	cards_played_this_turn = 0
	_last_player_damage_dealt = 0
	
	if has_blessing(BlessingData.BlessingID.PROTECTORS_WILL):
		var player = _get_player_node()
		if player:
			player.gain_shield(2)

func _on_card_played(_card: CardData) -> void:
	cards_played_this_turn += 1

func _on_player_dealt_damage(amount: int, _target: EnemyBase) -> void:
	_last_player_damage_dealt = amount

func trigger_resonance_heal() -> void:
	if has_blessing(BlessingData.BlessingID.RESONANCE):
		var player = _get_player_node()
		if player:
			player.heal(2)

func _on_enemy_status_applied(enemy: EnemyBase, status_type: StatusAilment.AilmentType) -> void:
	if status_type == StatusAilment.AilmentType.POISON and has_blessing(BlessingData.BlessingID.TOXIC_CHEMIST):
		_trigger_toxic_chemist_aoe_damage()

	match status_type:
		StatusAilment.AilmentType.BURN, StatusAilment.AilmentType.POISON, StatusAilment.AilmentType.DESTABILIZE:
			trigger_resonance_heal()

func _on_card_manually_discarded(_card: CardData) -> void:
	if has_blessing(BlessingData.BlessingID.RECYCLE):
		var player = _get_player_node()
		if player:
			player.add_random_token(1)

func _on_poison_explosion_triggered(_source_enemy: EnemyBase) -> void:
	pass

func _on_burn_damage_dealt(_amount: int) -> void:
	if has_blessing(BlessingData.BlessingID.COVER_BEHIND_SMOKE):
		var player = _get_player_node()
		if player:
			player.gain_shield(2)

func _trigger_toxic_chemist_aoe_damage() -> void:
	var stage_manager = get_tree().root.find_child("StageManager", true, false)
	if not stage_manager:
		return

	for child in stage_manager.get_children():
		if child is EnemyBase and is_instance_valid(child) and not child.is_queued_for_deletion():
			child.take_damage(6)
