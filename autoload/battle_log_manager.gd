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

	if EventBus.has_signal("tokens_gained"):
		EventBus.tokens_gained.connect(_on_tokens_gained)

	if EventBus.has_signal("siphon_token_requested"):
		EventBus.siphon_token_requested.connect(_on_token_siphoned)

	if EventBus.has_signal("enemy_summon_requested"):
		EventBus.enemy_summon_requested.connect(_on_enemy_summoned)

	if EventBus.has_signal("apply_player_status"):
		EventBus.apply_player_status.connect(_on_player_status_applied)

	if EventBus.has_signal("enemy_gained_buff"):
		EventBus.enemy_gained_buff.connect(_on_enemy_gained_buff)

	if EventBus.has_signal("dazzle_stacks_changed"):
		EventBus.dazzle_stacks_changed.connect(_on_dazzle_stacks_changed)

	if EventBus.has_signal("boss_phase_changed"):
		EventBus.boss_phase_changed.connect(_on_boss_phase_changed)

	if EventBus.has_signal("player_stunned_requested"):
		EventBus.player_stunned_requested.connect(_on_player_stunned)

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

func _on_tokens_gained(tokens: Dictionary) -> void:
	var parts: Array[String] = []
	var color_map: Dictionary = {
		"Carbon": "gray",
		"Hydrogen": "aqua",
		"Oxygen": "light_blue",
		"Nitrogen": "green"
	}
	
	for token_name: String in tokens:
		var amount: int = tokens[token_name]
		var color: String = color_map.get(token_name, "white")
		parts.append("[color=" + color + "]+" + str(amount) + " " + token_name + "[/color]")
		
	if not parts.is_empty():
		add_log("[color=cyan]Pemain[/color] menerima token: " + ", ".join(parts) + ".")

func _on_token_siphoned(token_type: String, amount: int) -> void:
	add_log("[color=red][!] Musuh menyedot [b]" + str(amount) + " token " + token_type.capitalize() + "[/b] milik Pemain![/color]")

func _on_enemy_summoned(minion_stat: EnemyStat, amount: int) -> void:
	var minion_name: String = minion_stat.enemy_name if minion_stat else "Minion"
	add_log("[color=purple][!] Musuh memanggil " + str(amount) + "x [b]" + minion_name + "[/b] ke arena![/color]")

func _on_player_status_applied(status_name: String, duration: int, damage_per_turn: int) -> void:
	add_log("[color=salmon][!] Pemain terkena status [b]" + status_name + "[/b] selama " + str(duration) + " giliran (" + str(damage_per_turn) + " dmg/turn)![/color]")

func _on_enemy_gained_buff(enemy: EnemyBase, buff_name: String, stacks_added: int, total_stacks: int) -> void:
	var enemy_name: String = enemy.stats.enemy_name if enemy.stats else enemy.name
	add_log("[color=gold]" + enemy_name + " memperoleh +" + str(stacks_added) + " [b]" + buff_name + "[/b] (Total: " + str(total_stacks) + ").[/color]")

func _on_dazzle_stacks_changed(current_stacks: int) -> void:
	if current_stacks > 0:
		add_log("[color=yellow][!] Medan energi [b]Dazzle[/b] meningkat menjadi " + str(current_stacks) + " stack![/color]")

func _on_boss_phase_changed(boss_name: String, new_phase: int) -> void:
	add_log("\n[b][color=crimson]=== PERINGATAN: " + boss_name.to_upper() + " MEMASUKI FASE " + str(new_phase) + " ===[/color][/b]")

func _on_player_stunned(duration: int) -> void:
	add_log("[color=dark_red][X] Pemain mengalami [b]STUN[/b] selama " + str(duration) + " giliran![/color]")
