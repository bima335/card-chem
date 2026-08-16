class_name StageManager
extends Node2D

signal wave_cleared
signal round_won
signal enemy_turn_ended

@export_group("Spawn Configuration")
@export var enemy_base_y: float = 350.0
@export var enemy_spacing_x: float = 180.0
@export var cobalt_center_gap: float = 120.0
@export var player_bottom_margin: float = 180.0

@export_group("Custom Spawn Markers")
@export var boss_spawn_marker: Marker2D
@export var boss_cobalt_spawn_point: Marker2D

@export_group("Throne Environment")
@export var throne_texture_rect: TextureRect

@export_group("Scene References")
@export var enemy_scene: PackedScene

var player_position: Vector2
var enemy_position: Array[Vector2] = []
var wave_queue: Array[Array] = []

const COBALT_SPAWN_PRIORITY: Array[int] = [1, 3, 0, 4]
const DEFAULT_SPAWN_PRIORITY: Array[int] = [2, 1, 3, 0, 4]


func _ready() -> void:
	_setup_throne_visibility()
	_setup_wave_from_map()
	_calculate_stage_positions()
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_summon_requested.connect(_on_enemy_summon_requested)
	start_next_wave()


func _setup_throne_visibility() -> void:
	if throne_texture_rect == null:
		return
	throne_texture_rect.visible = _is_cobalt_boss_battle()


func _is_cobalt_boss_battle() -> bool:
	if GameManager.active_event_type != MapNodeData.NodeType.BOSS:
		return false
		
	var incoming_enemies: Array[EnemyStat] = GameManager.current_wave_data
	for stat in incoming_enemies:
		if _is_cobalt_boss_stat(stat):
			return true
			
	if GameManager.current_section and GameManager.current_section.section_name.to_lower() == "cobalt":
		return true
		
	return false


func _is_cobalt_boss_stat(stat: EnemyStat) -> bool:
	if not _is_boss_stat(stat):
		return false
	var enemy_name: String = stat.enemy_name.to_lower() if "enemy_name" in stat else ""
	return "cobalt" in enemy_name or (stat.custom_enemy_scene != null and "cobalt" in stat.custom_enemy_scene.resource_path.to_lower())


func _calculate_stage_positions() -> void:
	enemy_position.clear()
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var center_x: float = viewport_size.x / 2.0
	player_position = Vector2(center_x, viewport_size.y - player_bottom_margin)
	
	var is_cobalt: bool = _is_cobalt_boss_battle()
	var current_center_gap: float = cobalt_center_gap if is_cobalt else 0.0
	
	for slot_index in range(5):
		var slot_offset: int = slot_index - 2
		var base_offset_x: float = slot_offset * enemy_spacing_x
		var extra_gap_x: float = 0.0
		
		if slot_offset < 0:
			extra_gap_x = -current_center_gap
		elif slot_offset > 0:
			extra_gap_x = current_center_gap
			
		var spawn_x: float = center_x + base_offset_x + extra_gap_x
		var spawn_y: float = enemy_base_y
		
		enemy_position.append(Vector2(spawn_x, spawn_y))


func _on_enemy_summon_requested(minion_stat: EnemyStat, amount: int) -> void:
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
	var priority_order: Array[int] = COBALT_SPAWN_PRIORITY if _is_cobalt_boss_battle() else DEFAULT_SPAWN_PRIORITY
	
	for slot_idx in priority_order:
		var pos: Vector2 = enemy_position[slot_idx]
		if not occupied_positions.has(pos):
			free_indices.append(slot_idx)
			
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
	var is_cobalt: bool = _is_cobalt_boss_battle()
	var start_index: int = (5 - wave_data.size()) / 2
	
	for i in range(wave_data.size()):
		var stat: EnemyStat = wave_data[i]
		var spawn_pos: Vector2 = Vector2.ZERO

		if _is_cobalt_boss_stat(stat) and boss_cobalt_spawn_point != null:
			spawn_pos = boss_cobalt_spawn_point.global_position
		elif _is_boss_stat(stat) and boss_spawn_marker != null:
			spawn_pos = boss_spawn_marker.global_position
		else:
			if is_cobalt:
				var available_slots = _get_available_spawn_indices()
				if not available_slots.is_empty():
					spawn_pos = enemy_position[available_slots[0]]
				else:
					spawn_pos = enemy_position[start_index + i]
			else:
				spawn_pos = enemy_position[start_index + i]

		var scene_to_spawn: PackedScene = enemy_scene
		if stat.custom_enemy_scene != null:
			scene_to_spawn = stat.custom_enemy_scene
			
		if scene_to_spawn != null:
			var enemy_instance: EnemyBase = scene_to_spawn.instantiate() as EnemyBase
			enemy_instance.stats = stat
			enemy_instance.global_position = spawn_pos
			add_child(enemy_instance)
			
			if _is_boss_stat(stat):
				EventBus.boss_spawned.emit.call_deferred(enemy_instance)
		else:
			push_error("GAGAL SPAWN: Tidak ada PackedScene valid untuk di-instantiate!")


func _is_boss_stat(stat: EnemyStat) -> bool:
	if stat == null:
		return false
	if "tag" in stat:
		return stat.tag == EnemyStat.EnemyTag.BOSS
	return false


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
					await enemy.execute_move(action)
				
				await get_tree().create_timer(0.3).timeout
			
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
