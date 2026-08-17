extends Node2D

@onready var global_click_sfx: AudioStreamPlayer = $GlobalClickSFX
@onready var background: TextureRect = $bg
@onready var play_btn = $Play
@onready var continue_btn = $ContinueButton 

# --- OVERLAY UI NODES ---
@onready var overlay_layer: CanvasLayer = $OverlayLayer
@onready var close_btn: TextureButton = $OverlayLayer/CloseButton

# Settings Panel (Menggunakan find_child agar 100% aman)
@onready var settings_container: TextureRect = overlay_layer.find_child("SettingsPanel", true, false)
@onready var master_slider: HSlider = settings_container.find_child("MasterSlider", true, false)
@onready var bgm_slider: HSlider = settings_container.find_child("BGMSlider", true, false)
@onready var sfx_slider: HSlider = settings_container.find_child("SFXSliders", true, false)

# Credits Nodes (Juga menggunakan find_child agar path tidak error lagi)
@onready var credits_container: TextureRect = overlay_layer.find_child("CreditsPanel2", true, false)
@onready var credits_scroll: ScrollContainer = $OverlayLayer/CreditsPanel2/ScrollContainer
@onready var credits_text: RichTextLabel = $OverlayLayer/CreditsPanel2/ScrollContainer/CreditsText

# Tombol Utama
@onready var tombol_list: Array = [
	$Play, $ContinueButton, $Collection, $Settings, $Credit, $Quit
]

const MAP_SCENE_PATH := "res://map/map_scene.tscn"

func _ready() -> void:
	SoundManager.play_bgm("main_menu")
	background.pivot_offset = background.size / 2
	background.scale = Vector2(1.2, 1.2)
	
	play_btn.pressed.connect(_on_play_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	
	# Hubungkan tombol baru
	$Settings.pressed.connect(_on_settings_pressed)
	$Credit.pressed.connect(_on_credit_pressed)
	$Quit.pressed.connect(_on_quit_pressed)
	close_btn.pressed.connect(_close_panels)
	
	# Slider Volume
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	_update_continue_button()
	_overlay_animation(false) # Sembunyikan panel awal

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


func _update_continue_button() -> void:
	var has_valid_data = SaveManager.current_save.player_deck_data.size() > 0
	if has_valid_data:
		play_btn.visible = false
		continue_btn.visible = true
	else:
		play_btn.visible = true
		continue_btn.visible = false


# ==========================================
# OVERLAY & NAVIGASI PANEL (LOGIKA UTAMA)
# ==========================================

func _on_settings_pressed() -> void:
	if global_click_sfx: global_click_sfx.play()
	_open_settings_panel()

func _on_credit_pressed() -> void:
	if global_click_sfx: global_click_sfx.play()
	_open_credits_panel()

func _on_quit_pressed() -> void:
	if global_click_sfx: global_click_sfx.play()
	# Tween fade out, baru quit
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(background, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func(): get_tree().quit())

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
	if global_click_sfx: global_click_sfx.play()
	_overlay_animation(false)

func _overlay_animation(should_show: bool) -> void:
	var target_alpha: float = 1.0 if should_show else 0.0
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if settings_container.visible:
		tween.tween_property(settings_container, "modulate:a", target_alpha, 0.3)
	if credits_container.visible:
		tween.tween_property(credits_container, "modulate:a", target_alpha, 0.3)
	
	if should_show:
		overlay_layer.visible = true
	else:
		tween.tween_callback(func(): 
			overlay_layer.visible = false
			settings_container.visible = false
			credits_container.visible = false
		)


# ==========================================
# SETTINGS AUDIO (Volume Slider Custom Mapping)
# ==========================================
# Rumus: 0 = -80dB (Mute), 50% = 0dB (Normal), 100% = +6dB (Max)
func _map_slider_to_db(value: float) -> float:
	if value <= 0.01: return -80.0 # Mute total
	else: return (value - 0.5) * 12.0 # 0.5 -> 0dB, 1.0 -> 6dB

func _on_master_volume_changed(value: float) -> void:
	var db = _map_slider_to_db(value)
	SoundManager.set_master_volume_db(db)

func _on_bgm_volume_changed(value: float) -> void:
	var db = _map_slider_to_db(value)
	SoundManager.set_bgm_volume_db(db)

func _on_sfx_volume_changed(value: float) -> void:
	var db = _map_slider_to_db(value)
	SoundManager.set_sfx_volume_db(db)


# ==========================================
# CREDITS (Auto Scroll)
# ==========================================

func _start_credit_scroll() -> void:
	credits_scroll.scroll_vertical = 0
	await get_tree().process_frame # Tunggu layout UI terhitung
	var max_scroll = credits_text.size.y - credits_scroll.size.y
	if max_scroll < 0: max_scroll = 0
	
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(credits_scroll, "scroll_vertical", max_scroll, 15.0).set_delay(1.0)


# ==========================================
# LOGIKA DRAG PLAY & CONTINUE
# ==========================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if global_click_sfx and not global_click_sfx.playing:
			global_click_sfx.play()

func _on_play_pressed() -> void:
	if global_click_sfx: global_click_sfx.play()
	for btn in tombol_list: btn.disabled = true
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	for btn in tombol_list: fade_tween.tween_property(btn, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(background, "modulate:a", 0.0, 0.35)
	await fade_tween.finished
	GameManager.start_new_run()
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_continue_pressed() -> void:
	if global_click_sfx: global_click_sfx.play()
	for btn in tombol_list: btn.disabled = true
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	for btn in tombol_list: fade_tween.tween_property(btn, "modulate:a", 0.0, 0.25)
	fade_tween.tween_property(background, "modulate:a", 0.0, 0.35)
	await fade_tween.finished
	get_tree().change_scene_to_file(MAP_SCENE_PATH)
