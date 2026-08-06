class_name StageManager
extends Node2D

signal wave_cleared
signal round_won
signal enemy_turn_ended

@export var enemy_spacing_x: float = 160.0
@export var curve_steepness: float = 30.0
@export var player_bottom_margin: float = 180.0

@export var enemy_scene: PackedScene

var player_position: Vector2
var enemy_position: Array[Vector2] = []

var wave_queue: Array[Array] = []

func _ready() -> void:
	_calculate_stage_positions()
	_setup_wave_from_map()
	EventBus.enemy_died.connect(_on_enemy_died)
	start_next_wave()

func _calculate_stage_positions() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var center_x: float = viewport_size.x / 2.0
	player_position = Vector2(center_x, viewport_size.y - player_bottom_margin)
	
	var base_enemy_y: float = 150.0
	
	for i in range(5):
		var x_offset: int = i - 2
		var pos_x: float = center_x + (x_offset * enemy_spacing_x)
		var pos_y: float = base_enemy_y + (curve_steepness * pow(x_offset, 2))
		enemy_position.append(Vector2(pos_x, pos_y))

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
		if enemy_scene != null:
			var enemy_instance: EnemyBase = enemy_scene.instantiate() as EnemyBase
			enemy_instance.stats = stat
			enemy_instance.global_position = spawn_pos
			add_child(enemy_instance)
		else:
			push_error("GAGAL SPAWN: 'Enemy Scene' di Inspector StageManager masih kosong!")

func execute_enemies_turn() -> void:
	var active_enemies: Array[EnemyBase] = []
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			active_enemies.append(child)
			
	if active_enemies.is_empty():
		enemy_turn_ended.emit()
		return
		
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			# PERBAIKAN: Panggil start_turn_process() untuk Burn damage, Stun, & durasi status
			enemy.start_turn_process()
			
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
