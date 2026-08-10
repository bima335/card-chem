class_name MapManager
extends Control

@export var map_node_scene: PackedScene
@export var section_wallpapers: Array[Texture2D] = [] 

@export_group("Enemy Configuration Pool")
@export var global_common_enemies: Array[EnemyStat] = []
@export var global_elite_enemies: Array[EnemyStat] = []
@export var sections_data: Array[SectionData] = []

@export_group("Map Layout Settings")
@export var total_floors: int = 15 
@export var nodes_per_floor: int = 3
@export var spacing_x: float = 220.0

@export_group("Debug / Testing Options")
## Pilih Section awal untuk keperluan Testing di Inspector (0 = Section 1, 1 = Section 2, dst)
@export_range(0, 10, 1) var test_starting_section: int = 0
## Centang untuk mengabaikan musuh acak dan memaksa pertempuran dengan musuh ujicoba
@export var is_ujicoba: bool = false
## Drag & Drop file Resource .tres (EnemyStat) yang ingin diuji di sini
@export var test_enemy: EnemyStat

const SECTION_WIDTH: float = 1920.0
const SECTION_HEIGHT: float = 1080.0

@onready var scroll_container: ScrollContainer = get_parent()

@onready var btn_up: Button = $"../../BtnUp"
@onready var btn_down: Button = $"../../BtnDown"

var total_sections: int = 0
var current_view_section: int = 0

func _ready() -> void:
	total_sections = total_floors / 5
	
	_apply_debug_starting_section()
	
	GameManager.setup_enemy_pools(global_common_enemies, global_elite_enemies, sections_data)
	
	_apply_debug_starting_section()
	GameManager.generate_new_adventure(total_floors, nodes_per_floor)
	
	var canvas_height: float = total_sections * SECTION_HEIGHT
	custom_minimum_size = Vector2(SECTION_WIDTH, canvas_height)
	
	_draw_map_on_canvas(canvas_height)
	
	btn_up.pressed.connect(_on_btn_up_pressed)
	btn_down.pressed.connect(_on_btn_down_pressed)
	
	current_view_section = GameManager.current_floor / 5
	current_view_section = clampi(current_view_section, 0, total_sections - 1)
	
	await get_tree().process_frame
	var target_scroll = (total_sections - 1 - current_view_section) * SECTION_HEIGHT
	scroll_container.scroll_vertical = int(target_scroll)
	
	_update_navigation_buttons()

func _apply_debug_starting_section() -> void:
	if not GameManager.is_map_generated and test_starting_section > 0:
		var target_floor: int = test_starting_section * 5
		target_floor = clampi(target_floor, 0, total_floors - 1)
		
		GameManager.current_floor = target_floor
		print("[DEBUG] Teleportasi awal diaktifkan! Memulai dari Section %d (Lantai %d)" % [test_starting_section, target_floor])

func _draw_map_on_canvas(canvas_max_y: float) -> void:
	for child in get_children():
		child.queue_free()
		
	var matrix: Dictionary = GameManager.map_data_matrix
	var total_sections: int = total_floors / 5
	
	for section_idx in range(total_sections):
		var bg_rect = TextureRect.new()
		bg_rect.custom_minimum_size = Vector2(SECTION_WIDTH, SECTION_HEIGHT)
		bg_rect.size = Vector2(SECTION_WIDTH, SECTION_HEIGHT)
		
		if section_idx < section_wallpapers.size() and section_wallpapers[section_idx] != null:
			bg_rect.texture = section_wallpapers[section_idx]
			bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		else:
			var fallback_colors = [Color(0.1, 0.15, 0.2), Color(0.2, 0.1, 0.1), Color(0.15, 0.05, 0.2)]
			var color_bg = ColorRect.new()
			color_bg.color = fallback_colors[section_idx % 3]
			color_bg.set_anchors_preset(PRESET_FULL_RECT)
			bg_rect.add_child(color_bg)
			
		var y_pos = canvas_max_y - ((section_idx + 1) * SECTION_HEIGHT)
		bg_rect.position = Vector2(0, y_pos)
		
		add_child(bg_rect)
		
	var node_positions: Dictionary = {} 
	var spacing_y: float = SECTION_HEIGHT / 4.8
	var bottom_padding: float = spacing_y / 2.0 
	
	for floor_idx in matrix:
		var nodes_in_floor: Array = matrix[floor_idx]
		var floor_width: float = (nodes_in_floor.size() - 1) * spacing_x
		var start_x: float = (SECTION_WIDTH / 2.0) - (floor_width / 2.0)
		
		for node_idx in range(nodes_in_floor.size()):
			var data: MapNodeData = nodes_in_floor[node_idx]
			var pos_x: float = start_x + (node_idx * spacing_x)
			var pos_y: float = canvas_max_y - bottom_padding - (floor_idx * spacing_y)
			node_positions[data.grid_position] = Vector2(pos_x, pos_y)

	var center_offset := Vector2(40.0, 40.0) 
	
	for floor_idx in matrix:
		for node_data: MapNodeData in matrix[floor_idx]:
			var start_grid_pos: Vector2i = node_data.grid_position
			var start_pos: Vector2 = node_positions[start_grid_pos]
			
			for target_grid_pos in node_data.next_connections:
				if node_positions.has(target_grid_pos):
					var end_pos: Vector2 = node_positions[target_grid_pos]
					
					var line = Line2D.new()
					line.add_point(start_pos + center_offset)
					line.add_point(end_pos + center_offset)
					line.width = 4.0
					line.default_color = Color(0.4, 0.4, 0.4, 0.5) 
					
					if GameManager.history_path.has(start_grid_pos) and GameManager.history_path.has(target_grid_pos):
						line.default_color = Color(0.8, 0.8, 0.2, 0.8)
					
					add_child(line)

	for floor_idx in matrix:
		var nodes_in_floor: Array = matrix[floor_idx]
		
		for node_data: MapNodeData in nodes_in_floor:
			var visual_node = map_node_scene.instantiate() as MapNodeVisual
			add_child(visual_node)
			var is_accessible: bool = false
			
			if floor_idx == GameManager.current_floor:
				if GameManager.current_floor == 0 or GameManager.available_paths.is_empty():
					is_accessible = true
				else:
					is_accessible = GameManager.available_paths.has(node_data.grid_position)
			
			visual_node.setup_node(node_data, is_accessible)
			visual_node.position = node_positions[node_data.grid_position]
			visual_node.node_clicked.connect(_on_node_selected)

func _on_node_selected(node_data: MapNodeData) -> void:
	GameManager.history_path.append(node_data.grid_position)
	GameManager.available_paths = node_data.next_connections
	GameManager.current_floor += 1
	GameManager.active_event_type = node_data.type
	
	if is_ujicoba and test_enemy != null:
		print("[TEST MODE] Memulai pertempuran uji coba melawan: ", test_enemy.enemy_name)
		GameManager.current_wave_data = [test_enemy]
		get_tree().change_scene_to_file("res://main/battle_scene.tscn")
		return

	match node_data.type:
		MapNodeData.NodeType.REST, MapNodeData.NodeType.SHOP:
			print("Singgah di fasilitas damai. Melanjutkan langsung ke lantai berikutnya...")
			GameManager.active_event_type = node_data.type
			get_tree().change_scene_to_file("res://event/event_scene.tscn")
		MapNodeData.NodeType.BATTLE_NORMAL, MapNodeData.NodeType.BATTLE_HARD, MapNodeData.NodeType.BOSS:
			GameManager.current_wave_data = node_data.wave_data
			get_tree().change_scene_to_file("res://main/battle_scene.tscn")

func _on_btn_up_pressed() -> void:
	if current_view_section < total_sections - 1:
		current_view_section += 1
		_animate_to_current_section()

func _on_btn_down_pressed() -> void:
	if current_view_section > 0:
		current_view_section -= 1
		_animate_to_current_section()

func _animate_to_current_section() -> void:
	_update_navigation_buttons()
	var target_scroll: float = (total_sections - 1 - current_view_section) * SECTION_HEIGHT
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll_container, "scroll_vertical", int(target_scroll), 0.6)

func _update_navigation_buttons() -> void:
	btn_up.visible = (current_view_section < total_sections - 1)
	btn_down.visible = (current_view_section > 0)
