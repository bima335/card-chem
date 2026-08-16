class_name MapManager
extends Control

@export var map_node_scene: PackedScene

@export_group("Map Backgrounds")
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
@export_range(0, 14, 1) var test_starting_floor: int = 0
@export var is_ujicoba: bool = false
@export var test_enemy: EnemyStat
@export var force_first_three_shops: bool = false

const FLOOR_WIDTH: float = 1920.0
const FLOOR_HEIGHT: float = 1080.0

@onready var scroll_container: ScrollContainer = get_parent()
@onready var btn_up: Button = $"../../BtnUp"
@onready var btn_down: Button = $"../../BtnDown"

@export var node_size: float = 200.0 

var current_view_floor: int = 0


func _ready() -> void:
	if scroll_container == null:
		push_error("MapManager: ScrollContainer tidak ditemukan.")
		return

	GameManager.setup_enemy_pools(
		global_common_enemies,
		global_elite_enemies,
		sections_data
	)

	_apply_debug_starting_floor()

	GameManager.generate_new_adventure(
		total_floors,
		nodes_per_floor,
		force_first_three_shops
	)

	var canvas_height: float = total_floors * FLOOR_HEIGHT

	custom_minimum_size = Vector2(
		FLOOR_WIDTH,
		canvas_height
	)

	size = Vector2(
		FLOOR_WIDTH,
		canvas_height
	)

	_draw_map(canvas_height)

	if btn_up != null:
		if not btn_up.pressed.is_connected(_on_btn_up_pressed):
			btn_up.pressed.connect(_on_btn_up_pressed)

	if btn_down != null:
		if not btn_down.pressed.is_connected(_on_btn_down_pressed):
			btn_down.pressed.connect(_on_btn_down_pressed)

	current_view_floor = clampi(
		GameManager.current_floor,
		0,
		total_floors - 1
	)

	await get_tree().process_frame

	_update_scroll_position()
	_update_navigation_buttons()


func _apply_debug_starting_floor() -> void:
	if not GameManager.is_map_generated and test_starting_floor > 0:
		GameManager.current_floor = clampi(
			test_starting_floor,
			0,
			total_floors - 1
		)


func _get_floor_y(
	floor_idx: int,
	canvas_height: float
) -> float:
	return canvas_height - (
		(floor_idx + 1) * FLOOR_HEIGHT
	)


func _get_node_position(
	floor_idx: int,
	node_idx: int,
	canvas_height: float
) -> Vector2:

	var nodes_in_floor: Array = GameManager.map_data_matrix.get(
		floor_idx,
		[]
	)

	var floor_nodes_count: int = nodes_in_floor.size()

	if floor_nodes_count <= 0:
		return Vector2.ZERO

	# Jarak antar node horizontal
	var floor_width: float = (
		(floor_nodes_count - 1) * spacing_x
	)

	# Posisi awal supaya node selalu berada di tengah
	var start_x: float = (
		FLOOR_WIDTH / 2.0
	) - (
		floor_width / 2.0
	)

	var x: float = start_x + (
		node_idx * spacing_x
	)

	# Setiap floor punya tinggi 1080
	var floor_y: float = _get_floor_y(
		floor_idx,
		canvas_height
	)

	# Node diletakkan di tengah area floor
	var y: float = floor_y + (
		FLOOR_HEIGHT / 2.0
	)

	return Vector2(x, y)


func _draw_map(canvas_height: float) -> void:
	var matrix: Dictionary = GameManager.map_data_matrix

	_draw_backgrounds(canvas_height)

	var node_positions: Dictionary = {}

	_build_node_positions(
		matrix,
		canvas_height,
		node_positions
	)

	_draw_connections(
		matrix,
		node_positions
	)

	_draw_nodes(
		matrix,
		node_positions
	)


func _draw_backgrounds(canvas_height: float) -> void:
	var base_bg := TextureRect.new()
	base_bg.position = Vector2(0.0, canvas_height) # Letak tepat di bawah lantai pertama
	base_bg.size = Vector2(FLOOR_WIDTH, FLOOR_HEIGHT)
	base_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_bg.stretch_mode = TextureRect.STRETCH_SCALE
	if section_wallpapers.size() > 0 and section_wallpapers[0] != null:
		base_bg.texture = section_wallpapers[0]
	base_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base_bg)

	for floor_idx in range(total_floors):
		var bg := TextureRect.new()

		bg.position = Vector2(
			0.0,
			_get_floor_y(
				floor_idx,
				canvas_height
			)
		)

		bg.size = Vector2(
			FLOOR_WIDTH,
			FLOOR_HEIGHT
		)

		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE

		var bg_idx: int = floor_idx + 1
		if bg_idx < section_wallpapers.size():
			var texture: Texture2D = section_wallpapers[bg_idx]
			if texture != null:
				bg.texture = texture
				
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

		add_child(bg)


func _build_node_positions(
	matrix: Dictionary,
	canvas_height: float,
	node_positions: Dictionary
) -> void:

	for floor_idx in matrix:
		var nodes_in_floor: Array = matrix[floor_idx]

		for node_idx in range(nodes_in_floor.size()):
			var node_data: MapNodeData = nodes_in_floor[node_idx]

			var position: Vector2 = _get_node_position(
				floor_idx,
				node_idx,
				canvas_height
			)

			node_positions[
				node_data.grid_position
			] = position


func _draw_connections(
	matrix: Dictionary,
	node_positions: Dictionary
) -> void:

	for floor_idx in matrix:
		var nodes_in_floor: Array = matrix[floor_idx]

		for node_data: MapNodeData in nodes_in_floor:
			var start_grid_pos: Vector2i = (
				node_data.grid_position
			)

			if not node_positions.has(start_grid_pos):
				continue

			var start_pos: Vector2 = (
				node_positions[start_grid_pos]
			)

			for target_grid_pos in node_data.next_connections:
				if not node_positions.has(target_grid_pos):
					continue

				var end_pos: Vector2 = (
					node_positions[target_grid_pos]
				)

				var line := Line2D.new()
				line.joint_mode = Line2D.LINE_JOINT_ROUND
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND  # Ganti cap_mode menjadi begin_cap_mode
				line.end_cap_mode = Line2D.LINE_CAP_ROUND    # Tambahkan end_cap_mode

				line.add_point(start_pos)
				line.add_point(end_pos)

				line.width = 5.0

				line.default_color = Color(
					0.4,
					0.4,
					0.4,
					0.6
				)

				if (
					GameManager.history_path.has(
						start_grid_pos
					)
					and
					GameManager.history_path.has(
						target_grid_pos
					)
				):
					line.default_color = Color(
						0.8,
						0.8,
						0.2,
						0.9
					)

				add_child(line)


func _draw_nodes(
	matrix: Dictionary,
	node_positions: Dictionary
) -> void:

	if map_node_scene == null:
		push_error(
			"MapManager: map_node_scene belum diisi."
		)
		return

	for floor_idx in matrix:
		var nodes_in_floor: Array = matrix[floor_idx]

		for node_data: MapNodeData in nodes_in_floor:

			var visual_node := (
				map_node_scene.instantiate()
				as MapNodeVisual
			)

			if visual_node == null:
				push_error(
					"MapManager: map_node_scene bukan MapNodeVisual."
				)
				continue

			add_child(visual_node)

			var is_accessible: bool = false

			if floor_idx == GameManager.current_floor:
				if GameManager.current_floor == 0:
					is_accessible = true
				else:
					is_accessible = (
						GameManager.available_paths.has(
							node_data.grid_position
						)
					)

			visual_node.setup_node(
				node_data,
				is_accessible
			)

			if node_positions.has(node_data.grid_position):
				var center_pos: Vector2 = node_positions[node_data.grid_position]
				# Gunakan variabel node_size yang sudah kita tambahkan tadi
				visual_node.position = center_pos - Vector2(node_size / 2.0, node_size / 2.0)

			if not visual_node.node_clicked.is_connected(
				_on_node_selected
			):
				visual_node.node_clicked.connect(
					_on_node_selected
				)


func _on_node_selected(
	node_data: MapNodeData
) -> void:

	GameManager.history_path.append(
		node_data.grid_position
	)

	GameManager.available_paths = (
		node_data.next_connections
	)

	GameManager.current_floor += 1

	GameManager.active_event_type = node_data.type

	GameManager.update_current_section_for_floor(
		GameManager.current_floor - 1
	)

	if is_ujicoba and test_enemy != null:
		GameManager.current_wave_data = [
			test_enemy
		]

		get_tree().change_scene_to_file(
			"res://main/battle_scene.tscn"
		)

		return

	match node_data.type:

		MapNodeData.NodeType.SHOP:
			get_tree().change_scene_to_file(
				"res://shop/shop_scene.tscn"
			)

		MapNodeData.NodeType.REST:
			get_tree().change_scene_to_file(
				"res://event/event_scene.tscn"
			)

		MapNodeData.NodeType.RANDOM_EVENT:
			get_tree().change_scene_to_file(
				"res://event/random_event_scene.tscn"
			)

		MapNodeData.NodeType.BATTLE_NORMAL, \
		MapNodeData.NodeType.BATTLE_HARD, \
		MapNodeData.NodeType.BOSS:

			GameManager.current_wave_data = (
				node_data.wave_data
			)

			get_tree().change_scene_to_file(
				"res://main/battle_scene.tscn"
			)


func _on_btn_up_pressed() -> void:
	if current_view_floor < total_floors - 1:
		current_view_floor += 1

		_animate_to_current_floor()


func _on_btn_down_pressed() -> void:
	if current_view_floor > 0:
		current_view_floor -= 1

		_animate_to_current_floor()


func _update_scroll_position() -> void:
	var target_scroll: float = (
		total_floors - 1 - current_view_floor
	) * FLOOR_HEIGHT

	scroll_container.scroll_vertical = int(
		target_scroll
	)


func _animate_to_current_floor() -> void:
	_update_navigation_buttons()

	var target_scroll: float = (
		total_floors - 1 - current_view_floor
	) * FLOOR_HEIGHT

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_CUBIC
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		scroll_container,
		"scroll_vertical",
		int(target_scroll),
		0.6
	)


func _update_navigation_buttons() -> void:
	if btn_up != null:
		btn_up.visible = (
			current_view_floor < total_floors - 1
		)

	if btn_down != null:
		btn_down.visible = (
			current_view_floor > 0
		)
