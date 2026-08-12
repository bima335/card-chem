extends TextureProgressBar

func update_health(current_hp: int, max_hp: int) -> void:
	max_value = max_hp
	value = current_hp

func update_health_smooth(new_hp: int) -> void:
	var tween = create_tween()
	tween.tween_property(self, "value", new_hp, 0.2).set_trans(Tween.TRANS_SINE)