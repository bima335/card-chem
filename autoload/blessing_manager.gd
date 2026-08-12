extends Node

const MAX_SLOTS: int = 3
var active_blessings: Array[BlessingData] = []
var cards_played_this_turn: int = 0

func _ready() -> void:
	_connect_event_bus()

func _connect_event_bus() -> void:
	EventBus.round_started.connect(_on_round_started)
	EventBus.card_played.connect(_on_card_played)
	EventBus.card_manually_discarded.connect(_on_card_manually_discarded)
	EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
	EventBus.poison_explosion_triggered.connect(_on_poison_explosion_triggered)
	EventBus.burn_damage_dealt.connect(_on_burn_damage_dealt)

func equip_blessing(blessing: BlessingData) -> bool:
	if active_blessings.size() >= MAX_SLOTS:
		return false
	
	if has_blessing(blessing.id):
		return false

	active_blessings.append(blessing)
	_on_blessing_added(blessing)
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
	
	if has_blessing(BlessingData.BlessingID.PROTECTORS_WILL):
		var player = _get_player_node()
		if player:
			player.gain_shield(2)

func _on_card_played(_card: CardData) -> void:
	cards_played_this_turn += 1
	if has_blessing(BlessingData.BlessingID.RESONANCE):
		if cards_played_this_turn % 2 == 0:
			var player = _get_player_node()
			if player:
				player.heal(2)

func _on_card_manually_discarded(_card: CardData) -> void:
	if has_blessing(BlessingData.BlessingID.RECYCLE):
		var player = _get_player_node()
		if player:
			player.add_random_token(1)

func _on_poison_explosion_triggered(source_enemy: EnemyBase) -> void:
	if has_blessing(BlessingData.BlessingID.TOXIC_CHEMIST):
		var stage_manager = get_tree().root.find_child("StageManager", true, false)
		if stage_manager:
			for child in stage_manager.get_children():
				if child is EnemyBase and child != source_enemy and not child.is_queued_for_deletion():
					child.take_damage(6)

func _on_enemy_status_applied(enemy: EnemyBase, status_type: StatusAilment.AilmentType) -> void:
	if has_blessing(BlessingData.BlessingID.OVER_ACCIDIC):
		if status_type == StatusAilment.AilmentType.DESTABILIZE:
			enemy.take_damage(3)
			
	if has_blessing(BlessingData.BlessingID.STAND_PROUD):
		var player = _get_player_node()
		if player:
			player.gain_shield(3)


func _on_burn_damage_dealt(_amount: int) -> void:
	if has_blessing(BlessingData.BlessingID.COVER_BEHIND_SMOKE):
		var player = _get_player_node()
		if player:
			player.gain_shield(2)
