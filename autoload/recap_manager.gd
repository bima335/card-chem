extends Node

# --- Statistik Pertempuran & Karakter ---
var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var current_gold: int = 0
var total_cards_obtained: int = 0
var total_enemies_defeated: int = 0
var total_bosses_defeated: int = 0
var biggest_one_hit_damage: int = 0
var total_cards_discarded: int = 0
var total_cards_played: int = 0
var total_blessings_obtained: int = 0

var history_cards: Array[CardData] = []
var history_blessings: Array[BlessingData] = []

var highest_node_reached: int = 0
var history_nodes_path: Array[Vector2i] = []


func _ready() -> void:
	_connect_event_bus()


func reset_stats() -> void:
	total_damage_dealt = 0
	total_damage_taken = 0
	current_gold = GameManager.shop_coins
	total_cards_obtained = 0
	total_enemies_defeated = 0
	total_bosses_defeated = 0
	biggest_one_hit_damage = 0
	total_cards_discarded = 0
	total_cards_played = 0
	total_blessings_obtained = 0
	
	history_cards.clear()
	history_blessings.clear()

	highest_node_reached = 0
	history_nodes_path.clear()


func _connect_event_bus() -> void:
	EventBus.player_dealt_damage.connect(_on_player_dealt_damage)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.card_obtained.connect(_on_card_obtained)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.card_played.connect(_on_card_played)
	EventBus.card_manually_discarded.connect(_on_card_discarded)
	EventBus.blessing_list_changed.connect(_on_blessing_list_changed)

func record_node_visited(node_position: Vector2i, floor_level: int) -> void:
	history_nodes_path.append(node_position)
	if floor_level > highest_node_reached:
		highest_node_reached = floor_level


func sync_map_progress_from_gamemanager() -> void:
	history_nodes_path = GameManager.history_path.duplicate()
	highest_node_reached = GameManager.current_floor

func _on_player_dealt_damage(amount: int, _target_enemy: EnemyBase) -> void:
	if amount <= 0:
		return
		
	total_damage_dealt += amount
	if amount > biggest_one_hit_damage:
		biggest_one_hit_damage = amount


func _on_player_took_damage(amount: int) -> void:
	if amount > 0:
		total_damage_taken += amount


func _on_gold_changed(total_gold: int) -> void:
	current_gold = total_gold


func _on_card_obtained(card: CardData) -> void:
	if card:
		total_cards_obtained += 1
		history_cards.append(card)


func _on_enemy_killed(enemy: EnemyBase, is_boss: bool) -> void:
	if is_boss:
		total_bosses_defeated += 1
	else:
		total_enemies_defeated += 1


func _on_card_played(_card: CardData) -> void:
	total_cards_played += 1


func _on_card_discarded(_card: CardData) -> void:
	total_cards_discarded += 1


func _on_blessing_list_changed() -> void:
	total_blessings_obtained = BlessingManager.active_blessings.size()


func track_blessing_acquired(blessing: BlessingData) -> void:
	total_blessings_obtained += 1
	history_blessings.append(blessing)
