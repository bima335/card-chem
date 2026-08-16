class_name AuraCardUI
extends TextureButton

const CARD_DETAIL_VIEWER_SCENE = preload("res://ui/card_detail_viewer.tscn")

signal aura_selected(aura_data: AuraCardData)

var aura_data: AuraCardData

func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	gui_input.connect(_on_gui_input)

func setup(data: AuraCardData) -> void:
	aura_data = data
	
	if aura_data and aura_data.icon:
		texture_normal = aura_data.icon
	
	if aura_data:
		tooltip_text = aura_data.description

func set_visual_color(color: Color) -> void:
	self.modulate = color

func _on_pressed() -> void:
	if aura_data:
		aura_selected.emit(aura_data)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_open_card_viewer()

func _open_card_viewer() -> void:
	if aura_data == null: return
	
	var viewer = CARD_DETAIL_VIEWER_SCENE.instantiate()
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(viewer)
	get_tree().root.add_child(canvas_layer)
	
	viewer.setup(aura_data)