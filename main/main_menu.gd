extends Node2D

const MAP_SCENE_PATH: String = "res://map/map_scene.tscn"

@onready var background: TextureRect = $bg
@onready var play_btn: TextureButton = $Play
@onready var continue_btn: TextureButton = $ContinueButton

@onready var overlay_layer: CanvasLayer = $OverlayLayer
@onready var backdrop: Button = $OverlayLayer/Backdrop
@onready var close_btn: TextureButton = $OverlayLayer/CloseButton

@onready var settings_container: TextureRect = overlay_layer.find_child("SettingsPanel", true, false)
@onready var master_slider: HSlider = settings_container.find_child("MasterSlider", true, false)
@onready var bgm_slider: HSlider = settings_container.find_child("BGMSlider", true, false)
@onready var sfx_slider: HSlider = settings_container.find_child("SFXSliders", true, false)

@onready var credits_container: TextureRect = overlay_layer.find_child("CreditsPanel2", true, false)
@onready var credits_scroll: ScrollContainer = $OverlayLayer/CreditsPanel2/ScrollContainer
@onready var credits_text: RichTextLabel = $OverlayLayer/CreditsPanel2/ScrollContainer/CreditsText

@onready var tombol_list: Array = [
	$Play, $ContinueButton, $Collection, $Settings, $Credit, $Quit
]

func _ready() -> void:
	SoundManager.play_bgm("main_menu")
	_initialize_background()
	_connect_signals()
	_configure_mouse_filters()
	_update_continue_button()
	_overlay_animation(false)
	_play_intro_animation()

func _initialize_background() -> void:
	background.pivot_offset = background.size / 2.0
	background.scale = Vector2(1.2, 1.2)

func _connect_signals() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	$Settings.pressed.connect(_on_settings_pressed)
	$Credit.pressed.connect(_on_credit_pressed)
	$Quit.pressed.connect(_on_quit_pressed)
	
	close_btn.pressed.connect(_close_panels)
	backdrop.pressed.connect(_close_panels)
	
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _configure_mouse_filters() -> void:
	settings_container.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_container.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

func _play_intro_animation() -> void:
	for btn in tombol_list:
		btn.modulate.a = 0.0
		btn.scale = Vector2.ZERO
		btn.pivot_offset = btn.size / 2.0

	var intro_tween := create_tween().set_parallel(false)
	intro_tween.tween_property(background, "scale", Vector2.ONE, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_interval(0.2)
	
	for btn in tombol_list:
		var btn_tween := create_tween().set_parallel(true)
		btn_tween.tween_property(btn, "modulate:a", 1.0, 0.3)
		btn_tween.tween_property(btn, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.12).timeout

func _update_continue_button() -> void:
	var has_valid_data: bool = SaveManager.current_save.player_deck_data.size() > 0
	play_btn.visible = not has_valid_data
	continue_btn.visible = has_valid_data

func _on_settings_pressed() -> void:
	SoundManager.play_sfx("ui_click")
	_open_settings_panel()

func _on_credit_pressed() -> void:
	SoundManager.play_sfx("ui_click")
	_open_credits_panel()

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("ui_click")
	var fade_tween := create_tween().set_parallel(true)
	fade_tween.tween_property(background, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func() -> void: get_tree().quit())

func _open_settings_panel() -> void:
	settings_container.visible = true
	credits_container.visible = false
	settings_container.modulate.a = 0.0
	_overlay_animation(true)

func _open_credits_panel() -> void:
	settings_container.visible = false
	credits_container.visible = true
	credits_container.modulate.a = 0.0
	_overlay_animation(true)
	_start_credit_scroll()

func _close_panels() -> void:
	SoundManager.play_sfx("ui_click")
	_overlay_animation(false)

func _overlay_animation(should_show: bool) -> void:
	var target_alpha: float = 1.0 if should_show else 0.0
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if should_show:
		overlay_layer.visible = true
		backdrop.visible = true
		close_btn.visible = true
	
	if settings_container.visible:
		tween.tween_property(settings_container, "modulate:a", target_alpha, 0.3)
	if credits_container.visible:
		tween.tween_property(credits_container, "modulate:a", target_alpha, 0.3)
	
	if not should_show:
		tween.chain().tween_callback(func() -> void:
			overlay_layer.visible = false
			backdrop.visible = false
			close_btn.visible = false
			settings_container.visible = false
			credits_container.visible = false
		)

func _on_master_volume_changed(value: float) -> void:
	SoundManager.set_bus_volume("Master", value)

func _on_bgm_volume_changed(value: float) -> void:
	SoundManager.set_bus_volume("Music", value)

func _on_sfx_volume_changed(value: float) -> void:
	SoundManager.set_bus_volume("SFX", value)

func _start_credit_scroll() -> void:
	credits_scroll.scroll_vertical = 0
	await get_tree().process_frame
	var max_scroll: float = max(0.0, credits_text.size.y - credits_scroll.size.y)
	
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(credits_scroll, "scroll_vertical", int(max_scroll), 15.0).set_delay(1.0)

func _on_play_pressed() -> void:
	SoundManager.play_sfx("ui_click")
	_change_scene_sequence(func() -> void: GameManager.start_new_run())

func _on_continue_pressed() -> void:
	SoundManager.play_sfx("ui_click")
	_change_scene_sequence()

func _change_scene_sequence(action: Callable = Callable()) -> void:
	for btn in tombol_list: 
		btn.disabled = true
	var fade_tween := create_tween().set_parallel(true)
	for btn in tombol_list: 
		fade_tween.tween_property(btn, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(background, "modulate:a", 0.0, 0.35)
	await fade_tween.finished
	if action.is_valid():
		action.call()
	get_tree().change_scene_to_file(MAP_SCENE_PATH)
