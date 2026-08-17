extends Control

@onready var back_button: TextureButton = $BackButton

var demo_button: Button
var tooltip_panel: Panel
var tooltip_label: Label


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	_create_demo_button()


func _create_demo_button() -> void:
	# ----- Tombol Demo Mod (tengah kiri) -----
	demo_button = Button.new()
	demo_button.text = "Demo Mod"
	demo_button.tooltip_text = ""

	# Posisi di tengah kiri (vertical center, agak ke kiri)
	# Pakai set_anchors_preset() bukan assignment langsung, supaya anchor
	# benar-benar ke-set (assignment langsung ke anchors_preset tidak
	# mengubah anchor sama sekali, makanya tombol kemarin nyangkut di bawah kiri).
	demo_button.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	demo_button.offset_left = 20
	demo_button.offset_top = -25  # setengah tinggi tombol (50/2)
	demo_button.size = Vector2(140, 50)

	# Style tombol (hijau)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.6, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 1, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	demo_button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.7, 0.3)
	demo_button.add_theme_stylebox_override("hover", hover_style)

	demo_button.pressed.connect(_on_demo_button_pressed)
	demo_button.mouse_entered.connect(_on_demo_button_mouse_entered)
	demo_button.mouse_exited.connect(_on_demo_button_mouse_exited)

	add_child(demo_button)

	# Kalau demo mod sudah pernah dipakai di run ini, langsung nonaktifkan
	# tombolnya (baru aktif lagi setelah menang/kalah dan mulai run baru).
	_update_demo_button_state()


	# ----- Tooltip (tengah kiri, di sebelah kanan tombol) -----
	tooltip_panel = Panel.new()
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tooltip_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	tooltip_panel.offset_left = 180  # di sebelah kanan tombol (tombol lebar 140 + jarak 20)
	tooltip_panel.offset_top = -55   # setengah tinggi tooltip (110/2)
	tooltip_panel.size = Vector2(320, 110)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.6, 0.9, 0.6)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	tooltip_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(tooltip_panel)

	# Label di dalam tooltip
	tooltip_label = Label.new()
	tooltip_label.text = "Jika run terasa terlalu sulit, aktifkan Demo Mod untuk menaikkan HP menjadi 500. Hanya bisa dipakai sekali per run."
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tooltip_label.size = Vector2(300, 100)
	tooltip_label.position = Vector2(10, 5)
	tooltip_label.add_theme_font_size_override("font_size", 14)
	tooltip_label.add_theme_color_override("font_color", Color(0.9, 1, 0.9))
	tooltip_panel.add_child(tooltip_label)


# ----- Handler tombol Demo Mod -----
func _on_demo_button_pressed() -> void:
	# Sudah pernah dipakai di run ini -> tidak bisa dipakai lagi.
	if GameManager.demo_mode_used:
		return

	GameManager.player_max_hp = 500
	GameManager.player_current_hp = 500

	# Update Player jika sedang berada di battle (untuk update HUD langsung)
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("reset_for_battle"):
		player.reset_for_battle()

	print("Demo Mod diaktifkan! HP player sekarang 500.")

	# Tandai sudah dipakai untuk run ini. Baru direset lagi oleh
	# GameManager.start_new_run() setelah menang/kalah (lihat recap_ui.gd).
	GameManager.demo_mode_used = true
	_update_demo_button_state()

	# Efek visual kedip
	var tween = create_tween()
	tween.tween_property(demo_button, "modulate", Color(0.5, 1, 0.5), 0.1)
	tween.tween_property(demo_button, "modulate", Color.WHITE, 0.2)


# ----- Update tampilan/status tombol sesuai apakah demo mod sudah dipakai -----
func _update_demo_button_state() -> void:
	if not demo_button:
		return

	if GameManager.demo_mode_used:
		demo_button.disabled = true
		demo_button.text = "Demo Mod (Terpakai)"
		demo_button.modulate = Color(0.6, 0.6, 0.6)
	else:
		demo_button.disabled = false
		demo_button.text = "Demo Mod"
		demo_button.modulate = Color.WHITE


func _on_demo_button_mouse_entered() -> void:
	tooltip_panel.visible = true


func _on_demo_button_mouse_exited() -> void:
	tooltip_panel.visible = false


# ----- Kembali ke Main Menu -----
func _on_back_pressed() -> void:
	if SoundManager.has_method("play_sfx"):
		SoundManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://main/main_menu.tscn")