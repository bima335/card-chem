extends TextureButton

@onready var ukuran_asal: Vector2 = scale
@onready var audio_hover: AudioStreamPlayer = $AudioHover

func _ready() -> void:
	pivot_offset = size / 2

func _on_mouse_entered() -> void:
	if audio_hover and not audio_hover.playing:
		audio_hover.play()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", ukuran_asal * 1.08, 0.15)
	tween.tween_property(self, "modulate", Color(1.3, 1.2, 0.9, 1.0), 0.15)

func _on_mouse_exited() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", ukuran_asal, 0.15)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
