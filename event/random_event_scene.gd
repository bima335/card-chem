extends Control

@onready var continue_button: Button = $TextureRect/ContinueButton

func _ready() -> void:
	SoundManager.play_bgm("event")
	continue_button.pressed.connect(_on_continue_button_pressed)

func _on_continue_button_pressed() -> void:
	var random_value: float = randf()
	
	if random_value < 0.5:
		get_tree().change_scene_to_file("res://event/wind_fall.tscn")
	else:
		get_tree().change_scene_to_file("res://event/gold_event.tscn")
