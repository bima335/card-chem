class_name CardUI
extends TextureButton

const CARD_DETAIL_VIEWER_SCENE = preload("res://ui/card_detail_viewer.tscn")

@export var card_viewer_scene: PackedScene

signal drag_started(card_ui: CardUI)
signal drag_ended(card_ui: CardUI, drop_position: Vector2)

var data: CardData
var is_preview: bool = false
var is_dragging: bool = false
var is_returning: bool = false
var drag_preview_ref: TextureRect = null

var drag_offset: Vector2 = Vector2.ZERO
var home_global_position: Vector2 = Vector2.ZERO

# Posisi & rotasi "istirahat" kartu di dalam formasi kipas tangan.
# Diisi oleh BattleUIManager.arrange_hand(), dipakai sebagai baseline hover/return.
var hand_position: Vector2 = Vector2.ZERO
var hand_rotation: float = 0.0
var hand_z_index: int = 0

var hover_tween: Tween
var return_tween: Tween

@export var hover_scale: Vector2 = Vector2(1.15, 1.15)
@export var hover_rotation_degrees: float = 3.0
@export var hover_lift: float = 55.0
@export var animation_duration: float = 0.25

@onready var name_label: Label = $TooltipPanel/VBoxContainer/Name
@onready var cost_label: Label = $TooltipPanel/VBoxContainer/Cost
@onready var description_label: Label = $TooltipPanel/VBoxContainer/Description
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var coat_icon: TextureRect = $CoatIcon

var tooltip_tween: Tween
func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	if tooltip_panel:
		tooltip_panel.hide()
		
	_setup_tooltip_text()
	tooltip_panel.hide() 

func setup(card_data: CardData) -> void:
	data = card_data
	texture_normal = data.card_texture
	if texture_normal:
		pivot_offset = custom_minimum_size / 2.0
		
	if data:
		modulate = data.modulate
		_update_coat_visual()
		
	_setup_tooltip_text()


func _update_coat_visual() -> void:
	if not coat_icon:
		return

	if data and data.coat_data and data.coat_data.icon:
		coat_icon.texture = data.coat_data.icon
		coat_icon.show()
	else:
		coat_icon.texture = null
		coat_icon.hide()


func set_visual_color(color_tint: Color) -> void:
	if data:
		modulate = data.modulate * color_tint
	else:
		modulate = color_tint


func _setup_tooltip_text() -> void:
	if not data:
		return
		
	var target_name_label: Label = _get_name_label()
	var target_cost_label: Label = _get_cost_label()
	var target_desc_label: Label = _get_description_label()
	
	if target_name_label:
		target_name_label.text = data.card_name
		
	if target_cost_label:
		var cost_parts: Array[String] = []
		
		_append_cost_info(cost_parts, "C", CardData.CostType.CARBON)
		_append_cost_info(cost_parts, "H", CardData.CostType.HYDROGEN)
		_append_cost_info(cost_parts, "O", CardData.CostType.OXYGEN)
		_append_cost_info(cost_parts, "N", CardData.CostType.NITROGEN)
		
		var cost_string: String = " ".join(cost_parts)
		if cost_string.is_empty():
			cost_string = "Gratis!"
			
		target_cost_label.text = cost_string.strip_edges()

	if target_desc_label:
		if not data.description.is_empty():
			target_desc_label.text = data.description
			target_desc_label.show()
		else:
			target_desc_label.text = ""
			target_desc_label.hide()


func _append_cost_info(parts_array: Array[String], symbol: String, type: CardData.CostType) -> void:
	var base_cost: int = 0
	
	match type:
		CardData.CostType.CARBON:
			base_cost = data.cost_carbon
		CardData.CostType.HYDROGEN:
			base_cost = data.cost_hydrogen
		CardData.CostType.OXYGEN:
			base_cost = data.cost_oxygen
		CardData.CostType.NITROGEN:
			base_cost = data.cost_nitrogen

	if base_cost <= 0:
		return
		
	if data.catalyst_reduced_type == type:
		var reduced_cost: int = data.get_effective_cost(type)
		parts_array.append("%s: %d (-1 From Catalyst)" % [symbol, reduced_cost])
	else:
		parts_array.append("%s: %d" % [symbol, base_cost])


func _get_name_label() -> Label:
	if name_label:
		return name_label
	if has_node("TooltipPanel/VBoxContainer/Name"):
		return get_node("TooltipPanel/VBoxContainer/Name") as Label
	return null


func _get_cost_label() -> Label:
	if cost_label:
		return cost_label
	if has_node("TooltipPanel/VBoxContainer/Cost"):
		return get_node("TooltipPanel/VBoxContainer/Cost") as Label
	return null


func _get_description_label() -> Label:
	if description_label:
		return description_label
	if has_node("TooltipPanel/VBoxContainer/Description"):
		return get_node("TooltipPanel/VBoxContainer/Description") as Label
	return null

func _start_drag() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or is_returning:
		return

	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()

	# Simpan posisi awal
	home_global_position = global_position
	drag_offset = get_global_mouse_position() - global_position

	# 1. Buat kartu tiruan (preview) yang akan mengikuti mouse
	var preview = TextureRect.new()
	preview.texture = texture_normal       # Pakai gambar kartu yang sama
	preview.custom_minimum_size = custom_minimum_size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.pivot_offset = size / 2.0
	
	# 2. Tempelkan tiruan ke lapisan UI paling atas (CanvasLayer)
	var ui_root = get_tree().get_first_node_in_group("ui_layer")
	if ui_root == null:
		var temp_layer = CanvasLayer.new()
		temp_layer.layer = 100
		get_tree().root.add_child(temp_layer)
		ui_root = temp_layer
		
	ui_root.add_child(preview)
	preview.global_position = get_global_mouse_position() - drag_offset
	preview.z_index = 999 # Agar selalu di atas segalanya
	
	# Simpan referensi tiruan
	drag_preview_ref = preview

	# 3. Sembunyikan kartu asli di tangan
	visible = false
	is_dragging = true
	z_index = 0
	if tooltip_panel:
		tooltip_panel.hide()
	
	drag_started.emit(self)

func _on_gui_input(event: InputEvent) -> void:
	if is_preview or is_returning:
		return

	if event is InputEventMouseButton:
		# Logika untuk Drag & Drop (Klik Kiri)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			else:
				_stop_drag()
		
		# Logika untuk Buka Detail Viewer (Klik Kanan)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_open_card_viewer()

func _stop_drag() -> void:
	if not is_dragging:
		return
		
	is_dragging = false
	
	var drop_pos = Vector2.ZERO
	
	# Hapus kartu tiruan dan ambil posisi terakhirnya
	if drag_preview_ref != null and is_instance_valid(drag_preview_ref):
		drop_pos = drag_preview_ref.global_position
		drag_preview_ref.queue_free()
		drag_preview_ref = null
	
	# Munculkan kembali kartu asli
	visible = true
	z_index = hand_z_index
	
	drag_ended.emit(self, drop_pos)


func return_to_hand() -> void:
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
		
	is_dragging = false  # Hentikan tracking mouse di _process
	is_returning = true
	mouse_filter = MOUSE_FILTER_IGNORE
	if tooltip_panel:
		tooltip_panel.hide()

	if return_tween and return_tween.is_valid():
		return_tween.kill()

	# 1. Selalu paksa reparent ke hand_container, meskipun dia sudah ada di dalamnya
	var hand_container = get_tree().get_first_node_in_group("hand_container")
	if hand_container != null:
		# PENTING: pindahkan dan set posisi home secara langsung
		reparent(hand_container, true) 
		global_position = home_global_position 

	scale = Vector2.ONE
	rotation = hand_rotation

	return_tween = create_tween().set_parallel(true)
	return_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return_tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	return_tween.tween_property(self, "rotation", hand_rotation, 0.18)

	return_tween.finished.connect(func():
		if not is_instance_valid(self) or is_queued_for_deletion():
			return
			
		mouse_filter = MOUSE_FILTER_STOP
		is_returning = false
		
		var battle_ui = get_tree().get_first_node_in_group("battle_ui_manager")
		if battle_ui and battle_ui.has_method("arrange_hand"):
			battle_ui.arrange_hand()
	)

func _on_mouse_entered() -> void:
	if is_dragging or is_returning:
		return
	
	if hand_position == Vector2.ZERO:
		return

	SoundManager.play_sfx("card_hover")
	z_index = 999

	if is_preview:
		_animate_preview_scale(Vector2(1.15, 1.15))
	else:
		var random_dir: float = 1.0 if randf() > 0.5 else -1.0
		var target_rot: float = hand_rotation + deg_to_rad(hover_rotation_degrees) * random_dir
		var target_pos: Vector2 = hand_position + Vector2(0, -hover_lift)
		_animate_hover(hover_scale, target_rot, target_pos)

	_show_tooltip_panel()


func _on_mouse_exited() -> void:
	if is_dragging or is_returning:
		return
		
	if is_preview:
		z_index = 0
		_animate_preview_scale(Vector2.ONE)
	else:
		z_index = hand_z_index
		_animate_hover(Vector2.ONE, hand_rotation, hand_position)
		
	_hide_tooltip_panel()

func _animate_preview_scale(target_scale: Vector2) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween().bind_node(self)
	hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "scale", target_scale, animation_duration)

func _show_tooltip_panel() -> void:
	if not tooltip_panel:
		return

	if tooltip_tween and tooltip_tween.is_valid():
		tooltip_tween.kill()

	tooltip_panel.modulate.a = 0.0
	tooltip_panel.show()
	tooltip_panel.reset_size()

	await get_tree().process_frame
	if not is_instance_valid(self) or not tooltip_panel.visible:
		return

	tooltip_panel.z_index = 1000

	var card_center_x: float = global_position.x + (size.x / 2.0)
	var card_top_y: float = global_position.y - ((size.y * (scale.y - 1.0)) / 2.0)

	var target_x: float = card_center_x - (tooltip_panel.size.x / 2.0)
	var target_y: float = card_top_y - tooltip_panel.size.y - 20.0

	tooltip_panel.global_position = Vector2(target_x, target_y)

	tooltip_tween = create_tween().bind_node(self)
	tooltip_tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.15)


func _hide_tooltip_panel() -> void:
	if tooltip_tween and tooltip_tween.is_valid():
		tooltip_tween.kill()
		
	if tooltip_panel:
		tooltip_panel.hide()

func _animate_hover(target_scale: Vector2, target_rotation: float, target_position: Vector2) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", target_scale, animation_duration)
	hover_tween.tween_property(self, "rotation", target_rotation, animation_duration)
	hover_tween.tween_property(self, "position", target_position, animation_duration)


func _open_card_viewer() -> void:
	if data == null: return
	
	# Pakai preload langsung (lebih aman, tidak perlu setup Inspector)
	var viewer = CARD_DETAIL_VIEWER_SCENE.instantiate()
	
	# Bungkus dengan CanvasLayer agar selalu di atas segalanya
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(viewer)
	get_tree().root.add_child(canvas_layer)
	
	viewer.setup(data)

func _process(delta: float) -> void:
	# 1. Update posisi tiruan mengikuti mouse
	if is_dragging and drag_preview_ref != null and is_instance_valid(drag_preview_ref):
		drag_preview_ref.global_position = get_global_mouse_position() - drag_offset
	
	# 2. DETEKSI GLOBAL: Jika sedang drag dan tombol kiri mouse sudah dilepas
	if is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_drag()
