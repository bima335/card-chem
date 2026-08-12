extends Node

var current_wave_data: Array[EnemyStat] = []
var map_data_matrix: Dictionary = {}
var current_floor: int = 0
var is_map_generated: bool = false
var available_paths: Array[Vector2i] = []
var history_path: Array[Vector2i] = []

var player_current_hp: int = 1000
var player_max_hp: int = 1000
var active_event_type: MapNodeData.NodeType
var shop_coins: int = 1000
var player_deck: Array[CardData] = []

@export var current_section: SectionData = null

var current_round: int = 1

var global_common_enemies: Array[EnemyStat] = []
var global_elite_enemies: Array[EnemyStat] = []
var sections_data: Array[SectionData] = []

func setup_enemy_pools(common_global: Array[EnemyStat], elite_global: Array[EnemyStat], sections: Array[SectionData]) -> void:
	global_common_enemies = common_global
	global_elite_enemies = elite_global
	sections_data = sections

func reset_round() -> void:
	current_round = 1

func advance_round() -> int:
	current_round += 1
	return current_round

func add_shop_coins(amount: int) -> void:
	if amount <= 0:
		return
	shop_coins += amount

func update_current_section_for_floor(floor_idx: int) -> void:
	var section_idx: int = floor_idx / 5
	if section_idx < sections_data.size():
		current_section = sections_data[section_idx]
	else:
		push_warning("GameManager: Indeks section " + str(section_idx) + " melebihi total sections_data!")

func generate_new_adventure(total_floors: int, nodes_per_floor: int, force_first_three_shops: bool = false) -> void:
	if is_map_generated: return
	
	map_data_matrix.clear()
	current_floor = 0
	available_paths.clear()
	history_path.clear()
	shop_coins = 1000
	player_deck.clear()
	reset_round()

	update_current_section_for_floor(0)

	for floor_idx in range(total_floors):
		map_data_matrix[floor_idx] = []
		
		var local_floor: int = floor_idx % 5 
		var current_floor_nodes_count: int = 1 if (local_floor == 3 or local_floor == 4) else nodes_per_floor
		
		var section_idx: int = floor_idx / 5
		var section_for_generation: SectionData = null
		if section_idx < sections_data.size():
			section_for_generation = sections_data[section_idx]
		
		for node_idx in range(current_floor_nodes_count):
			var node_data = MapNodeData.new()
			node_data.grid_position = Vector2i(floor_idx, node_idx)
			
			if force_first_three_shops and floor_idx < 3:
				node_data.type = MapNodeData.NodeType.SHOP
			elif local_floor == 3:
				node_data.type = MapNodeData.NodeType.REST
			elif local_floor == 4:
				node_data.type = MapNodeData.NodeType.BOSS
				node_data.wave_data = WaveGenerator.generate_wave(2, section_for_generation, global_common_enemies, global_elite_enemies)
			elif floor_idx == 0:
				node_data.type = MapNodeData.NodeType.BATTLE_NORMAL
				node_data.wave_data = WaveGenerator.generate_wave(0, section_for_generation, global_common_enemies, global_elite_enemies)
			else:
				var roll = randf()
				if roll < 0.50: 
					node_data.type = MapNodeData.NodeType.BATTLE_NORMAL
					node_data.wave_data = WaveGenerator.generate_wave(0, section_for_generation, global_common_enemies, global_elite_enemies)
				elif roll < 0.75: 
					node_data.type = MapNodeData.NodeType.BATTLE_HARD
					node_data.wave_data = WaveGenerator.generate_wave(1, section_for_generation, global_common_enemies, global_elite_enemies)
				else: 
					node_data.type = MapNodeData.NodeType.SHOP
					
			map_data_matrix[floor_idx].append(node_data)

	for floor_idx in range(total_floors - 1):
		var current_nodes = map_data_matrix[floor_idx]
		var next_nodes = map_data_matrix[floor_idx + 1]
		
		for i in range(current_nodes.size()):
			var current_node: MapNodeData = current_nodes[i]
			
			if next_nodes.size() == 1:
				current_node.next_connections.append(next_nodes[0].grid_position)
			elif current_nodes.size() == 1:
				for target_node in next_nodes:
					current_node.next_connections.append(target_node.grid_position)
			else:
				current_node.next_connections.append(next_nodes[i].grid_position)
				if randf() > 0.5:
					var offset = 1 if randf() > 0.5 else -1
					var target_index = clamp(i + offset, 0, next_nodes.size() - 1)
					if target_index != i:
						var target_pos = next_nodes[target_index].grid_position
						if not current_node.next_connections.has(target_pos):
							current_node.next_connections.append(target_pos)
							
	is_map_generated = true

func set_current_section(new_section: SectionData) -> void:
	current_section = new_section
