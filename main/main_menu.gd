extends Node2D

@onready var global_click_sfx: AudioStreamPlayer = $GlobalClickSFX
@onready var background: TextureRect = $bg
@onready var tombol_list: Array = [
	$Play,
	$Collection,
	$Settings,
	$Credit,
	$Quit
]
const MAP_SCENE_PATH := "res://map/map_scene.tscn"

func _ready() -> void:
	SoundManager.play_bgm("main_menu")
	background.pivot_offset = background.size / 2
	background.scale = Vector2(1.2, 1.2)
	
	$Play.pressed.connect(_on_play_pressed)

	for btn in tombol_list:
		btn.modulate.a = 0.0
		btn.scale = Vector2(0, 0)
		btn.pivot_offset = btn.size / 2

	var intro_tween = create_tween().set_parallel(false)
	intro_tween.tween_property(background, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_interval(0.2)
	
	for btn in tombol_list:
		var btn_tween = create_tween().set_parallel(true)
		btn_tween.tween_property(btn, "modulate:a", 1.0, 0.3)
		btn_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.12).timeout

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if global_click_sfx and not global_click_sfx.playing:
			global_click_sfx.play()

func _on_play_pressed() -> void:
	if global_click_sfx:
		global_click_sfx.play()

	# Cegah tombol dipencet berkali-kali
	for btn in tombol_list:
		btn.disabled = true

	# Fade out seluruh menu
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)

	for btn in tombol_list:
		fade_tween.tween_property(
			btn,
			"modulate:a",
			0.0,
			0.25
		)

	fade_tween.tween_property(
		background,
		"modulate:a",
		0.0,
		0.35
	)

	await fade_tween.finished

	GameManager.start_new_run()

	get_tree().change_scene_to_file(MAP_SCENE_PATH)
