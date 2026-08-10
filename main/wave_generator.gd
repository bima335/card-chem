class_name WaveGenerator
extends RefCounted

static func generate_wave(
	node_type: int, 
	section: SectionData, 
	global_common: Array[EnemyStat], 
	global_elite: Array[EnemyStat]
) -> Array[EnemyStat]:
	
	var generated_wave: Array[EnemyStat] = []
	
	if section == null:
		push_error("WaveGenerator: SectionData bernilai null!")
		return generated_wave

	match node_type:
		0: # Normal Battle (1 Exclusive Common + 1 Global Common)
			_append_random_enemy(generated_wave, section.exclusive_common, "Exclusive Common")
			_append_random_enemy(generated_wave, global_common, "Global Common")
			
		1: # Hard Battle (1 Exclusive Elite + 1 Global Elite)
			_append_random_enemy(generated_wave, section.exclusive_elite, "Exclusive Elite")
			_append_random_enemy(generated_wave, global_elite, "Global Elite")

		2: # Boss Battle (1 Exclusive Boss)
			_append_random_enemy(generated_wave, section.exclusive_boss, "Exclusive Boss")

	return generated_wave

static func _append_random_enemy(target_array: Array[EnemyStat], source_pool: Array[EnemyStat], pool_name: String) -> void:
	if not source_pool.is_empty():
		target_array.append(source_pool.pick_random())
	else:
		push_warning("WaveGenerator: Pool %s kosong saat melakukan generation!" % pool_name)
