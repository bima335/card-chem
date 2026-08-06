class_name WaveGenerator
extends RefCounted

static func generate_wave(node_type: int, pool_enemies: Array[EnemyStat]) -> Array[EnemyStat]:
	var generated_wave: Array[EnemyStat] = []
	
	if pool_enemies.is_empty():
		push_error("WaveGenerator: pool_enemies kosong!")
		return generated_wave
		
	if node_type == 0:
		# Filter musuh bertag SMALL
		var small_pool: Array[EnemyStat] = pool_enemies.filter(func(e): return e.tag == EnemyStat.EnemyTag.SMALL)
		
		if small_pool.is_empty():
			# Fallback ke seluruh pool jika tidak ada tag SMALL
			small_pool = pool_enemies
			
		var enemy_count: int = randi_range(1, 3)
		for i in range(enemy_count):
			generated_wave.append(small_pool.pick_random())
			
	elif node_type == 1:
		# Filter musuh bertag BIG
		var big_pool: Array[EnemyStat] = pool_enemies.filter(func(e): return e.tag == EnemyStat.EnemyTag.BIG)
		
		if big_pool.is_empty():
			push_warning("WaveGenerator: Tidak menemukan musuh BIG! Menggunakan musuh SMALL sebagai cadangan.")
			big_pool = pool_enemies.filter(func(e): return e.tag == EnemyStat.EnemyTag.SMALL)
			
		if not big_pool.is_empty():
			generated_wave.append(big_pool.pick_random())
			
		# Kesempatan 50% memanggil 1 musuh kroco (SMALL) tambahan
		if randf() > 0.5:
			var small_pool: Array[EnemyStat] = pool_enemies.filter(func(e): return e.tag == EnemyStat.EnemyTag.SMALL)
			if not small_pool.is_empty():
				generated_wave.append(small_pool.pick_random())
				
	return generated_wave
