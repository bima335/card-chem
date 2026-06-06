class_name StageManager
extends  Node2D

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

func _ready():
	_calculate_stage_positions()
	#_set_up_dummy_waves()
	_setup_wave_from_map()
	EventBus.enemy_died.connect(_on_enemy_died)
	start_next_wave()

func _calculate_stage_positions():
	var viewport_size: Vector2 = get_viewport_rect().size
	var center_x: float = viewport_size.x /2.0
	player_position = Vector2(center_x, viewport_size.y - player_bottom_margin)
	
	var base_enemy_y: float = 150.0
	
	for i in range(5):
		var x_offset: int = i -2
		var pos_x: float = center_x + (x_offset * enemy_spacing_x)
		var pos_y: float = base_enemy_y + (curve_steepness * pow(x_offset, 2))
		enemy_position.append(Vector2(pos_x, pos_y))

func _setup_wave_from_map():
	wave_queue.clear()
	var incoming_enemies: Array[EnemyStat] = GameManager.current_wave_data
	
	if incoming_enemies.is_empty():
		push_warning("Musuh kosong")
		return
	
	wave_queue.push_back(incoming_enemies)
	print("StageManager sukses memuat ", incoming_enemies.size(), " musuh dari pilihan peta pemain!")

#func _set_up_dummy_waves():
	#var dummy_enemy = load("res://enemy/res/dummy_enemy1.tres")
	#if dummy_enemy == null:
		#push_warning("Enemy null")
		#return
	#
	#var wave_1: Array[EnemyStat] = [dummy_enemy, dummy_enemy]
	#var wave_2: Array[EnemyStat] = [dummy_enemy, dummy_enemy, dummy_enemy, dummy_enemy, dummy_enemy]
	#
	#wave_queue.push_back(wave_1)
	#wave_queue.push_back(wave_2)

func start_next_wave():
	if wave_queue.is_empty():
		print("Wave habis, menang")
		return
	
	var current_wave: Array = wave_queue.pop_front()
	print("Mulai wave baru dengan ", current_wave.size(), "musuh!")
	_spawn_wave(current_wave)

func _spawn_wave(wave_data: Array):
	var start_index: int = (5- wave_data.size()) / 2
	for i in range(wave_data.size()):
		var stat: EnemyStat = wave_data[i]
		var spawn_pos: Vector2 = enemy_position[start_index + i]
		if enemy_scene != null:
			# 1. Cetak Node musuh baru dari file .tscn
			var enemy_instance: EnemyBase = enemy_scene.instantiate() as EnemyBase
			
			# 2. Masukkan ke dalam StageManager agar muncul di Scene Tree
			
			# 3. Suntikkan data Resource (HP, Nama, Texture) ke musuh ini
			enemy_instance.stats = stat
			
			# 4. Pindahkan posisinya ke titik matematika kurva kita
			enemy_instance.global_position = spawn_pos
			
			add_child(enemy_instance)

				
			print("Berhasil memunculkan ", stat.enemy_name, " di ", spawn_pos)
		else:
			push_error("GAGAL SPAWN: 'Enemy Scene' di Inspector StageManager masih kosong!")
	
func execute_enemies_turn() -> void:
	# 1. Kumpulkan musuh mana saja yang masih hidup di panggung
	var active_enemies: Array[EnemyBase] = []
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			active_enemies.append(child)
			
	# 2. Cek apakah menang
	if active_enemies.is_empty():
		print("Semua musuh di Wave ini sudah mati!")
		# (Nanti kita bisa panggil _start_next_wave di sini)
		enemy_turn_ended.emit()
		return
		
	# 3. Eksekusi satu per satu dengan jeda
	for enemy in active_enemies:
		# Pastikan musuh belum mati di tengah-tengah proses
		if is_instance_valid(enemy):
			enemy.decrease_status_durations()
			var action = enemy.determine_next_move()
			if action != null:
				enemy.execute_move(action)
			
			# Jeda 1 detik agar pemain bisa mencerna apa yang terjadi
			await get_tree().create_timer(1.0).timeout
			
	# 4. Berikan kembali kendali ke pemain
	print("Giliran musuh selesai!")
	enemy_turn_ended.emit()
	
func _on_enemy_died(_dead_enemy: EnemyBase) -> void:
	# Tunggu 1 frame agar Godot selesai menghapus node musuh yang mati (queue_free)
	await get_tree().process_frame 
	
	var active_enemies: int = 0
	for child in get_children():
		if child is EnemyBase and not child.is_queued_for_deletion():
			active_enemies += 1
			
	if active_enemies == 0:
		print("WAVE DIBERSIHKAN!")
		if wave_queue.is_empty():
			print("SELAMAT! KAMU MEMENANGKAN SEMUA WAVE!")
			round_won.emit()
		else:
			print("Memulai Wave berikutnya...")
			wave_cleared.emit()
			start_next_wave()
	
	
	
	
	
	
	
	
