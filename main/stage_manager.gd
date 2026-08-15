class_name StageManager
extends Node2D

signal wave_cleared
signal round_won
signal enemy_turn_ended

@export_group("Spawn Configuration")
@export var enemy_base_y: float = 300.0
@export var enemy_spacing_x: float = 160.0
@export var curve_steepness: float = 30.0
@export var player_bottom_margin: float = 180.0

@export_group("Scene References")
@export var enemy_scene: PackedScene

var player_position: Vector2
var enemy_position: Array[Vector2] = []
var wave_queue: Array[Array] = []

func _ready() -> void:
	_calculate_stage_positions()
	_setup_wave_from_map()
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_summon_requested.connect(_on_enemy_summon_requested)
	start_next_wave()

func _calculate_stage_positions() -> void:
	enemy_position.clear()
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var center_x: float = viewport_size.x / 2.0
	player_position = Vector2(center_x, viewport_size.y - player_bottom_margin)
	
	for slot_index in range(5):
		var slot_offset: int = slot_index - 2
		var spawn_x: float = center_x + (slot_offset * enemy_spacing_x)
		var spawn_y: float = enemy_base_y + (curve_steepness * pow(slot_offset, 2))
		enemy_position.append(Vector2(spawn_x, spawn_y))

func _on_enemy_summon_requested(minion_stat: EnemyStat, amount: int	) -> void:
	if minion_stat == null or amount <= 0:
		return
		
	var empty_indices: Array[int] = _get_available_spawn_indices()
	var spawn_count: int = mini(amount, empty_indices.size())
	
	for i in range(spawn_count):
		var target_index: int = empty_indices[i]
		_spawn_single_enemy(minion_stat, enemy_position[target_index])

func _get_available_spawn_indices() -> Array[int]:
	var occupied_positions: Array[Vector2] = []
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			occupied_positions.append(child.global_position)
			
	var free_indices: Array[int] = []
	for i in range(enemy_position.size()):
		var pos: Vector2 = enemy_position[i]
		if not occupied_positions.has(pos):
			free_indices.append(i)
			
	return free_indices

func _spawn_single_enemy(stat: EnemyStat, spawn_pos: Vector2) -> void:
	var scene_to_spawn: PackedScene = enemy_scene
	if stat.custom_enemy_scene != null:
		scene_to_spawn = stat.custom_enemy_scene
		
	if scene_to_spawn != null:
		var enemy_instance: EnemyBase = scene_to_spawn.instantiate() as EnemyBase
		enemy_instance.stats = stat
		enemy_instance.global_position = spawn_pos
		add_child(enemy_instance)

func _setup_wave_from_map() -> void:
	wave_queue.clear()
	var incoming_enemies: Array[EnemyStat] = GameManager.current_wave_data
	
	if incoming_enemies.is_empty():
		push_warning("StageManager: Data wave musuh dari GameManager kosong!")
		return
	
	wave_queue.push_back(incoming_enemies)

func start_next_wave() -> void:
	if wave_queue.is_empty():
		return
	
	var current_wave: Array = wave_queue.pop_front()
	_spawn_wave(current_wave)

func _spawn_wave(wave_data: Array) -> void:
	var start_index: int = (5 - wave_data.size()) / 2
	for i in range(wave_data.size()):
		var stat: EnemyStat = wave_data[i]
		var spawn_pos: Vector2 = enemy_position[start_index + i]

		var scene_to_spawn: PackedScene = enemy_scene
		if stat.custom_enemy_scene != null:
			scene_to_spawn = stat.custom_enemy_scene
			
		if scene_to_spawn != null:
			var enemy_instance: EnemyBase = scene_to_spawn.instantiate() as EnemyBase
			enemy_instance.stats = stat
			enemy_instance.global_position = spawn_pos
			add_child(enemy_instance)
		else:
			push_error("GAGAL SPAWN: Tidak ada PackedScene valid untuk di-instantiate!")

func get_sorted_active_enemies() -> Array[EnemyBase]:
	var enemies: Array[EnemyBase] = []
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			enemies.append(child)

	enemies.sort_custom(func(a: EnemyBase, b: EnemyBase): return a.global_position.x < b.global_position.x)
	return enemies

func get_adjacent_enemies(target_enemy: EnemyBase) -> Dictionary:
	var result = {"left": null, "right": null}
	var sorted_enemies = get_sorted_active_enemies()
	
	var target_index = sorted_enemies.find(target_enemy)
	if target_index == -1:
		return result
		
	if target_index > 0:
		result["left"] = sorted_enemies[target_index - 1]
		
	if target_index < sorted_enemies.size() - 1:
		result["right"] = sorted_enemies[target_index + 1]
		
	return result

func execute_enemies_turn() -> void:
	var active_enemies: Array[EnemyBase] = []
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			active_enemies.append(child)
			
	if active_enemies.is_empty():
		enemy_turn_ended.emit()
		return
		
	for enemy in active_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.start_turn_process()

			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				var action = enemy.determine_next_move()
				if action != null:
					enemy.execute_move(action)
				
				await get_tree().create_timer(0.8).timeout
			
	enemy_turn_ended.emit()

func _on_enemy_died(_dead_enemy: EnemyBase) -> void:
	await get_tree().process_frame 
	
	var active_enemies: int = 0
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			active_enemies += 1
			
	if active_enemies == 0:
		if wave_queue.is_empty():
			round_won.emit()
		else:
			wave_cleared.emit()
			start_next_wave()

func apply_aoe_poison_and_stun(poison_amount: int = 1, stun_amount: int = 1) -> void:
	var active_enemies: Array[EnemyBase] = get_sorted_active_enemies()
	for enemy in active_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.apply_poison_and_stun(poison_amount, stun_amount)
