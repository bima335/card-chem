extends Node

# Export variabel untuk menampung referensi scene viewer
@export var card_viewer_scene: PackedScene

func _ready() -> void:
	if card_viewer_scene == null:
		push_error("ViewerManager: card_viewer_scene belum diisi di Inspector!")