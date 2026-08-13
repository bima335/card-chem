class_name MapNodeVisual
extends TextureButton

signal node_clicked(node_data: MapNodeData)

var data: MapNodeData

# --- SLOT GAMBAR (Isi lewat Inspector) ---
@export var tex_battle_normal: Texture2D
@export var tex_battle_hard: Texture2D
@export var tex_shop: Texture2D
@export var tex_rest: Texture2D
@export var tex_boss: Texture2D
@export var tex_random_event: Texture2D # Slot Tekstur Baru

var scale_tween: Tween
var wobble_tween: Tween

func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_node(node_data: MapNodeData, is_accessible: bool) -> void:
	data = node_data
	
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	custom_minimum_size = Vector2(50, 50)
	size = Vector2(50, 50) 
	
	pivot_offset = size / 2.0
	
	match data.type:
		MapNodeData.NodeType.BATTLE_NORMAL: texture_normal = tex_battle_normal
		MapNodeData.NodeType.BATTLE_HARD: texture_normal = tex_battle_hard
		MapNodeData.NodeType.SHOP: texture_normal = tex_shop
		MapNodeData.NodeType.REST: texture_normal = tex_rest
		MapNodeData.NodeType.BOSS: texture_normal = tex_boss
		MapNodeData.NodeType.RANDOM_EVENT: texture_normal = tex_random_event
			
	if is_accessible:
		disabled = false
		modulate.a = 1.0
	else:
		disabled = true
		modulate.a = 0.25

func _on_mouse_entered() -> void:
	if disabled: return 
	if scale_tween and scale_tween.is_valid(): scale_tween.kill()
	if wobble_tween and wobble_tween.is_valid(): wobble_tween.kill()
	
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15).set_trans(Tween.TRANS_BACK)

	wobble_tween = create_tween().set_loops()
	wobble_tween.tween_property(self, "rotation_degrees", 8.0, 0.15)
	wobble_tween.tween_property(self, "rotation_degrees", -8.0, 0.15)

func _on_mouse_exited() -> void:
	if disabled: return
	
	if scale_tween and scale_tween.is_valid(): scale_tween.kill()
	if wobble_tween and wobble_tween.is_valid(): wobble_tween.kill()
	
	var reset_tween = create_tween().set_parallel(true)
	reset_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	reset_tween.tween_property(self, "rotation_degrees", 0.0, 0.15)

func _on_pressed() -> void:
	node_clicked.emit(data)
