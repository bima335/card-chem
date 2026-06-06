class_name AilmentReaction
extends Resource

@export var existing_element: StatusAilment.ailment_type
@export var incoming_element: StatusAilment.ailment_type

# TAMBAHAN BARU: Status hasil dari reaksi ini (Opsional)
@export var resulting_status: StatusAilment 

func execute(target: EnemyBase, stage_manager: StageManager, current_damage: int) -> int:
	# Jika ada status hasil reaksi yang dislotkan di Inspector, tempelkan ke musuh!
	if resulting_status != null:
		target.apply_status(resulting_status, resulting_status.duration)
		
	return current_damage
