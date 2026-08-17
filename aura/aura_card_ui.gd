class_name AuraCardUI
extends TextureButton

signal aura_selected(aura_data: AuraCardData)

var aura_data: AuraCardData
var is_preview: bool = false

var hover_tween: Tween

@export var hover_scale: Vector2 = Vector2(1.12, 1.12)
@export var animation_duration: float = 0.18

@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var name_label: Label = $TooltipPanel/VBoxContainer/Name
@onready var description_label: Label = $TooltipPanel/VBoxContainer/Description


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
		
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if tooltip_panel:
		tooltip_panel.hide()


func setup(data: AuraCardData) -> void:
	aura_data = data
	
	if aura_data and aura_data.icon:
		texture_normal = aura_data.icon
	
	pivot_offset = custom_minimum_size / 2.0
	_setup_tooltip_text()


func set_visual_color(color: Color) -> void:
	modulate = color


func _setup_tooltip_text() -> void:
	if not aura_data:
		return
		
	if name_label:
		name_label.text = aura_data.name
		
	if description_label:
		if not aura_data.description.is_empty():
			description_label.text = aura_data.description
			description_label.show()
		else:
			description_label.text = ""
			description_label.hide()


func _on_mouse_entered() -> void:
	z_index = 100
	_animate_scale(hover_scale)
	_show_tooltip()


func _on_mouse_exited() -> void:
	z_index = 0
	_animate_scale(Vector2.ONE)
	_hide_tooltip()


func _animate_scale(target_scale: Vector2) -> void:
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween().bind_node(self)
	hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "scale", target_scale, animation_duration)


func _show_tooltip() -> void:
	if not tooltip_panel:
		return

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

	var viewport_rect: Rect2 = get_viewport_rect()
	var margin: float = 16.0

	target_x = clampf(target_x, margin, viewport_rect.size.x - tooltip_panel.size.x - margin)
	
	if target_y < margin:
		var card_bottom_y: float = global_position.y + (size.y * scale.y)
		target_y = card_bottom_y + 20.0

	tooltip_panel.global_position = Vector2(target_x, target_y)
	tooltip_panel.modulate.a = 0.0

	var fade_tween := create_tween().bind_node(self)
	fade_tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.15)

func _hide_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.hide()


func _on_pressed() -> void:
	if aura_data:
		aura_selected.emit(aura_data)
