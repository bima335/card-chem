# event_scene.gd
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	# Hubungkan tombol kembali ke fungsi
	back_button.pressed.connect(_on_back_pressed)
	
	# Cek tipe event yang dititipkan di GameManager
	match GameManager.active_event_type:
		
		# --- LOGIKA SIKLUS REST AREA ---
		MapNodeData.NodeType.REST:
			title_label.text = "=== TEMPAT PERISTIRAHATAN ==="
			
			# Kalkulasi pemulihan HP secara aman
			var old_hp: int = GameManager.player_current_hp
			GameManager.player_current_hp = clampi(GameManager.player_current_hp + 15, 0, GameManager.player_max_hp)
			var healed_amount: int = GameManager.player_current_hp - old_hp
			
			desc_label.text = "Kamu duduk dengan tenang di dekat api unggun yang hangat...\n"
			desc_label.text += "HP pulih sebanyak [ +" + str(healed_amount) + " ] !\n"
			desc_label.text += "HP Sekarang: " + str(GameManager.player_current_hp) + " / " + str(GameManager.player_max_hp)
			
			# Sesuai permintaan: Rest otomatis jalan tanpa tombol. Kita beri jeda teaterikal 3 detik lalu pulang.
			back_button.hide() 
			await get_tree().create_timer(3.0).timeout
			_on_back_pressed()
			
		# --- LOGIKA SIKLUS SHOP ---
		MapNodeData.NodeType.SHOP:
			title_label.text = "=== TOKO RAHASIA ==="
			desc_label.text = "Seorang pedagang bertopeng emas menyapamu misterius.\n"
			desc_label.text += "(Fasilitas perdagangan barang belum dikembangkan)."
			
			# Sesuai permintaan: Toko membutuhkan tombol manual untuk pulang
			back_button.show()

func _on_back_pressed() -> void:
	print("Meninggalkan ruangan, kembali ke peta.")
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
