# event_scene.gd
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var back_button: Button = $VBoxContainer/BackButton

const REST_HEAL_AMOUNT: int = 15

func _ready() -> void:
	SoundManager.play_bgm("event")
	back_button.pressed.connect(_on_back_pressed)
	
	match GameManager.active_event_type:
		MapNodeData.NodeType.REST:
			_handle_rest_event()
		MapNodeData.NodeType.SHOP:
			_handle_shop_event()

func _handle_rest_event() -> void:
	#title_label.text = "=== TEMPAT PERISTIRAHATAN ==="
	#
	#var healed_amount: int = GameManager.heal_player(REST_HEAL_AMOUNT)
	#
	#desc_label.text = "Kamu duduk dengan tenang di dekat api unggun yang hangat...\n"
	#desc_label.text += "HP pulih sebanyak [ +" + str(healed_amount) + " ] !\n"
	#desc_label.text += "HP Sekarang: " + str(GameManager.player_current_hp) + " / " + str(GameManager.player_max_hp)
	
	back_button.hide()
	await get_tree().create_timer(3.0).timeout
	_on_back_pressed()

func _handle_shop_event() -> void:
	title_label.text = "=== TOKO RAHASIA ==="
	desc_label.text = "Seorang pedagang bertopeng emas menyapamu misterius.\n"
	desc_label.text += "(Fasilitas perdagangan barang belum dikembangkan)."
	back_button.show()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
