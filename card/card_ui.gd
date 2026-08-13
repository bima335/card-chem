class_name CardUI
extends TextureButton

signal drag_started(card_ui: CardUI)
signal drag_ended(card_ui: CardUI, drop_position: Vector2)

var data: CardData
var is_preview: bool = false
var is_dragging: bool = false
var is_returning: bool = false

var drag_offset: Vector2 = Vector2.ZERO
var home_global_position: Vector2 = Vector2.ZERO

var hover_tween: Tween
var return_tween: Tween

@export var hover_scale: Vector2 = Vector2(1.2, 1.2)
@export var hover_rotation_degrees: float = 3.0
@export var animation_duration: float = 0.25

@onready var name_label: Label = $TooltipPanel/VBoxContainer/Name
@onready var cost_label: Label = $TooltipPanel/VBoxContainer/Cost
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var coat_icon: TextureRect = $CoatIcon


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	_setup_tooltip_text()


func setup(card_data: CardData) -> void:
	data = card_data
	texture_normal = data.card_texture
	if texture_normal:
		pivot_offset = custom_minimum_size / 2.0
		
	if data:
		modulate = data.modulate
		_update_coat_visual() # Update tampilan Coat saat setup
		
	_setup_tooltip_text()


func _update_coat_visual() -> void:
	if not coat_icon:
		return

	# Cek apakah kartu memiliki data coat dan icon
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
		
	var target_name_label = _get_name_label()
	var target_cost_label = _get_cost_label()
	
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


func _on_gui_input(event: InputEvent) -> void:
	if is_preview or is_returning:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_stop_drag()


func _start_drag() -> void:
	if is_returning:
		return

	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()

	scale = Vector2.ONE
	rotation = 0.0

	home_global_position = global_position
	drag_offset = get_global_mouse_position() - global_position
	
	is_dragging = true
	z_index = 100
	if tooltip_panel:
		tooltip_panel.hide()
	
	drag_started.emit(self)


func _stop_drag() -> void:
	if not is_dragging:
		return
		
	is_dragging = false
	z_index = 0
	drag_ended.emit(self, get_global_mouse_position())


func return_to_hand() -> void:
	is_returning = true
	mouse_filter = MOUSE_FILTER_IGNORE
	if tooltip_panel:
		tooltip_panel.hide()

	if return_tween and return_tween.is_valid():
		return_tween.kill()

	return_tween = create_tween().set_parallel(true)
	return_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	return_tween.tween_property(self, "global_position", home_global_position, 0.18)
	return_tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	return_tween.tween_property(self, "rotation", 0.0, 0.18)

	return_tween.finished.connect(func():
		global_position = home_global_position
		mouse_filter = MOUSE_FILTER_STOP
		is_returning = false
	)


func _on_mouse_entered() -> void:
	if is_dragging or is_preview or is_returning:
		return
		
	SoundManager.play_sfx("card_hover")
	z_index = 10 
	
	var random_dir: float = 1.0 if randf() > 0.5 else -1.0
	var target_rot: float = deg_to_rad(hover_rotation_degrees) * random_dir
	_animate_hover(hover_scale, target_rot)

	if tooltip_panel:
		tooltip_panel.show()
		tooltip_panel.reset_size() 
		
		var target_x: float = global_position.x + (size.x / 2.0) - (tooltip_panel.size.x / 2.0)
		var target_y: float = global_position.y - tooltip_panel.size.y - 15.0
		tooltip_panel.global_position = Vector2(target_x, target_y)
		
		tooltip_panel.modulate = Color(1, 1, 1, 0)
		var tween = create_tween().bind_node(self)
		tween.tween_property(tooltip_panel, "modulate", Color.WHITE, 0.15)


func _on_mouse_exited() -> void:
	if is_dragging or is_preview or is_returning:
		return
		
	z_index = 0
	_animate_hover(Vector2.ONE, 0.0) 
	if tooltip_panel:
		tooltip_panel.hide()


func _animate_hover(target_scale: Vector2, target_rotation: float) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", target_scale, animation_duration)
	hover_tween.tween_property(self, "rotation", target_rotation, animation_duration)
