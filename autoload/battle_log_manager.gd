class_name LogManager
extends Node

signal log_updated(full_log_text: String)
signal log_cleared

var _log_entries: Array[String] = []


func _ready() -> void:
	add_to_group("log_manager")
	_connect_event_bus_signals()


func clear_log() -> void:
	_log_entries.clear()
	log_cleared.emit()
	log_updated.emit("")


func add_log(message: String) -> void:
	_log_entries.append(message)
	log_updated.emit(_get_formatted_text())


func _get_formatted_text() -> String:
	return "\n".join(_log_entries)


func _connect_event_bus_signals() -> void:
	if EventBus.has_signal("card_played"):
		EventBus.card_played.connect(_on_card_played)
		
	if EventBus.has_signal("player_dealt_damage"):
		EventBus.player_dealt_damage.connect(_on_player_dealt_damage)
		
	if EventBus.has_signal("player_took_damage"):
		EventBus.player_took_damage.connect(_on_player_took_damage)
		
	if EventBus.has_signal("enemy_status_applied"):
		EventBus.enemy_status_applied.connect(_on_enemy_status_applied)
		
	if EventBus.has_signal("enemy_died"):
		EventBus.enemy_died.connect(_on_enemy_died)
		
	if EventBus.has_signal("round_started"):
		EventBus.round_started.connect(_on_round_started)


func _on_card_played(card_data: CardData) -> void:
	add_log("[color=#0066CC]Pemain[/color] memainkan kartu [color=#556B2F]" + card_data.card_name + "[/color].")


func _on_player_dealt_damage(amount: int, target_enemy: EnemyBase) -> void:
	var enemy_name: String = target_enemy.stats.enemy_name if target_enemy.stats else target_enemy.name
	add_log("[color=#0066CC]Pemain[/color] memberikan [color=#CC0000]" + str(amount) + " damage[/color] ke [color=#8B4513]" + enemy_name + "[/color].")


func _on_player_took_damage(amount: int) -> void:
	add_log("[color=#0066CC]Pemain[/color] menerima [color=#CC0000]" + str(amount) + " damage[/color].")


func _on_enemy_status_applied(enemy: EnemyBase, status_type: StatusAilment.AilmentType) -> void:
	var enemy_name: String = enemy.stats.enemy_name if enemy.stats else enemy.name
	var status_str: String = StatusAilment.AilmentType.keys()[status_type]
	add_log("[color=#CC6600]" + enemy_name + "[/color] terkena efek [color=#9900CC]" + status_str + "[/color].")


func _on_enemy_died(enemy_node: EnemyBase) -> void:
	var enemy_name: String = enemy_node.stats.enemy_name if enemy_node.stats else enemy_node.name
	add_log("[color= #666666]" + enemy_name + " telah dikalahkan![/color]")


func _on_round_started(current_round: int) -> void:
	add_log("\n[b]--- RONDE " + str(current_round) + " DIMULAI ---[/b]")
