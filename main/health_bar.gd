class_name EnemyHealthBar
extends Control

@onready var health_bar: TextureProgressBar = $HealthBarUnder
@onready var shield_bar: TextureProgressBar = $ShieldBar
@onready var hp_label: Label = $HPLabel

func init_health(max_hp: int, max_shield: int) -> void:
	health_bar.max_value = max_hp
	shield_bar.max_value = max_hp
	
	update_values(max_hp, max_shield)

func update_values(current_hp: int, current_shield: int) -> void:
	# Animasi bar dengan Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(health_bar, "value", current_hp, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(shield_bar, "value", current_shield, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Sembunyikan bar shield jika nilainya 0
	shield_bar.visible = current_shield > 0
	
	# Update Teks Label
	_update_label_text(current_hp, health_bar.max_value, current_shield)

func _update_label_text(current_hp: int, max_hp: int, current_shield: int) -> void:
	if current_shield > 0:
		hp_label.text = "%d/%d (+%d shield)" % [current_hp, max_hp, current_shield]
	else:
		hp_label.text = "%d/%d" % [current_hp, max_hp]