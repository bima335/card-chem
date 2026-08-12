class_name BlessingUIItem
extends TextureRect

signal clicked(blessing_data: BlessingData)

var blessing_data: BlessingData

func _ready() -> void:
	custom_minimum_size = Vector2(100, 100)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func setup(data: BlessingData) -> void:
	blessing_data = data
	if blessing_data:
		texture = blessing_data.icon


func set_visual_color(color: Color) -> void:
	self_modulate = color


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(blessing_data)
