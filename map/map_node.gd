class_name MapNodeVisual
extends TextureButton

signal node_clicked(node_data: MapNodeData)

var data: MapNodeData

@export_group("Node Textures")
@export var tex_battle_normal: Texture2D
@export var tex_battle_hard: Texture2D
@export var tex_shop: Texture2D
@export var tex_rest: Texture2D
@export var tex_boss: Texture2D
@export var tex_random_event: Texture2D

@export_group("Node Size")
@export var node_size: float = 90.0

var scale_tween: Tween
var wobble_tween: Tween


func _ready() -> void:
	# Pastikan TextureButton menerima klik
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)

	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


func setup_node(
	node_data: MapNodeData,
	is_accessible: bool
) -> void:

	data = node_data

	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	custom_minimum_size = Vector2(
		node_size,
		node_size
	)

	size = Vector2(
		node_size,
		node_size
	)

	pivot_offset = size / 2.0

	# Reset texture terlebih dahulu
	texture_normal = null
	texture_hover = null
	texture_pressed = null
	texture_disabled = null

	match data.type:

		MapNodeData.NodeType.BATTLE_NORMAL:
			texture_normal = tex_battle_normal

		MapNodeData.NodeType.BATTLE_HARD:
			texture_normal = tex_battle_hard

		MapNodeData.NodeType.SHOP:
			texture_normal = tex_shop

		MapNodeData.NodeType.REST:
			texture_normal = tex_rest

		MapNodeData.NodeType.BOSS:
			texture_normal = tex_boss

		MapNodeData.NodeType.RANDOM_EVENT:
			texture_normal = tex_random_event

	# Accessibility
	disabled = not is_accessible

	if is_accessible:
		modulate.a = 1.0
	else:
		modulate.a = 0.25


func _on_mouse_entered() -> void:

	if disabled:
		return

	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()

	if wobble_tween and wobble_tween.is_valid():
		wobble_tween.kill()

	scale_tween = create_tween()

	scale_tween.tween_property(
		self,
		"scale",
		Vector2(1.15, 1.15),
		0.15
	).set_trans(Tween.TRANS_BACK)

	wobble_tween = create_tween()
	wobble_tween.set_loops()

	wobble_tween.tween_property(
		self,
		"rotation_degrees",
		5.0,
		0.15
	)

	wobble_tween.tween_property(
		self,
		"rotation_degrees",
		-5.0,
		0.15
	)


func _on_mouse_exited() -> void:

	if disabled:
		return

	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()

	if wobble_tween and wobble_tween.is_valid():
		wobble_tween.kill()

	var reset_tween := create_tween()
	reset_tween.set_parallel(true)

	reset_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.15
	)

	reset_tween.tween_property(
		self,
		"rotation_degrees",
		0.0,
		0.15
	)


func _on_pressed() -> void:

	if data == null:
		return

	node_clicked.emit(data)