# enemy_base.gd
class_name EnemyBase
extends Node2D

# 1. Definisi 5 Tipe Gerakan (Menggunakan Enum)
enum MoveType {ATTACK, BUFF, DEBUFF, SHIELD, HEAL}

# Tempat kita memasukkan data resource (.tres) dari Inspector
@export var stats: EnemyStat 
@export var max_display_size: Vector2 = Vector2(150.0, 150.0)

var active_statuses: Dictionary = {}

# Stat pertarungan yang aktif
var current_hp: int
var current_shield: int = 0

# Flag AI untuk mengingat apakah musuh sudah melakukan buff/debuff
var has_buffed: bool = false
var has_debuffed: bool = false

# Node referensi visual (opsional, sesuaikan dengan struktur scene Anda)
@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_aura: Sprite2D = $SelectionAura
@onready var click_area: Area2D = $ClickArea
@onready var collision_shape: CollisionShape2D = $ClickArea/CollisionShape2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/Label
@onready var status_container: HBoxContainer = $StatusContainer

var is_selected: bool = false
var float_tween: Tween
var base_sprite_y: float

func _ready() -> void:
	if stats:
		current_hp = stats.max_hp
		hp_bar.max_value = stats.max_hp
		hp_bar.value = current_hp
		_update_hp_text()
		if sprite and stats.texture:
			sprite.texture = stats.texture
			_adjust_sprite_scale()
	click_area.input_event.connect(_on_click_area_input_event)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	
	if sprite and stats.texture:
		sprite.texture = stats.texture
		_adjust_sprite_scale()
		
		# Sinkronkan gambar aura dengan gambar asli
		selection_aura.texture = stats.texture
		# Buat aura 15% lebih besar dari aslinya untuk efek "Border Cahaya"
		selection_aura.scale = sprite.scale * 1.15
		
	base_sprite_y = sprite.position.y
	
	# DENGARKAN SINYAL GLOBAL: Jika ada musuh yang dipilih, cek apakah itu kita?
	EventBus.enemy_selected.connect(_on_any_enemy_selected)

func _update_hp_text() -> void:
	if hp_label:
		hp_label.text = str(current_hp) + " / " + str(stats.max_hp)

func _adjust_sprite_scale() -> void:
	if sprite.texture == null:
		return
		
	var original_size: Vector2 = sprite.texture.get_size()
	
	# Kita cari rasio terkecil antara batas X atau batas Y 
	# Ini menggunakan fungsi min() bawaan Godot agar gambar tetap proporsional (tidak gepeng)
	var scale_factor: float = min(
		max_display_size.x / original_size.x, 
		max_display_size.y / original_size.y
	)
	
	# Terapkan perhitungan skala ke Sprite2D
	sprite.scale = Vector2(scale_factor, scale_factor)
	var shape = RectangleShape2D.new()
	shape.size = original_size * scale_factor
	collision_shape.shape = shape

func determine_next_move() -> EnemyAction:
	if stats.moveset.is_empty():
		push_error(stats.enemy_name + " tidak memiliki moveset di Inspector!")
		return null
		
	# LOGIKA MVP: Pilih jurus secara acak dari kantong
	# (Nanti kita bisa upgrade dengan logika probabilitas atau kondisi HP)
	var chosen_action: EnemyAction = stats.moveset.pick_random()
	return chosen_action

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SoundManager.play_sfx("enemy_select")
		EventBus.enemy_selected.emit(self)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_mouse_entered() -> void:
	if is_selected: return # Blokir!
	var hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited() -> void:
	if is_selected: return # Blokir!
	var reset_tween = create_tween()
	reset_tween.tween_property(self, "scale", Vector2.ONE, 0.1)

## Fungsi untuk mengeksekusi gerakan yang sudah diputuskan AI
func execute_move(action: EnemyAction) -> void:
	print("Musuh: ", stats.enemy_name, " | Jurus: ", action.action_name, " | Tipe Enum: ", action.type)
	match action.type:
		EnemyAction.ActionType.ATTACK:
			print(stats.enemy_name, " melancarkan serangan!")
			EventBus.player_took_damage.emit(action.amount)
			
		EnemyAction.ActionType.BUFF:
			print(stats.enemy_name, " meningkatkan serangannya!")
			# Logika tambah stat serang
			
		EnemyAction.ActionType.DEBUFF:
			print(stats.enemy_name, " melemahkan pemain!")
			# Logika buang kartu pemain atau kurangi armor
			
		EnemyAction.ActionType.SHIELD:
			print(stats.enemy_name, " memasang perisai!")
			current_shield += 10
			
		EnemyAction.ActionType.HEAL:
			print(stats.enemy_name, " memulihkan lukanya!")
			current_hp = clampi(current_hp + 15, 0, stats.max_hp)

func take_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = clampi(current_hp, 0, stats.max_hp)
	
	# Animasi Tween agar darah berkurang dengan mulus (Juicy!)
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE)
	_update_hp_text()
	
	# Efek musuh berkedip merah saat diserang
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		print(stats.enemy_name, " telah mati!")
		EventBus.enemy_died.emit(self)
		queue_free()

func _on_any_enemy_selected(selected_enemy: EnemyBase) -> void:
	if selected_enemy == self:
		_become_selected()
	else:
		_become_deselected()

## --- ANIMASI SAAT TERPILIH ---
func _become_selected() -> void:
	if is_selected: return # Jangan ulangi jika sudah terpilih
	is_selected = true
	
	# 1. Nyalakan Border Cahaya
	selection_aura.show()
	
	# 2. Zoom In seluruh tubuh (Sprite, Aura, dan HP Bar akan membesar)
	var zoom_tween = create_tween()
	zoom_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK)
	
	# 3. Animasi Bergoyang/Melayang (Floating)
	if float_tween and float_tween.is_valid():
		float_tween.kill()
		
	float_tween = create_tween().set_loops() # set_loops() membuat tween diulang tanpa batas!
	# Melayang naik sedikit
	float_tween.tween_property(sprite, "position:y", base_sprite_y - 15.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Melayang turun kembali
	float_tween.tween_property(sprite, "position:y", base_sprite_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## --- ANIMASI SAAT BATAL TERPILIH ---
func _become_deselected() -> void:
	if not is_selected: return
	is_selected = false
	
	# Matikan Border
	selection_aura.hide()
	
	# Kembalikan Zoom ke ukuran normal
	var zoom_tween = create_tween()
	zoom_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	
	# Matikan goyangan dan kembalikan posisi Y
	if float_tween and float_tween.is_valid():
		float_tween.kill()
	var reset_tween = create_tween()
	reset_tween.tween_property(sprite, "position:y", base_sprite_y, 0.2)

func apply_status(status_data: StatusAilment, duration: int) -> void:
	if status_data == null: return
	
	var ailment_id = status_data.ailment
	
	# Jika musuh sudah punya status ini, perbarui/reset durasinya
	active_statuses[ailment_id] = {
		"duration": duration,
		"resource": status_data
	}
	
	print(stats.enemy_name, " terkena status elemen: ", ailment_id, " selama ", duration, " turn!")
	_update_status_ui() # Perbarui visual!

func has_status(element: int) -> bool:
	return active_statuses.has(element)

func remove_status(element: int) -> void:
	if active_statuses.has(element):
		active_statuses.erase(element)
		_update_status_ui() # Perbarui visual setelah dihapus

## --- FUNGSI MENGURANGI DURASI (Dipanggil setiap giliran berakhir) ---
func decrease_status_durations() -> void:
	var keys_to_remove = []
	for ailment_id in active_statuses.keys():
		active_statuses[ailment_id]["duration"] -= 1
		if active_statuses[ailment_id]["duration"] <= 0:
			keys_to_remove.append(ailment_id)
			
	for ailment_id in keys_to_remove:
		active_statuses.erase(ailment_id)
		print("Status elemen ", ailment_id, " pada ", stats.enemy_name, " telah hilang.")
		
	_update_status_ui() # Perbarui visual setelah durasi berkurang

## --- FUNGSI MEMPERBARUI UI STATUS ---
func _update_status_ui() -> void:
	# 1. Bersihkan semua ikon lama di dalam container
	for child in status_container.get_children():
		child.queue_free()
		
	# 2. Buat ulang ikon untuk setiap status yang sedang aktif
	for ailment_id in active_statuses.keys():
		var status_info = active_statuses[ailment_id]
		var resource_data: StatusAilment = status_info["resource"]
		var current_duration: int = status_info["duration"]
		
		# --- Membuat Struktur UI secara Prosedural ---
		
		# A. TextureRect untuk menampilkan ikon efek
		var icon_rect = TextureRect.new()
		icon_rect.texture = resource_data.status_icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Saran: Besarkan sedikit ukuran minimum agar angka mudah dibaca pemain
		icon_rect.custom_minimum_size = Vector2(30, 30) 
		
		# B. Label untuk menampilkan sisa angka (durasi)
		var duration_label = Label.new()
		duration_label.text = str(current_duration)
		
		# Gaya teks agar tebal dan memiliki border hitam yang kuat
		duration_label.add_theme_color_override("font_outline_color", Color.BLACK)
		duration_label.add_theme_constant_override("outline_size", 6)
		# (Opsional) Jika Anda ingin teks berwarna unik, misal Kuning Emas:
		# duration_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		
		# ==========================================
		# SIHIR ALIGNMENT GODOT (TANPA TEBAK POSISI)
		# ==========================================
		# 1. Paksa Label untuk mengambil seluruh ukuran dari TextureRect (30x30)
		duration_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# 2. Daripada menggeser Label-nya, kita dorong TEKS-nya ke pojok kanan bawah!
		duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		duration_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		
		# Masukkan Label ke dalam TextureRect, lalu masukkan TextureRect ke HBoxContainer
		icon_rect.add_child(duration_label)
		status_container.add_child(icon_rect)
