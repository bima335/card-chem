extends Control

@onready var play_button: Button = $MenuButton/PlayButton
@onready var option_button: Button = $MenuButton/OptionButton
@onready var press_any: Control = $Transition/PressAny
@onready var menu_button: VBoxContainer = $MenuButton
@onready var title: Label = $TitleLabel


var node: Button

func _ready() -> void:
	# Menghubungkan klik tombol ke fungsi transisi
	play_button.pressed.connect(_on_play_button_pressed)

func _process(delta: float) -> void:
	if press_any.visible == true:
		if Input.is_anything_pressed():
			press_any.visible = false
			$AnimationPlayer.play("menu_button")
			#menu_button.visible = true
			#menu_transition()
			#pop_int_style(play_button)

func pop_int_style(button: int):
	match button:
		0:
			node = play_button
		1:
			node = option_button
	node.visible = true
	#node.scale = Vector2.ZERO
	node.modulate.a = 0.0
	
	var tween = create_tween()
	#tween.set_parallel(true)
	#tween.tween_property(node, "scale", Vector2(1,1), .6) \
	#.set_trans(Tween.TRANS_ELASTIC) \
	#.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(node, "modulate:a", 1.0, .4)

func menu_transition():
	title.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 1.0)

func _on_play_button_pressed() -> void:
	print("Memasuki pertempuran...")
	# Fungsi bawaan Godot untuk berpindah scene secara otomatis
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
