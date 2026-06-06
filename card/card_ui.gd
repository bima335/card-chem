class_name CardUI
extends TextureButton

var data: CardData

# Menyimpan referensi Tween agar bisa dihentikan saat mouse bergerak cepat
var hover_tween: Tween
var is_preview: bool = false

# Parameter "Juicy" (Diekspor agar bisa Anda atur lewat Inspector)
@export var hover_scale: Vector2 = Vector2(1.2, 1.2) # Membesar 20%
@export var hover_rotation_degrees: float = 3.0 # Sedikit miring agar dinamis
@export var animation_duration: float = 0.25 # Kecepatan animasi

@onready var name_label = $TooltipPanel/VBoxContainer/Name
@onready var cost_label = $TooltipPanel/VBoxContainer/Cost
@onready var tooltip_panel = $TooltipPanel

func _ready() -> void:
	# Menghubungkan sinyal bawaan Control node untuk deteksi mouse
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(delta: float) -> void:
	modulate = data.modulate

func setup(card_data: CardData) -> void:
	data = card_data
	texture_normal = data.card_texture
	# RAHASIA 1: Pindahkan titik pusat (pivot) ke tengah kartu
	# Kita harus melakukannya setelah texture_normal diisi agar kita tahu ukuran gambarnya
	if texture_normal:
		pivot_offset = custom_minimum_size / 2.0
	_setup_tooltip_text()

func _setup_tooltip_text() -> void:
	name_label.text = data.card_name
	#desc_label.text = card_data.description
	
	# Merangkai string Cost cerdas (hanya yang > 0)
	var cost_string: String = ""
	
	if data.cost_carbon > 0:
		cost_string += "[C: " + str(data.cost_carbon) + "] "
	if data.cost_hydrogen > 0:
		cost_string += "[H: " + str(data.cost_hydrogen) + "] "
	if data.cost_oxygen > 0:
		cost_string += "[O: " + str(data.cost_oxygen) + "] "
	if data.cost_nitrogen > 0:
		cost_string += "[N: " + str(data.cost_nitrogen) + "] "
		
	# Jika semua cost 0, tampilkan "Gratis", jika tidak, rapikan spasi ujungnya
	if cost_string == "":
		cost_string = "Gratis!"
		
	cost_label.text = cost_string.strip_edges()

## Dipanggil saat mouse masuk ke area kartu
func _on_mouse_entered() -> void:
	SoundManager.play_sfx("card_hover")
	#if is_preview: return
	# RAHASIA 2: Naikkan Z-Index agar kartu ini menutupi kartu di sebelahnya
	z_index = 10 
	
	# Rotasi ke arah yang sedikit acak (kiri atau kanan) untuk efek natural
	var random_dir: float = 1.0 if randf() > 0.5 else -1.0
	var target_rot: float = deg_to_rad(hover_rotation_degrees) * random_dir
	
	_animate_hover(hover_scale, target_rot)

	# 1. Tampilkan tooltip
	tooltip_panel.show()
	
	# 2. Paksa Godot menghitung ukuran kontainer (penting agar posisi tengahnya akurat)
	tooltip_panel.reset_size() 
	
	# 3. Hitung Posisi: 
	# X = Posisi Global Kartu + (Setengah lebar kartu) - (Setengah lebar Tooltip) -> Agar presisi di tengah
	# Y = Posisi Global Kartu - Tinggi Tooltip - Jeda (Margin) 15 pixel -> Agar tepat di atas kartu
	var target_x: float = global_position.x + (size.x / 2.0) - (tooltip_panel.size.x / 2.0)
	var target_y: float = global_position.y - tooltip_panel.size.y - 15.0
	
	tooltip_panel.global_position = Vector2(target_x, target_y)
	
	# (Opsional) Animasi Fade In ringan
	tooltip_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween().bind_node(self)
	tween.tween_property(tooltip_panel, "modulate", Color.WHITE, 0.15)

## Dipanggil saat mouse keluar dari area kartu
## Dipanggil saat mouse keluar dari area kartu
func _on_mouse_exited() -> void:
	#if is_preview: return
	# Kembalikan Z-Index ke normal
	z_index = 0
	
	# PERBAIKAN: Gunakan Vector2.ONE untuk mengembalikan skala ke (1, 1) dan rotasi ke 0
	_animate_hover(Vector2.ONE, 0.0) 
	tooltip_panel.hide()

## Fungsi pusat untuk menangani sihir Tween
func _animate_hover(target_scale: Vector2, target_rotation: float) -> void:
	# RAHASIA 3: Hentikan animasi sebelumnya jika masih berjalan
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	
	# Transisi BACK memberikan efek "membal" (overshoot) yang sangat memuaskan!
	hover_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Set paralel agar properti 'scale' dan 'rotation' berjalan di waktu yang sama
	hover_tween.set_parallel(true)
	
	# Mulai proses tween
	hover_tween.tween_property(self, "scale", target_scale, animation_duration)
	hover_tween.tween_property(self, "rotation", target_rotation, animation_duration)
