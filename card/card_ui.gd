class_name CardUI
extends TextureButton

var data: CardData

# Menyimpan referensi Tween agar bisa dihentikan saat mouse bergerak cepat
var hover_tween: Tween

# Parameter "Juicy" (Diekspor agar bisa Anda atur lewat Inspector)
@export var hover_scale: Vector2 = Vector2(1.2, 1.2) # Membesar 20%
@export var hover_rotation_degrees: float = 3.0 # Sedikit miring agar dinamis
@export var animation_duration: float = 0.25 # Kecepatan animasi

func _ready() -> void:
	# Menghubungkan sinyal bawaan Control node untuk deteksi mouse
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(card_data: CardData) -> void:
	data = card_data
	texture_normal = data.card_texture
	
	# RAHASIA 1: Pindahkan titik pusat (pivot) ke tengah kartu
	# Kita harus melakukannya setelah texture_normal diisi agar kita tahu ukuran gambarnya
	if texture_normal:
		pivot_offset = texture_normal.get_size() / 2.0

## Dipanggil saat mouse masuk ke area kartu
func _on_mouse_entered() -> void:
	# RAHASIA 2: Naikkan Z-Index agar kartu ini menutupi kartu di sebelahnya
	z_index = 10 
	
	# Rotasi ke arah yang sedikit acak (kiri atau kanan) untuk efek natural
	var random_dir: float = 1.0 if randf() > 0.5 else -1.0
	var target_rot: float = deg_to_rad(hover_rotation_degrees) * random_dir
	
	_animate_hover(hover_scale, target_rot)

## Dipanggil saat mouse keluar dari area kartu
## Dipanggil saat mouse keluar dari area kartu
func _on_mouse_exited() -> void:
	# Kembalikan Z-Index ke normal
	z_index = 0
	
	# PERBAIKAN: Gunakan Vector2.ONE untuk mengembalikan skala ke (1, 1) dan rotasi ke 0
	_animate_hover(Vector2.ONE, 0.0) 

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
