class_name AuraCardUI
extends TextureButton

signal aura_selected(aura_data: AuraCardData)

var aura_data: AuraCardData

func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

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
