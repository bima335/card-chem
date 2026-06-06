class_name JuicyButton
extends TextureButton # Ganti menjadi 'extends TextureButton' jika Anda memakai gambar, bukan tombol UI standar

@export var hover_scale: Vector2 = Vector2(1.15, 1.15) # Seberapa besar saat disentuh mouse
@export var idle_scale: Vector2 = Vector2(1.05, 1.05) # Seberapa besar detak nafasnya
@export var breath_speed: float = 0.8 # Kecepatan satu tarikan nafas

var active_tween: Tween

func _ready() -> void:
	# SIHIR WAJIB: Pusatkan titik tumpu (Pivot)
	pivot_offset = size / 2.0
	
	# 1. Pastikan tombol diizinkan menerima fokus dari keyboard/gamepad
	focus_mode = Control.FOCUS_ALL
	
	# 2. Sambungkan deteksi kursor (Mouse)
	mouse_entered.connect(_on_mouse_hover)
	mouse_exited.connect(_start_idle_breathing)
	
	# 3. Sambungkan deteksi navigasi (Keyboard/Controller) - INI KUNCINYA!
	focus_entered.connect(_on_mouse_hover)
	focus_exited.connect(_start_idle_breathing)
	
	# Mulai berdetak saat game dijalankan
	_start_idle_breathing()

func _start_idle_breathing() -> void:
	# Hentikan animasi sebelumnya (seperti animasi hover yang mungkin belum selesai)
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	# set_loops() membuat animasi ini berjalan abadi
	active_tween = create_tween().set_loops()
	# TRANS_SINE memberikan efek melambat di puncak, persis seperti orang bernafas
	active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Tarik nafas (membesar perlahan)
	active_tween.tween_property(self, "scale", idle_scale, breath_speed)
	# Hembuskan nafas (kembali normal perlahan)
	active_tween.tween_property(self, "scale", Vector2.ONE, breath_speed)

func _on_mouse_hover() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	active_tween = create_tween()
	# TRANS_BACK memberikan efek membal ("overshoot") yang sangat memuaskan saat kursor masuk
	active_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Membesar dengan cepat
	active_tween.tween_property(self, "scale", hover_scale, 0.2)
	
	# Tambahkan suara agar lebih responsif! (Pastikan nama audionya sesuai dengan yang di SoundManager Anda)
	SoundManager.play_sfx("card_hover", 0.1)
