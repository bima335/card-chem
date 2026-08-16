extends Control

@export var gold_boss_stat: EnemyStat
@export_file("*.tscn") var battle_scene_path: String = "res://main/battle_scene.tscn"

@onready var fight_button: Button = $TextureRect/FightButton
@onready var skip_button: Button = $TextureRect/SkipButton
@onready var gold_label: Label = $TextureRect/GoldLabel

func _ready() -> void:
	gold_label.text = str(GameManager.shop_coins)
	_connect_signals()

func _connect_signals() -> void:
	fight_button.pressed.connect(_on_fight_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)

func _on_fight_button_pressed() -> void:
	if gold_boss_stat == null:
		push_error("GoldEvent: Resource gold_boss_stat belum di-assign di Inspector!")
		return

	GameManager.current_wave_data.clear()
	GameManager.current_wave_data.append(gold_boss_stat)
	GameManager.active_event_type = MapNodeData.NodeType.BOSS
	GameManager.is_gold_boss = true
	get_tree().change_scene_to_file(battle_scene_path)

func _on_skip_button_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")
