class_name PauseMenu
extends PanelContainer

@export_file("*.tscn") var main_menu_scene_path: String = "res://main/main_menu.tscn"

@onready var resume_button: TextureButton = $CenterContainer/VBoxContainer/ResumeButton
@onready var main_menu_button: TextureButton = $CenterContainer/VBoxContainer/MainMenuButton
@onready var dark_overlay: ColorRect = $DarkOverlay

const HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const NORMAL_SCALE: Vector2 = Vector2.ONE
const TWEEN_DURATION: float = 0.15

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	_setup_button_effects(resume_button)
	_setup_button_effects(main_menu_button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if visible:
		resume()
	else:
		pause()

func pause() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()
	_animate_menu_open()

func resume() -> void:
	get_tree().paused = false
	visible = false

func _animate_menu_open() -> void:
	modulate.a = 0.0
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _setup_button_effects(button: TextureButton) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
	button.pivot_offset = button.size / 2.0
	
	button.mouse_entered.connect(_on_button_hover_entered.bind(button))
	button.mouse_exited.connect(_on_button_hover_exited.bind(button))
	button.focus_entered.connect(_on_button_hover_entered.bind(button))
	button.focus_exited.connect(_on_button_hover_exited.bind(button))

func _on_button_hover_entered(button: TextureButton) -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(button, "scale", HOVER_SCALE, TWEEN_DURATION)
	tween.parallel().tween_property(button, "modulate", Color(1.15, 1.15, 1.15, 1.0), TWEEN_DURATION)

func _on_button_hover_exited(button: TextureButton) -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(button, "scale", NORMAL_SCALE, TWEEN_DURATION)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, TWEEN_DURATION)

func _on_resume_button_pressed() -> void:
	resume()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		push_error("PauseMenu: Path scene main menu tidak valid: " + main_menu_scene_path)
