extends Node

var current_wave_data: Array[EnemyStat] = []

var map_data_matrix: Dictionary = {}
var current_floor: int = 0
var is_map_generated: bool = false # Flag agar peta tidak teracak ulang saat kembali dari battle
var available_paths: Array[Vector2i] = []
var history_path: Array[Vector2i] = []

var player_current_hp: int = 50
var player_max_hp: int = 50
var active_event_type: MapNodeData.NodeType
var shop_coins: int = 0
var player_deck: Array[CardData] = []

func generate_new_adventure(total_floors: int, nodes_per_floor: int, pool_enemies: Array[EnemyStat]) -> void:
	if is_map_generated: return
	
	map_data_matrix.clear()
	current_floor = 0
	available_paths.clear()
	history_path.clear()
	
	shop_coins = 0
	player_deck.clear()
	# Asumsi HP dsb direset di sini...
	
	# ==========================================
	# TAHAP 1: MEMBANGUN SELURUH LANTAI & NODE
	# ==========================================
	for floor_idx in range(total_floors): # total_floors sekarang akan diisi 15
		map_data_matrix[floor_idx] = []
		
		# local_floor adalah angka 0 sampai 4 (Lantai ke-berapa di dalam section tersebut)
		var local_floor: int = floor_idx % 5 
		
		# Lantai 3 (Rest) dan Lantai 4 (Boss) HANYA memiliki 1 Node! Sisanya sesuai nodes_per_floor.
		var current_floor_nodes_count: int = 1 if (local_floor == 3 or local_floor == 4) else nodes_per_floor
		
		for node_idx in range(current_floor_nodes_count):
			var node_data = MapNodeData.new()
			node_data.grid_position = Vector2i(floor_idx, node_idx)
			
			if local_floor == 3:
				node_data.type = MapNodeData.NodeType.REST
				
			elif local_floor == 4:
				node_data.type = MapNodeData.NodeType.BOSS
				# (Wave untuk Boss nanti bisa ditambahkan di sini)
				
			elif floor_idx == 0:
				# ==========================================
				# DESAIN KHUSUS: STAGE 1 (TUTORIAL / WARM-UP)
				# ==========================================
				node_data.type = MapNodeData.NodeType.BATTLE_NORMAL
				var tutorial_pool = pool_enemies.filter(func(e): return e.tag == EnemyStat.EnemyTag.SMALL)
				
				if not tutorial_pool.is_empty():
					var first_stage_wave: Array[EnemyStat] = []
					first_stage_wave.append(tutorial_pool.pick_random())
					node_data.wave_data = first_stage_wave
				else:
					push_error("GameManager: Tidak ada musuh SMALL untuk Stage 1!")
					
			else:
				# ==========================================
				# GENERASI ACAK UNTUK LANTAI SELANJUTNYA
				# ==========================================
				var roll = randf()
				if roll < 0.50: 
					node_data.type = MapNodeData.NodeType.BATTLE_NORMAL
					# Pengisian wave normal dipindah ke sini agar aman!
					node_data.wave_data = WaveGenerator.generate_wave(0, pool_enemies)
					
				elif roll < 0.75: 
					node_data.type = MapNodeData.NodeType.BATTLE_HARD
					# Pengisian wave hard dipindah ke sini agar aman!
					node_data.wave_data = WaveGenerator.generate_wave(1, pool_enemies)
					
				else: 
					node_data.type = MapNodeData.NodeType.SHOP
					
			# Masukkan ke matriks peta
			map_data_matrix[floor_idx].append(node_data)
			
	# ==========================================
	# TAHAP 2: MENYAMBUNGKAN GARIS KONEKSI (BOTTLENECK LOGIC)
	# ==========================================
	for floor_idx in range(total_floors - 1):
		var current_nodes = map_data_matrix[floor_idx]
		var next_nodes = map_data_matrix[floor_idx + 1]
		
		for i in range(current_nodes.size()):
			var current_node: MapNodeData = current_nodes[i]
			
			if next_nodes.size() == 1:
				# ATURAN CORONG: Jika lantai depan cuma 1 node (Rest/Boss), SEMUA jalur harus tersedot ke node 0 tersebut.
				current_node.next_connections.append(next_nodes[0].grid_position)
				
			elif current_nodes.size() == 1:
				# ATURAN MEKAR: Jika lantai ini cuma 1 node (Boss) dan depan banyak (awal Section baru), buka semua jalur!
				for target_node in next_nodes:
					current_node.next_connections.append(target_node.grid_position)
					
			else:
				# ATURAN NORMAL: Lurus dan serong
				current_node.next_connections.append(next_nodes[i].grid_position)
				if randf() > 0.5:
					var offset = 1 if randf() > 0.5 else -1
					var target_index = clamp(i + offset, 0, next_nodes.size() - 1)
					if target_index != i:
						var target_pos = next_nodes[target_index].grid_position
						if not current_node.next_connections.has(target_pos):
							current_node.next_connections.append(target_pos)
							
	is_map_generated = true
