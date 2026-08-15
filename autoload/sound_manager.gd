extends Node
const MAX_POOL_SIZE: int = 12 

var sfx_players: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer
var current_bgm_track: String = ""

var sfx_database: Dictionary = {
	"card_hover": preload("res://assets/audio/sfx/cards/Select/GP_Select_3.wav"),
	"enemy_select": preload("res://assets/audio/sfx/ui/UI_Select_1.wav"),
}

var bgm_database: Dictionary = {
	"battle_theme": preload("res://assets/audio/bgm/Go!_Fight!_Win!.mp3"),
	"battle": preload("res://assets/audio/bgm/battle_general.mp3"),
	"ferrum": preload("res://assets/audio/bgm/Ferrum_Env.mp3"),
	"cobalt": preload("res://assets/audio/bgm/Cobalt_Env.mp3"),
	"neon": preload("res://assets/audio/bgm/Neon_Env.mp3"),
	"rest": preload("res://assets/audio/bgm/The_Rest.mp3"),
	"shop": preload("res://assets/audio/bgm/The_Lab.mp3"),
	"main_menu": preload("res://assets/audio/bgm/main_menu.mp3"),
	"aurum": preload("res://assets/audio/bgm/Aurum_Gold_Env.mp3"),
	"event": preload("res://assets/audio/bgm/event_node.mp3"),
	"intro_theme": preload("res://assets/audio/bgm/story.mp3"),
}

func _ready() -> void:
	for i in range(MAX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music" # Arahkan ke jalur Music yang kita buat di editor
	add_child(bgm_player)

func play_sfx(sound_name: String, pitch_variance: float = 0.0) -> void:
	if not sfx_database.has(sound_name):
		push_warning("SoundManager: Suara '" + sound_name + "' tidak ditemukan di database!")
		return
		
	var stream_to_play = sfx_database[sound_name]
	
	for player in sfx_players:
		if not player.playing:
			_play_on_player(player, stream_to_play, pitch_variance)
			return
			
	push_warning("SoundManager: Pool Penuh! Menimpa suara yang sedang berjalan.")
	_play_on_player(sfx_players[0], stream_to_play, pitch_variance)

func _play_on_player(player: AudioStreamPlayer, stream: AudioStream, variance: float) -> void:
	player.stream = stream
	
	if variance > 0.0:
		player.pitch_scale = randf_range(1.0 - variance, 1.0 + variance)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	if not bgm_database.has(track_name):
		push_warning("SoundManager: BGM '" + track_name + "' tidak ditemukan!")
		return
		
	# Cerdas: Jika musik yang diminta SAMA dengan yang sedang main, biarkan saja!
	if current_bgm_track == track_name and bgm_player.playing:
		return 
		
	current_bgm_track = track_name
	var new_stream = bgm_database[track_name]
	
	# Transisi Crossfade yang Halus!
	if bgm_player.playing and fade_duration > 0.0:
		var tween = create_tween()
		# 1. Fade out volume ke -40 dB (sangat pelan/senyap)
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration / 2.0)
		
		# 2. Ganti kaset setelah senyap
		tween.tween_callback(func():
			bgm_player.stream = new_stream
			bgm_player.play()
		)
		
		# 3. Fade in volume kembali ke 0 dB (normal)
		tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration / 2.0)
	else:
		# Mainkan langsung jika tidak ada musik sebelumnya
		bgm_player.stream = new_stream
		bgm_player.volume_db = 0.0
		bgm_player.play()

func stop_bgm(fade_duration: float = 1.0) -> void:
	if not bgm_player.playing: return
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
	tween.tween_callback(bgm_player.stop)
	current_bgm_track = ""
