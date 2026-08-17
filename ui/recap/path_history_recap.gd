class_name PathHistoryRecap
extends Control

@export_group("Layout Configuration")
@export var first_row_count: int = 10
@export var icon_size: Vector2 = Vector2(56.0, 56.0)
@export var horizontal_spacing: float = 38.0
@export var row_vertical_spacing: float = 65.0

@export_group("Line & Arrow Style")
@export var line_color: Color = Color(0.9, 0.75, 0.2, 0.9)
@export var line_width: float = 3.0
@export var arrow_size: float = 8.0

@export_group("Node Type Icons")
@export var tex_battle_normal: Texture2D
@export var tex_battle_hard: Texture2D
@export var tex_shop: Texture2D
@export var tex_rest: Texture2D
@export var tex_boss: Texture2D
@export var tex_random_event: Texture2D

@export_group("Debug / Testing")
@export var use_dummy_data: bool = true

var _node_centers: Array[Vector2] = []
var _resolved_node_types: Array[MapNodeData.NodeType] = []


func _ready() -> void:
	if use_dummy_data:
		_load_dummy_data()
	else:
		load_history_from_game_manager()


func _draw() -> void:
	if _node_centers.size() < 2:
		return

	var half_icon_extent: float = icon_size.x * 0.5

	for i in range(_node_centers.size() - 1):
		var start_pt: Vector2 = _node_centers[i]
		var end_pt: Vector2 = _node_centers[i + 1]

		var is_row_transition: bool = (i == first_row_count - 1)

		if is_row_transition:
			_draw_row_transition_line(start_pt, end_pt, half_icon_extent)
		else:
			_draw_horizontal_connection(start_pt, end_pt, half_icon_extent)


func load_history_from_game_manager() -> void:
	_resolved_node_types.clear()

	var history: Array[Vector2i] = GameManager.history_path
	var matrix: Dictionary = GameManager.map_data_matrix

	for grid_pos in history:
		var floor_idx: int = grid_pos.x
		var node_idx: int = grid_pos.y

		if matrix.has(floor_idx):
			var nodes_in_floor: Array = matrix[floor_idx]
			if node_idx >= 0 and node_idx < nodes_in_floor.size():
				var node_data: MapNodeData = nodes_in_floor[node_idx]
				_resolved_node_types.append(node_data.type)

	build_visuals()


func set_custom_history_data(types: Array[MapNodeData.NodeType]) -> void:
	_resolved_node_types = types.duplicate()
	build_visuals()


func build_visuals() -> void:
	for child in get_children():
		child.queue_free()

	_node_centers.clear()

	if _resolved_node_types.is_empty():
		queue_redraw()
		return

	var total_items: int = _resolved_node_types.size()
	var row1_items: int = mini(first_row_count, total_items)
	var row2_items: int = maxi(0, total_items - first_row_count)

	var total_w_row1: float = (row1_items * icon_size.x) + (maxi(0, row1_items - 1) * horizontal_spacing)
	var total_h: float = (icon_size.y * 2.0) + row_vertical_spacing

	custom_minimum_size = Vector2(total_w_row1, total_h)

	for i in range(total_items):
		var is_first_row: bool = (i < first_row_count)
		var col_idx: int = i if is_first_row else (i - first_row_count)
		var row_idx: int = 0 if is_first_row else 1

		var pos_x: float = col_idx * (icon_size.x + horizontal_spacing)
		var pos_y: float = row_idx * (icon_size.y + row_vertical_spacing)

		var center: Vector2 = Vector2(pos_x + (icon_size.x * 0.5), pos_y + (icon_size.y * 0.5))
		_node_centers.append(center)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = icon_size
		icon_rect.size = icon_size
		icon_rect.position = Vector2(pos_x, pos_y)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.texture = _get_texture_for_type(_resolved_node_types[i])

		add_child(icon_rect)

	queue_redraw()


func _load_dummy_data() -> void:
	var dummy_sequence: Array[MapNodeData.NodeType] = [
		MapNodeData.NodeType.BATTLE_NORMAL,
		MapNodeData.NodeType.RANDOM_EVENT,
		MapNodeData.NodeType.SHOP,
		MapNodeData.NodeType.BATTLE_HARD,
		MapNodeData.NodeType.BOSS,
		MapNodeData.NodeType.BATTLE_NORMAL,
		MapNodeData.NodeType.REST,
		MapNodeData.NodeType.SHOP,
		MapNodeData.NodeType.BATTLE_HARD,
		MapNodeData.NodeType.BOSS,
		MapNodeData.NodeType.BATTLE_NORMAL,
		MapNodeData.NodeType.RANDOM_EVENT,
		MapNodeData.NodeType.SHOP,
		MapNodeData.NodeType.REST,
		MapNodeData.NodeType.BOSS
	]
	set_custom_history_data(dummy_sequence)


func _get_texture_for_type(node_type: MapNodeData.NodeType) -> Texture2D:
	match node_type:
		MapNodeData.NodeType.BATTLE_NORMAL:
			return tex_battle_normal
		MapNodeData.NodeType.BATTLE_HARD:
			return tex_battle_hard
		MapNodeData.NodeType.SHOP:
			return tex_shop
		MapNodeData.NodeType.REST:
			return tex_rest
		MapNodeData.NodeType.BOSS:
			return tex_boss
		MapNodeData.NodeType.RANDOM_EVENT:
			return tex_random_event
		_:
			return tex_battle_normal


func _draw_horizontal_connection(start_pt: Vector2, end_pt: Vector2, half_size: float) -> void:
	var line_start: Vector2 = start_pt + Vector2(half_size + 4.0, 0.0)
	var line_end: Vector2 = end_pt - Vector2(half_size + 4.0, 0.0)

	if line_start.x >= line_end.x:
		return

	draw_line(line_start, line_end, line_color, line_width, true)
	_draw_arrow_head(line_end, Vector2.RIGHT)


func _draw_row_transition_line(start_pt: Vector2, end_pt: Vector2, half_size: float) -> void:
	var p1: Vector2 = start_pt + Vector2(0.0, half_size + 4.0)
	var mid_y: float = (start_pt.y + end_pt.y) * 0.5
	var p2: Vector2 = Vector2(start_pt.x, mid_y)
	var p3: Vector2 = Vector2(end_pt.x, mid_y)
	var p4: Vector2 = end_pt - Vector2(0.0, half_size + 4.0)

	draw_polyline(PackedVector2Array([p1, p2, p3, p4]), line_color, line_width, true)
	_draw_arrow_head(p4, Vector2.DOWN)


func _draw_arrow_head(tip: Vector2, direction: Vector2) -> void:
	var norm_dir: Vector2 = direction.normalized()
	var perp_dir: Vector2 = Vector2(-norm_dir.y, norm_dir.x)

	var p1: Vector2 = tip - (norm_dir * arrow_size) + (perp_dir * (arrow_size * 0.6))
	var p2: Vector2 = tip - (norm_dir * arrow_size) - (perp_dir * (arrow_size * 0.6))

	draw_colored_polygon(PackedVector2Array([tip, p1, p2]), line_color)
