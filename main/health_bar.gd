class_name HealthBar
extends VBoxContainer

# Node References
@onready var health_bar: TextureProgressBar = $BarContainer/HealthBarUnder
@onready var shield_bar: TextureProgressBar = $BarContainer/ShieldBar
@onready var hp_label: Label = $BarContainer/HPLabel
@onready var status_container: HBoxContainer = $StatusContainer

# Preload scene kecil untuk Ikon Status (TextureRect)
# Pastikan kamu sudah buat scene StatusIcon.tscn ini!
const STATUS_ICON_SCENE = preload("res://UI/StatusIcon.tscn")

# Dictionary untuk mencatat ikon status yang sedang aktif: { "status_id": Node_TextureRect }
var active_status_icons: Dictionary = {}

# 1. Inisialisasi awal nilai Max HP & Shield
func init_health(max_hp: int, max_shield: int) -> void:
	health_bar.max_value = max_hp
	shield_bar.max_value = max_hp
	update_values(max_hp, max_shield)

# 2. Update HP & Shield (memakai Animasi Tween)
func update_values(current_hp: int, current_shield: int) -> void:
	var tween = create_tween().set_parallel(true)
	
	# Transisi halus nilai HP dan Shield
	tween.tween_property(health_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(shield_bar, "value", current_shield, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Sembunyikan bar shield jika nilainya 0
	shield_bar.visible = current_shield > 0
	
	# Update teks angka HP + Shield
	_update_label_text(current_hp, health_bar.max_value, current_shield)

# Update Teks Format: "80/100 (+20 shield)"
func _update_label_text(current_hp: int, max_hp: int, current_shield: int) -> void:
	if current_shield > 0:
		hp_label.text = "%d/%d (+%d shield)" % [current_hp, max_hp, current_shield]
	else:
		hp_label.text = "%d/%d" % [current_hp, max_hp]

# ==============================================================================
# 3. MANAJEMEN STATUS TAGS (DITAMBAHKAN KEDALAM HBOXCONTAINER LEWAT SCRIPT)
# ==============================================================================

# Tambah Ikon Status ke HBoxContainer
func add_status_tag(status_id: String, icon_texture: Texture2D) -> void:
	# Jika status ini sudah ada, tidak perlu spawn ikon baru lagi
	if active_status_icons.has(status_id):
		return
	
	# Buat instance baru dari StatusIcon.tscn
	var icon_instance = STATUS_ICON_SCENE.instantiate() as TextureRect
	icon_instance.texture = icon_texture
	
	# Masukkan ke dalam HBoxContainer (Godot otomatis menata posisinya)
	status_container.add_child(icon_instance)
	
	# Simpan referensi ke Dictionary
	active_status_icons[status_id] = icon_instance

# Hapus Ikon Status dari HBoxContainer saat durasi buff/debuff habis
func remove_status_tag(status_id: String) -> void:
	if active_status_icons.has(status_id):
		var icon_node = active_status_icons[status_id]
		icon_node.queue_free() # Hapus node dari scene
		active_status_icons.erase(status_id) # Hapus dari dictionary

# Bersihkan semua tag (misal saat musuh mati/respawn)
func clear_all_status_tags() -> void:
	for status_id in active_status_icons:
		active_status_icons[status_id].queue_free()
	active_status_icons.clear()