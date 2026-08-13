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
		0: # Normal Battle (2-3 Exclusive Common)
			var target_count: int = randi_range(2, 3)
			_append_random_enemies_from_pool(generated_wave, section.exclusive_common, target_count, "Exclusive Common")
			
		1: # Hard Battle (1 Exclusive Elite + 1 Global Elite)
			_append_random_enemy(generated_wave, section.exclusive_elite, "Exclusive Elite")
			_append_random_enemy(generated_wave, global_elite, "Global Elite")

		2: # Boss Battle (1 Exclusive Boss)
			_append_random_enemy(generated_wave, section.exclusive_boss, "Exclusive Boss")

	return generated_wave


static func _append_random_enemies_from_pool(
	target_array: Array[EnemyStat], 
	source_pool: Array[EnemyStat], 
	count: int, 
	pool_name: String
) -> void:
	if source_pool.is_empty():
		push_warning("WaveGenerator: Pool %s kosong saat melakukan generation!" % pool_name)
		return

	for i in range(count):
		target_array.append(source_pool.pick_random())


static func _append_random_enemy(
	target_array: Array[EnemyStat], 
	source_pool: Array[EnemyStat], 
	pool_name: String
) -> void:
	_append_random_enemies_from_pool(target_array, source_pool, 1, pool_name)
