class_name ShopManager
extends Control

# --- REFERENSI TOMBOL BEBAS ---
@onready var btn_buy: TextureButton = $Interactables/BtnBuy
@onready var btn_heal: TextureButton = $Interactables/BtnHeal
@onready var btn_sell: TextureButton = $Interactables/BtnSell
@onready var btn_leave: Button = $BtnLeave

# --- REFERENSI UI OVERLAY ---
@onready var coin_label: Label = $UI_Overlay/CoinContainer/CoinLabel
@onready var buy_panel: PanelContainer = $UI_Overlay/BuyPanel
@onready var sell_panel: PanelContainer = $UI_Overlay/SellPanel

# --- PENGATURAN HARGA HEAL ---
const HEAL_PRICE: int = 20
const HEAL_AMOUNT: int = 15

func _ready() -> void:
	# Putar musik yang santai dan nyentrik untuk toko
	SoundManager.play_bgm("shop_theme")
	
	_update_coin_display()
	
	# Sambungkan tombol-tombol melayang Anda
	btn_buy.pressed.connect(_on_btn_buy_pressed)
	btn_heal.pressed.connect(_on_btn_heal_pressed)
	btn_sell.pressed.connect(_on_btn_sell_pressed)
	btn_leave.pressed.connect(_on_btn_leave_pressed)

func _update_coin_display() -> void:
	coin_label.text = "Koin: " + str(GameManager.shop_coins)
	
	# Animasi UI membal saat koin berubah
	var tween = create_tween()
	coin_label.scale = Vector2(1.3, 1.3)
	tween.tween_property(coin_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)

# ==========================================
# LOGIKA TOMBOL TOKO
# ==========================================

func _on_btn_buy_pressed() -> void:
	print("Membuka menu Beli...")
	sell_panel.hide()
	
	# (Nanti kita panggil fungsi pembuat daftar kartu shoppable & efek di sini)
	
	buy_panel.show()

func _on_btn_heal_pressed() -> void:
	print("Mencoba membeli Heal...")
	if GameManager.shop_coins >= HEAL_PRICE:
		if GameManager.player_current_hp < GameManager.player_max_hp:
			GameManager.shop_coins -= HEAL_PRICE
			
			# Tambahkan HP dan pastikan tidak melebihi batas maksimal
			GameManager.player_current_hp += HEAL_AMOUNT
			GameManager.player_current_hp = clampi(GameManager.player_current_hp, 0, GameManager.player_max_hp)
			
			_update_coin_display()
			SoundManager.play_sfx("heal_success")
			print("Pemain disembuhkan! HP sekarang: ", GameManager.player_current_hp)
		else:
			print("HP sudah penuh!")
			SoundManager.play_sfx("error")
	else:
		print("Koin tidak cukup untuk Heal!")
		SoundManager.play_sfx("error")

func _on_btn_sell_pressed() -> void:
	print("Membuka menu Jual...")
	buy_panel.hide()
	
	# (Nanti kita panggil fungsi pembaca GameManager.player_deck di sini)
	
	sell_panel.show()

func _on_btn_leave_pressed() -> void:
	print("Meninggalkan toko, kembali ke peta...")
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
