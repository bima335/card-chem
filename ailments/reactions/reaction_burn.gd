class_name ReactionExplode
extends AilmentReaction

@export var is_aoe: bool = false
@export var bonus_damage: int = 10
@export var splash_damage: int = 5

func execute(target: EnemyBase, stage_manager: StageManager, current_damage: int) -> int:
	print("🔥REAKSI: BURNT!")
	#SoundManager.play_sfx("explode")
	
	target.remove_status(existing_element)
	
	if is_aoe:
		# Panggil semua anak dari StageManager (semua musuh di panggung)
		for child in stage_manager.get_children():
			# Pastikan itu musuh, BUKAN target utama, dan belum mati
			if child is EnemyBase and child != target and not child.is_queued_for_deletion():
				print("💥 Ledakan menyambar: ", child.stats.enemy_name, " sebesar ", splash_damage, " damage!")
				child.take_damage(splash_damage)
				
				# (Opsional) Jika ledakan ini sangat dahsyat, Anda bahkan bisa
				# menempelkan efek Burnt ke musuh di sekitarnya juga!
				# if resulting_status != null:
				#     child.apply_status(resulting_status.ailment, resulting_status.duration)
	
	# 3. Kembalikan damage untuk target utama (damage dasar kartu + bonus ledakan)
	return super.execute(target, stage_manager, current_damage + bonus_damage)
