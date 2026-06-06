class_name WaveGenerator
extends RefCounted

static func generate_wave(node_type: int, pool_enemies: Array[EnemyStat]) -> Array[EnemyStat]:
	var generated_wave: Array[EnemyStat] = []
	var filtered_pool: Array[EnemyStat] = []
	
	if node_type == 0:
		for enemy in pool_enemies:
			if enemy.tag == EnemyStat.EnemyTag.SMALL:
				filtered_pool.append(enemy)
		
		var enemy_count = randi_range(1, 3)
		for i in range(enemy_count):
			if not filtered_pool.is_empty():
				generated_wave.append(filtered_pool.pick_random())
	
	elif node_type == 1:
		for enemy in pool_enemies:
			if enemy.tag == EnemyStat.EnemyTag.BIG:
				filtered_pool.append(enemy)
		
		# --- RENCANA CADANGAN (FALLBACK) ---
		# Jika ternyata tidak ada musuh BIG yang terdaftar, ambil musuh SMALL!
		if filtered_pool.is_empty():
			push_warning("WaveGenerator: Tidak menemukan musuh BIG! Menggunakan musuh SMALL sebagai cadangan.")
			for enemy in pool_enemies:
				if enemy.tag == EnemyStat.EnemyTag.SMALL:
					filtered_pool.append(enemy)
					
		# Masukkan 1 musuh utama
		if not filtered_pool.is_empty():
			generated_wave.append(filtered_pool.pick_random())
			
		# Kesempatan 50% memanggil 1 musuh kroco (kacung) tambahan
		if randf() > 0.5:
			var small_pool = pool_enemies.filter(func(e): return e.tag == EnemyStat.EnemyTag.SMALL)
			if not small_pool.is_empty():
				generated_wave.append(small_pool.pick_random())
	
	return generated_wave
