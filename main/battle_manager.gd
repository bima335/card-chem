class_name BattleManager
extends Node2D

enum TurnState { PLAYER, ENEMY }
var current_state: TurnState = TurnState.PLAYER

# --- DATABASE REAKSI ELEMENTAL ---
@export var active_reactions: Array[AilmentReaction] = []

@export var card_ui_scene: PackedScene 
@export var available_cards: Array[CardData] 

@onready var deck: Deck = $Deck
@onready var hand: Hand = $Hand
@onready var hand_container: HBoxContainer = $UI/HandContainer

@onready var end_turn_button = $UI/EndTurnButton
@onready var stage_manager: StageManager = $StageManager
@onready var player: Player = $Player
@onready var deck_visual: TextureButton = $UI/DeckVisual 
@onready var discard_visual: TextureButton = $UI/DiscardVisual
@onready var panel_title_label: Label = $UI/DeckViewPanel/TitleLabel
@onready var deck_view_panel: PanelContainer = $UI/DeckViewPanel
@onready var deck_backdrop: ColorRect = $UI/DeckBackDrop
@onready var card_grid: GridContainer = $UI/DeckViewPanel/VBoxContainer/ScrollContainer/CardGrid
@onready var close_deck_button: Button = $UI/DeckViewPanel/CloseButton

@onready var player_hp_bar: ProgressBar = $UI/PlayerHPBar
@onready var player_hp_label: Label = $UI/PlayerHPBar/Label

@onready var player_shield_bar: ProgressBar = $UI/PlayerShieldBar
@onready var player_shield_label: Label = $UI/PlayerShieldBar/Label

@onready var c_label: Label = $UI/TokenContainer/CLabel
@onready var h_label: Label = $UI/TokenContainer/HLabel
@onready var o_label: Label = $UI/TokenContainer/OLabel
@onready var n_label: Label = $UI/TokenContainer/NLabel
@onready var reward_backdrop: ColorRect = $UI/RewardBackdrop
@onready var reward_title: Label = $UI/RewardBackdrop/VBoxContainer/TtileLabel
@onready var reward_card_grid: HBoxContainer = $UI/RewardBackdrop/VBoxContainer/RewardCardGrid
@onready var skip_button: Button = $UI/RewardBackdrop/VBoxContainer/SkipButton

var current_round: int = 1
var is_first_turn: bool = true

var current_target: EnemyBase = null

# --- MEMORI EFEK KARTU ---
var is_selecting_effect_target: bool = false
var active_effect_choice: String = ""

func _ready() -> void:
	SoundManager.play_bgm("battle_theme")
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	stage_manager.enemy_turn_ended.connect(_start_player_turn)
	
	hand.card_added_to_hand.connect(_on_card_added_to_hand)
	EventBus.enemy_selected.connect(_on_enemy_selected)
	EventBus.enemy_died.connect(_on_enemy_died)
	
	player.stats_updated.connect(_on_player_stats_updated)
	_on_player_stats_updated(player.current_hp, player.max_hp, player.shield, player.base_damage)
	stage_manager.wave_cleared.connect(_on_wave_cleared)
	stage_manager.round_won.connect(_on_round_won)
	
	player.coins_updated.connect(_on_coins_updated)
	current_round = 1
	is_first_turn = true
	player.reset_for_battle()
	
	deck_visual.pressed.connect(_on_deck_visual_pressed)
	discard_visual.pressed.connect(_on_discard_visual_pressed)
	close_deck_button.pressed.connect(_on_close_deck_pressed)
	_prepare_starting_deck()

func _on_coins_updated(c: int, h: int, o: int, n: int) -> void:
	c_label.text = "Carbon: " + str(c)
	h_label.text = "Hydrogen: " + str(h)
	o_label.text = "Oxygen: " + str(o)
	n_label.text = "Nitrogen: " + str(n)
	
	# (Opsional) Animasi ringan saat UI update
	var tween = create_tween()
	tween.tween_property($UI/TokenContainer, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property($UI/TokenContainer, "scale", Vector2.ONE, 0.1)

func _prepare_starting_deck() -> void:
	# Jika memori abadi masih kosong (Misal: baru mulai Lantai 1)
	if GameManager.player_deck.is_empty():
		print("Membuat deck awal untuk petualangan ini...")
		for i in range(15): # (Contoh: Deck awal berisi 15 kartu acak)
			var random_card: CardData = available_cards.pick_random()
			GameManager.player_deck.append(random_card)

	# Salin isi dari memori abadi ke sistem Deck untuk dipakai bertarung!
	for card in GameManager.player_deck:
		deck.add_card(card)
		
	_start_player_turn()

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
	if current_state != TurnState.PLAYER:
		print("Sabar, ini sedang giliran musuh!")
		_reject_play(clicked_ui)
		return
	
	if card_data.tipe == CardData.tipe_kartu.ATTACK:
		# Kita cek: Apakah targetnya kosong? ATAU apakah targetnya sudah keburu dihapus dari memori?
		if current_target == null or not is_instance_valid(current_target):
			print("Gagal: Anda belum memilih target atau target sudah mati!")
			_reject_play(clicked_ui)
			return # <--- BARIS INI SANGAT KRUSIAL! 
			# 'return' akan menghentikan seluruh fungsi di detik ini juga. 
			# Koin tidak akan dipotong, dan kartu tidak akan dibuang.
	
	# CEK DOMPET PEMAIN
	if player.can_afford(card_data):
		# 1. Bayar koinnya
		player.pay_for_card(card_data)
		
		# 2. Mainkan kartunya
		match card_data.tipe:
			CardData.tipe_kartu.SHIELD:
				player.gain_shield(card_data.effect_amount)
			CardData.tipe_kartu.ATTACK:
				# 1. KUMPULKAN TARGET (Single Target vs Multi Target)
				var targets: Array[EnemyBase] = []
				
				if card_data.is_multi_target:
					# Jika kartu AIR (Multi), ambil semua musuh yang masih hidup di panggung
					for child in stage_manager.get_children():
						if child is EnemyBase and not child.is_queued_for_deletion():
							targets.append(child)
				else:
					# Jika kartu FIRE / SHOCK (Single), pastikan ada target
					if current_target == null or not is_instance_valid(current_target):
						print("Gagal: Anda belum memilih target!")
						_reject_play(clicked_ui)
						return
					targets.append(current_target)
				
				# 2. EKSEKUSI DAMAGE & REAKSI KE SETIAP TARGET
				for target in targets:
					var final_damage = player.base_damage + card_data.effect_amount
					var reaction_occurred: bool = false
					
					# --- MESIN REAKSI ELEMENTAL PINTAR ---
					var incoming_el = card_data.attack_ailment
					
					if incoming_el != StatusAilment.ailment_type.None:
						for reaction_rule in active_reactions:
							# Jika ada kecocokan reaksi
							if incoming_el == reaction_rule.incoming_element and target.has_status(reaction_rule.existing_element):
								
								# Eksekusi resep reaksi! (Otomatis menyebarkan damage & menempelkan status baru)
								final_damage = reaction_rule.execute(target, stage_manager, final_damage)
								reaction_occurred = true
								break # Hentikan pencarian reaksi lain untuk elemen ini
					
					# Berikan damage final setelah dimodifikasi reaksi
					target.take_damage(final_damage)
					
					# --- ATURAN PENEMPELAN STATUS ---
					# Hanya tempelkan status bawaan kartu (misal: Wet/Fire) JIKA:
					# 1. Tidak terjadi reaksi (Elemen gagal dikonsumsi)
					# 2. Kartu tersebut memang memiliki status bawaan (Bukan trigger kosong)
					if not reaction_occurred and card_data.status_to_apply != null:
						target.apply_status(card_data.status_to_apply, card_data.status_to_apply.duration)
				
		# 3. Mainkan dan buang kartunya
		hand.remove_card(card_data)
		deck.add_to_discard(card_data)
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
	

func _show_card_viewer(cards_to_show: Array[CardData], title_text: String) -> void:
	panel_title_label.text = title_text
	
	for child in card_grid.get_children():
		child.queue_free()
		
	for card_data in cards_to_show:
		var card_instance = card_ui_scene.instantiate() as CardUI
		card_grid.add_child(card_instance)
		
		card_instance.setup(card_data)
		card_instance.is_preview = true 
		
		# --- ATURAN 4: JIKA SEDANG MEMILIH EFEK, KARTU BISA DIKLIK! ---
		if is_selecting_effect_target:
			card_instance.pressed.connect(_apply_effect_to_card.bind(card_data))
			
	# --- ATURAN 2: JIKA WAJIB PILIH TARGET, HILANGKAN TOMBOL CLOSE! ---
	if is_selecting_effect_target:
		close_deck_button.hide()
	else:
		close_deck_button.show()
		
	deck_backdrop.show()
	deck_view_panel.show()
	
	deck_backdrop.modulate.a = 0.0
	deck_view_panel.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(deck_backdrop, "modulate:a", 1.0, 0.2)
	tween.tween_property(deck_view_panel, "modulate:a", 1.0, 0.2)

## Dipanggil saat mengklik tombol DECK di kiri
func _on_deck_visual_pressed() -> void:
	print("Membuka Deck...")
	# Panggil fungsi serbaguna, masukkan array Deck
	_show_card_viewer(deck.cards, "SISA KARTU DECK")

## Dipanggil saat mengklik tombol DISCARD di kanan
func _on_discard_visual_pressed() -> void:
	print("Membuka Discard Pile...")
	# Panggil fungsi serbaguna, masukkan array Discard
	_show_card_viewer(deck.discard_pile, "TUMPUKAN BUANGAN")
	
func _on_close_deck_pressed() -> void:
	print("Menutup menu intip deck.")
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(deck_backdrop, "modulate:a", 0.0, 0.15)
	tween.tween_property(deck_view_panel, "modulate:a", 0.0, 0.15)
	
	# Sembunyikan node fisik setelah transparan penuh
	tween.chain().tween_callback(deck_view_panel.hide)
	tween.chain().tween_callback(deck_backdrop.hide)

func _on_card_removed_from_hand(card_data: CardData) -> void:
	pass

func _on_player_stats_updated(hp: int, max_hp: int, shield: int, _damage: int) -> void:
	# 1. Update HP
	player_hp_bar.max_value = max_hp
	var hp_tween = create_tween()
	hp_tween.tween_property(player_hp_bar, "value", hp, 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	if player_hp_label:
		player_hp_label.text = str(hp) + " / " + str(max_hp)
		
	# 2. Update Shield
	# Asumsi: Max Shield di UI disamakan dengan Max HP agar barnya rapi, 
	# atau Anda bisa set statis misal 50.
	player_shield_bar.max_value = max_hp 
	var shield_tween = create_tween()
	shield_tween.tween_property(player_shield_bar, "value", shield, 0.3).set_trans(Tween.TRANS_SINE)
	
	if player_shield_label:
		if shield > 0:
			player_shield_label.text = "Shield: " + str(shield)
			player_shield_bar.show() # Tampilkan jika ada shield
		else:
			player_shield_label.text = ""
			player_shield_bar.hide() # Sembunyikan bar jika shield habis (Opsional)

func _start_player_turn() -> void:
	current_state = TurnState.PLAYER
	print("\n--- GILIRAN PEMAIN DIMULAI ---")
	
	# Aktifkan tombol
	end_turn_button.disabled = true
	
	if is_first_turn:
		# Jika ini awal battle, jangan tambah token, cukup matikan flag-nya
		is_first_turn = false
	else:
		# Jika bukan turn pertama (artinya baru saja melewati giliran musuh)
		print("Ronde ", current_round, " selesai! Memberikan bonus ", current_round, " token.")
		player.gain_tokens(current_round)
		
		# Maju ke ronde berikutnya
		current_round += 1
	
	# Auto Draw Kartu: Tarik kartu sampai tangan penuh
	# Karena belum ada discard pile, kita tarik kartu sebanyak ruang kosong di tangan
	var cards_to_draw: int = hand.max_hand_size - hand.cards_in_hand.size()
	
	for i in range(cards_to_draw):
		await get_tree().create_timer(0.2).timeout 
		var drawn_card: CardData = deck.draw_card()
		if drawn_card != null:
			var success = hand.add_card(drawn_card)
			if not success:
				deck.cards.append(drawn_card)
	
	await get_tree().create_timer(0.5).timeout 
	end_turn_button.disabled = false

func _discard_hand_to_deck() -> void:
	# 1. Masukkan semua sisa kartu di tangan ke Discard Pile
	for card in hand.cards_in_hand:
		deck.add_to_discard(card)
		
	# 2. Kosongkan memori tangan
	hand.cards_in_hand.clear()
	
	# 3. Hapus visual kartu dari layar (HBoxContainer)
	for child in hand_container.get_children():
		child.queue_free()
		
	print("Sisa kartu di tangan dibuang ke Discard Pile.")

func _on_end_turn_pressed() -> void:
	if current_state != TurnState.PLAYER: return
	
	current_state = TurnState.ENEMY
	print("\n--- GILIRAN MUSUH DIMULAI ---")
	
	# Matikan UI agar pemain tidak bisa curang
	end_turn_button.disabled = true
	current_target = null # Reset target di akhir giliran
	
	_discard_hand_to_deck()
	# Perintahkan musuh untuk mulai bergerak
	stage_manager.execute_enemies_turn()

func _on_enemy_selected(enemy: EnemyBase) -> void:
	current_target = enemy
	print("BattleManager mencatat target baru: ", current_target.stats.enemy_name)

func _on_enemy_died(dead_enemy: EnemyBase) -> void:
	if current_target == dead_enemy:
		current_target = null
		print("Target hancur! Seleksi target direset.")
		
func _on_wave_cleared() -> void:
	# Bersihkan sisa kartu di tangan jika musuh terakhir mati di giliran pemain
	_discard_hand_to_deck()
	
	# Berikan kembali giliran ke pemain (Auto Draw akan berjalan di sini)
	_start_player_turn()

func _on_round_won() -> void:
	print("\nVICTORY! Semua musuh telah dikalahkan!")
	end_turn_button.disabled = true
	
	# Jeda sebelum layar reward muncul
	await get_tree().create_timer(1.5).timeout
	_show_reward_screen()

func _show_reward_screen() -> void:
	# 1. Berikan Shop Coins
	GameManager.shop_coins += 10
	
	# Bersihkan sisa grid (berjaga-jaga)
	for child in reward_card_grid.get_children():
		child.queue_free()
	
	# ===============================================
	# CABANG 1: HADIAH BATTLE NORMAL (PILIH KARTU)
	# ===============================================
	if GameManager.active_event_type == MapNodeData.NodeType.BATTLE_NORMAL:
		reward_title.text = "VICTORY!\n+10 Shop Coins (Total: " + str(GameManager.shop_coins) + ")\n\nPilih 1 Kartu Baru:"
		
		# Pastikan tombol skip muncul
		skip_button.show() 
		skip_button.text = "Lewati Kartu & Kembali ke Peta"
		
		var valid_reward_pool: Array[CardData] = []
		for card in available_cards:
			if card.can_be_reward == true: 
				valid_reward_pool.append(card)
		
		valid_reward_pool.shuffle()
		var choice_count = mini(3, valid_reward_pool.size())
		for i in range(choice_count):
			var card_data = valid_reward_pool[i]
			var card_ui = card_ui_scene.instantiate() as CardUI
			reward_card_grid.add_child(card_ui)
			card_ui.setup(card_data)
			card_ui.is_preview = true 
			card_ui.pressed.connect(_on_reward_card_chosen.bind(card_data))
			
	# ===============================================
	# CABANG 2: HADIAH BATTLE HARD (PILIH EFEK)
	# ===============================================
	elif GameManager.active_event_type == MapNodeData.NodeType.BATTLE_HARD:
		reward_title.text = "HARD VICTORY!\n+10 Shop Coins (Total: " + str(GameManager.shop_coins) + ")\n\nPILIH 1 EFEK UNTUK KARTUMU:"
		
		# ATURAN 2: TIDAK BISA SKIP / SIMPAN!
		skip_button.hide() 
		
		# Buat 3 Tombol Efek (Berupa Button biasa agar beda dengan kartu)
		var effects = ["UNSTABLE", "VOLATILE", "CLONE"]
		var effect_desc = [
			"UNSTABLE\n(Damage diri saat dipakai)", 
			"VOLATILE\n(Hancur setelah dipakai)", 
			"CLONE\n(Gandakan kartu ke Deck)"
		]
		
		for i in range(effects.size()):
			var btn = Button.new()
			btn.text = effect_desc[i]
			btn.custom_minimum_size = Vector2(180, 250) # Ukuran mirip kartu
			
			# Sihir Godot: Hubungkan tombol ke fungsi dan bawa nama efeknya!
			btn.pressed.connect(_on_effect_chosen.bind(effects[i]))
			reward_card_grid.add_child(btn)
			
	# (Opsional) Jika Boss, biarkan skip sementara
	else:
		reward_title.text = "VICTORY!\n+10 Shop Coins"
		skip_button.show()
		skip_button.text = "Kembali ke Peta"
		
	# Tampilkan layar dan sambungkan tombol skip (jika ada)
	if not skip_button.pressed.is_connected(_return_to_map):
		skip_button.pressed.connect(_return_to_map)
		
	reward_backdrop.show()

func _on_reward_card_chosen(chosen_card: CardData) -> void:
	print("Kartu diambil: ", chosen_card.card_name)
	
	# SIMPAN KE MEMORI ABADI!
	GameManager.player_deck.append(chosen_card)
	
	# Langsung pulang ke peta setelah memilih
	_return_to_map()

## --- FUNGSI MENGAMBIL EFEK (MEMBUKA DECK) ---
func _on_effect_chosen(effect_name: String) -> void:
	print("Efek dipilih: ", effect_name)
	
	# Kunci state kita ke mode "Memilih Target"
	active_effect_choice = effect_name
	is_selecting_effect_target = true
	
	# Sembunyikan layar reward
	reward_backdrop.hide()
	
	# Daur ulang Deck Viewer untuk memilih kartu target!
	_show_card_viewer(GameManager.player_deck, "PILIH 1 KARTU UNTUK DIBERIKAN EFEK: " + effect_name)

## --- FUNGSI MENERAPKAN EFEK KE KARTU ---
func _apply_effect_to_card(target_card: CardData) -> void:
	print("Menerapkan efek ", active_effect_choice, " ke kartu ", target_card.card_name)
	
	match active_effect_choice:
		"UNSTABLE":
			target_card.effect = CardData.effect_kartu.UNSTABLE
		"VOLATILE":
			target_card.effect = CardData.effect_kartu.VOLATILE
		"CLONE":
			# PENTING: Gunakan duplicate(true) agar kloningan menjadi entitas 
			# resource yang terpisah secara sempurna, bukan sekadar referensi bayangan!
			var cloned_card = target_card.duplicate(true)
			GameManager.player_deck.append(cloned_card)
			
	# Reset state kembali ke normal agar aman untuk pertarungan berikutnya
	is_selecting_effect_target = false
	active_effect_choice = ""
	
	# Pulang ke peta setelah selesai!
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
