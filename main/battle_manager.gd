class_name BattleManager
extends Node2D

@export var card_ui_scene: PackedScene 
@export var available_cards: Array[CardData] 

@onready var deck: Deck = $Deck
@onready var hand: Hand = $Hand
@onready var hand_container: HBoxContainer = $UI/HandContainer
@onready var draw_button: Button = $UI/DrawButton
@onready var player: Player = $Player

# Referensi ke posisi deck di layar
@onready var deck_visual: TextureButton = $UI/DeckVisual 

func _ready() -> void:
	draw_button.pressed.connect(_on_draw_button_pressed)
	hand.card_added_to_hand.connect(_on_card_added_to_hand)
	hand.card_removed_from_hand.connect(_on_card_removed_from_hand)
	
	_prepare_starting_deck()

func _prepare_starting_deck() -> void:
	if available_cards.is_empty():
		push_error("Katalog kartu kosong!")
		return
		
	# 1. Isi Deck penuh secara acak
	for i in range(deck.max_capacity):
		var random_card: CardData = available_cards.pick_random()
		deck.add_card(random_card)
		
	# 2. Auto-draw dengan efek "Dealing" (Dibagi satu-satu)
	_draw_initial_hand()

## Fungsi terpisah karena kita akan menggunakan trik 'await' (jeda waktu)
func _draw_initial_hand() -> void:
	for i in range(hand.max_hand_size):
		# Jeda 0.2 detik antar kartu agar animasinya memuaskan
		await get_tree().create_timer(0.2).timeout 
		
		var drawn_card: CardData = deck.draw_card()
		if drawn_card != null:
			var success = hand.add_card(drawn_card)
			if not success:
				deck.cards.append(drawn_card)

func _on_draw_button_pressed() -> void:
	var drawn_card: CardData = deck.draw_card()
	if drawn_card != null:
		var success = hand.add_card(drawn_card)
		if not success:
			deck.cards.append(drawn_card)

## Trik Master: Animasi Dummy Card
func _on_card_added_to_hand(new_card_data: CardData) -> void:
	# 1. Buat KARTU ASLI di dalam HandContainer
	var real_card: CardUI = card_ui_scene.instantiate() as CardUI
	hand_container.add_child(real_card)
	real_card.setup(new_card_data)
	
	# Jadikan transparan. Container akan otomatis menggeser kartu lain untuk memberi ruang!
	real_card.modulate = Color(1, 1, 1, 0)
	
	# Tunggu 1 frame agar HBoxContainer selesai menghitung posisi koordinat
	await get_tree().process_frame
	
	# 2. Buat KARTU BAYANGAN (Dummy) di luar Container agar bebas terbang
	var dummy_card: CardUI = card_ui_scene.instantiate() as CardUI
	$UI.add_child(dummy_card)
	dummy_card.setup(new_card_data)
	
	# Set posisi awal dummy tepat di tengah DeckVisual
	dummy_card.global_position = deck_visual.global_position
	
	# 3. MULAI ANIMASI TWEEN
	var tween = create_tween()
	# Gunakan transisi CUBIC dan EASE_OUT agar gerakannya melambat mulus di akhir
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Terbangkan dummy menuju posisi asli yang sudah dihitung oleh Container
	tween.tween_property(dummy_card, "global_position", real_card.global_position, 0.4)
	
	# 4. Saat animasi selesai (menggunakan fungsi Lambda Godot 4 yang sangat bersih)
	tween.finished.connect(func():
		dummy_card.queue_free() # Hapus bayangan
		real_card.modulate = Color(1, 1, 1, 1) # Munculkan kartu asli
		
		# Baru aktifkan sinyal klik setelah kartu mendarat, agar pemain tidak 
		# memencet kartu yang sedang terbang!
		real_card.pressed.connect(_play_card.bind(real_card, new_card_data))
	)

func _play_card(clicked_ui: CardUI, card_data: CardData) -> void:
	# CEK DOMPET PEMAIN
	if player.can_afford(card_data):
		# 1. Bayar koinnya
		player.pay_for_card(card_data)
		
		# 2. Mainkan kartunya
		print("Kartu dimainkan: ", card_data.card_name)
		hand.remove_card(card_data)
		clicked_ui.queue_free() 
		
	else:
		# JIKA KOIN TIDAK CUKUP (Juicy Feedback!)
		_reject_play(clicked_ui)

## Fungsi untuk memberikan feedback visual jika gagal dimainkan
func _reject_play(card_ui: CardUI) -> void:
	print("Koin tidak cukup!")
	
	# Karena kartu ada di HBoxContainer (posisinya dikunci), 
	# kita tidak bisa menggeser posisinya. 
	# Solusi elegan Godot: Kita kedipkan warnanya menjadi Merah dengan Tween!
	var error_tween = create_tween()
	
	# Ubah warna ke merah dengan cepat
	error_tween.tween_property(card_ui, "modulate", Color.RED, 0.1)
	# Kembalikan ke warna normal (putih)
	error_tween.tween_property(card_ui, "modulate", Color.WHITE, 0.1)
	

func _on_card_removed_from_hand(card_data: CardData) -> void:
	pass
