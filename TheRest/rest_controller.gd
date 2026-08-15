extends Control

@export var heal_amount: int = 20
@export var heal_price: int = 0  # Gratis di rest area

@onready var heal_button: TextureButton = $HealButton
@onready var leave_button: TextureButton = $LeaveButton
@onready var bg: TextureRect = $bg
@onready var hp_label: Label = $HPLabel

var heal_tween: Tween
var leave_tween: Tween
var feedback_tween: Tween

# Flag untuk menandai apakah sudah heal atau belum
var has_healed: bool = false

func _ready() -> void:
	print("=== REST CONTROLLER READY ===")
	print("Heal Button: ", heal_button)
	print("Leave Button: ", leave_button)
	print("BG: ", bg)
	print("Has Healed: ", has_healed)
	
	# Pastikan button bisa menerima mouse input
	if heal_button:
		heal_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if leave_button:
		leave_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_connect_signals()
	_setup_hover_effects()
	_update_ui()
	
	# Play BGM rest area (jika ada)
	if SoundManager.has_method("play_bgm"):
		SoundManager.play_bgm("rest")

func _connect_signals() -> void:
	if heal_button:
		heal_button.pressed.connect(_on_heal_pressed)
		heal_button.mouse_entered.connect(_on_heal_hover_entered)
		heal_button.mouse_exited.connect(_on_heal_hover_exited)
		print("Heal button signals connected!")
	else:
		push_error("HealButton not found! Check node name.")
	
	if leave_button:
		leave_button.pressed.connect(_on_leave_pressed)
		leave_button.mouse_entered.connect(_on_leave_hover_entered)
		leave_button.mouse_exited.connect(_on_leave_hover_exited)
		print("Leave button signals connected!")
	else:
		push_error("LeaveButton not found! Check node name.")

func _setup_hover_effects() -> void:
	# Setup efek glow untuk heal button
	if heal_button:
		_create_glow_effect(heal_button, Color(0.2, 0.8, 0.2, 0.3))
	
	# Setup efek glow untuk leave button
	if leave_button:
		_create_glow_effect(leave_button, Color(0.8, 0.2, 0.2, 0.3))

func _create_glow_effect(button: TextureButton, glow_color: Color) -> void:
	# Buat ColorRect sebagai glow effect di belakang button
	var glow = ColorRect.new()
	glow.color = glow_color
	glow.size = button.size + Vector2(60, 60)
	glow.position = Vector2(-30, -30)
	glow.modulate = Color(1, 1, 1, 0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = -1
	glow.self_modulate = Color(1, 1, 1, 0)
	
	button.add_child(glow)
	button.set_meta("glow_effect", glow)
	print("Glow effect created for: ", button.name)

func _on_heal_hover_entered() -> void:
	print("Heal button hovered!")
	_animate_glow(heal_button, true, "heal")
	_animate_button_scale(heal_button, 1.05)  # Scale lebih kecil (1.05)
	
	# Tooltip dengan info apakah sudah heal atau belum
	var tooltip_text = "Heal +%d HP" % heal_amount
	if has_healed:
		tooltip_text += "heal mencapai maksimum"
	else:
		tooltip_text += " (1x)"
	_show_tooltip(heal_button, tooltip_text, Color(0.2, 0.8, 0.2))

func _on_heal_hover_exited() -> void:
	print("Heal button unhovered!")
	_animate_glow(heal_button, false, "heal")
	_animate_button_scale(heal_button, 1.0)
	_hide_tooltip()

func _on_leave_hover_entered() -> void:
	print("Leave button hovered!")
	_animate_glow(leave_button, true, "leave")
	_animate_button_scale(leave_button, 1.05)  # Scale lebih kecil (1.05)
	_show_tooltip(leave_button, "Kembali ke Map", Color(0.8, 0.2, 0.2))

func _on_leave_hover_exited() -> void:
	print("Leave button unhovered!")
	_animate_glow(leave_button, false, "leave")
	_animate_button_scale(leave_button, 1.0)
	_hide_tooltip()

func _show_tooltip(button: TextureButton, text: String, color: Color) -> void:
	# Hapus tooltip lama jika ada
	_hide_tooltip()
	
	# Buat tooltip sederhana (tanpa panel, langsung Label)
	var tooltip = Label.new()
	tooltip.name = "Tooltip"
	tooltip.text = text
	tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip.add_theme_color_override("font_color", color)
	tooltip.add_theme_font_size_override("font_size", 18)
	tooltip.modulate = Color(1, 1, 1, 0)
	tooltip.z_index = 100
	
	# Hitung ukuran label berdasarkan teks
	tooltip.size = Vector2(200, 30)
	
	# Posisi tooltip di ATAS button (dekat)
	var button_global_pos = button.global_position
	var button_size = button.size * button.scale
	
	tooltip.global_position = Vector2(
		button_global_pos.x + (button_size.x / 2) - (tooltip.size.x / 2),
		button_global_pos.y - tooltip.size.y - 8  # Jarak 8px di atas button
	)
	
	add_child(tooltip)
	
	# Animasi fade in
	var tween = create_tween()
	tween.tween_property(tooltip, "modulate", Color(1, 1, 1, 1), 0.15)

func _hide_tooltip() -> void:
	var tooltip = get_node_or_null("Tooltip")
	if tooltip:
		var tween = create_tween()
		tween.tween_property(tooltip, "modulate", Color(1, 1, 1, 0), 0.1)
		tween.tween_callback(func():
			if is_instance_valid(tooltip):
				tooltip.queue_free()
		)

func _animate_glow(button: TextureButton, show: bool, button_id: String) -> void:
	var glow = button.get_meta("glow_effect", null)
	if not glow:
		return
	
	# Kill tween yang sesuai
	if button_id == "heal" and heal_tween and heal_tween.is_valid():
		heal_tween.kill()
	elif button_id == "leave" and leave_tween and leave_tween.is_valid():
		leave_tween.kill()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Simpan tween ke variabel yang sesuai
	if button_id == "heal":
		heal_tween = tween
	else:
		leave_tween = tween
	
	if show:
		tween.tween_property(glow, "self_modulate", Color(1, 1, 1, 1), 0.3)
		tween.tween_property(glow, "size", button.size + Vector2(80, 80), 0.3)
		tween.tween_property(glow, "position", Vector2(-40, -40), 0.3)
	else:
		tween.tween_property(glow, "self_modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_property(glow, "size", button.size + Vector2(60, 60), 0.3)
		tween.tween_property(glow, "position", Vector2(-30, -30), 0.3)

func _animate_button_scale(button: TextureButton, target_scale: float) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.2)

func _on_heal_pressed() -> void:
	print("Heal button PRESSED!")
	
	# Cek apakah sudah pernah heal
	if has_healed:
		_show_feedback("Sudah pernah heal!", Color(0.8, 0.8, 0.2))
		return
	
	# Cek apakah HP sudah full
	if GameManager.player_current_hp >= GameManager.player_max_hp:
		_show_feedback("HP sudah penuh!", Color(0.8, 0.8, 0.2))
		return
	
	# Heal player
	var actual_healed = GameManager.heal_player(heal_amount)
	
	if actual_healed > 0:
		# Tandai sudah heal
		has_healed = true
		print("Has Healed set to: ", has_healed)
		
		_show_feedback("+%d HP!" % actual_healed, Color(0.2, 0.8, 0.2))
		_animate_heal_effect()
		_update_ui()
		
		# Update tooltip text dengan menampilkan ulang hover
		if heal_button and not heal_button.is_hovered():
			# Jika tidak di-hover, tooltip akan update saat hover berikutnya
			pass
		
		if SoundManager.has_method("play_sfx"):
			SoundManager.play_sfx("heal_success")
	else:
		_show_feedback("Gagal heal!", Color(0.8, 0.2, 0.2))

func _animate_heal_effect() -> void:
	if heal_button:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(heal_button, "modulate", Color(0.2, 1, 0.2), 0.1)
		tween.tween_property(heal_button, "scale", Vector2(0.95, 0.95), 0.1)
		
		var tween2 = create_tween()
		tween2.tween_interval(0.15)
		tween2.tween_callback(func():
			if is_instance_valid(heal_button):
				var t = create_tween()
				t.set_parallel(true)
				t.tween_property(heal_button, "modulate", Color.WHITE, 0.15)
				t.tween_property(heal_button, "scale", Vector2(1, 1), 0.15)
		)

func _show_feedback(text: String, color: Color) -> void:
	# Hapus feedback lama
	var old_feedback = get_node_or_null("Feedback")
	if old_feedback:
		old_feedback.queue_free()
	
	# Buat label feedback
	var label = Label.new()
	label.name = "Feedback"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = color
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	
	# Posisikan di tengah scene
	label.size = Vector2(400, 60)
	label.position = (size - label.size) / 2
	
	add_child(label)
	
	# Animate naik dan fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 80, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.5)
	
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

func _on_leave_pressed() -> void:
	print("Leave button PRESSED!")
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://map/map_scene.tscn")
	)

func _update_ui() -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [GameManager.player_current_hp, GameManager.player_max_hp]
		print("UI Updated: ", hp_label.text)
	else:
		print("HP: %d / %d" % [GameManager.player_current_hp, GameManager.player_max_hp])
