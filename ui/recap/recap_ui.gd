# recap_ui.gd
class_name RecapUI
extends Control

@export var victory_texture: Texture2D
@export var defeat_texture: Texture2D

@onready var background: TextureRect = $Background

@onready var node_count_recap: Label = $NodeCountRecap
@onready var total_damage_recap: Label = $TotalDamageRecap
@onready var damage_taken_recap: Label = $DamageTakenRecap
@onready var total_gold_recap: Label = $TotalGoldRecap
@onready var card_got_recap: Label = $CardGotRecap

@onready var enemy_defeated: Label = $EnemyDefeated
@onready var boss_defeated: Label = $BossDefeated
@onready var total_damage: Label = $TotalDamage
@onready var one_hit_damage: Label = $OneHitDamage
@onready var damage_taken: Label = $DamageTaken
@onready var total_gold: Label = $TotalGold
@onready var card_got: Label = $CardGot
@onready var discard_total: Label = $DiscardTotal
@onready var card_played: Label = $CardPlayed
@onready var blessing_got: Label = $BlessingGot

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup_recap(is_victory: bool) -> void:
	_update_background(is_victory)
	_populate_statistics()


func _update_background(is_victory: bool) -> void:
	if is_victory and victory_texture != null:
		background.texture = victory_texture
	elif not is_victory and defeat_texture != null:
		background.texture = defeat_texture


func _populate_statistics() -> void:
	RecapManager.sync_map_progress_from_gamemanager()

	var damage_val: String = str(RecapManager.total_damage_dealt)
	var taken_val: String = str(RecapManager.total_damage_taken)
	var gold_val: String = str(RecapManager.current_gold)
	var cards_val: String = str(RecapManager.total_cards_obtained)

	node_count_recap.text = str(RecapManager.highest_node_reached)
	total_damage_recap.text = damage_val
	damage_taken_recap.text = taken_val
	total_gold_recap.text = gold_val
	card_got_recap.text = cards_val

	enemy_defeated.text = str(RecapManager.total_enemies_defeated)
	boss_defeated.text = str(RecapManager.total_bosses_defeated)
	total_damage.text = damage_val
	one_hit_damage.text = str(RecapManager.biggest_one_hit_damage)
	damage_taken.text = taken_val
	total_gold.text = gold_val
	card_got.text = cards_val
	discard_total.text = str(RecapManager.total_cards_discarded)
	card_played.text = str(RecapManager.total_cards_played)
	blessing_got.text = str(RecapManager.total_blessings_obtained)


func _on_continue_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
