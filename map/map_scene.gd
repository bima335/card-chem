extends Control # Atau Node2D, sesuaikan dengan tipe root scene kamu

@onready var back_button: TextureButton = $BackButton

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	# Opsional: Mainkan SFX klik
	if SoundManager.has_method("play_sfx"):
		SoundManager.play_sfx("ui_click")
		
	# Kembali ke main menu. Data game tetap tersimpan di SaveManager.
	get_tree().change_scene_to_file("res://main/main_menu.tscn")