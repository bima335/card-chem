extends Node2D

@onready var logo = $logo

func _ready():
	logo.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 1.5)
	tween.tween_interval(2.0)
	tween.tween_property(logo, "modulate:a", 0.0, 1.5)
	tween.tween_callback(pindah_ke_intro)

func pindah_ke_intro():
	get_tree().change_scene_to_file("res://cutscene/intro.tscn")