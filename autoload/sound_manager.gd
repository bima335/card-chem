extends Node

const MAX_POOL_SIZE: int = 12 

var sfx_players: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer
var current_bgm_track: String = ""

var sfx_database: Dictionary = {}
var bgm_database: Dictionary = {}

var sfx_paths: Dictionary = {
	"card_hover": "res://assets/audio/sfx/cards/Select/GP_Select_3.wav",
	"enemy_select": "res://assets/audio/sfx/ui/UI_Select_1.wav",
	"ui_click": "res://assets/audio/sfx/ui/UI_Click_2.wav",
	"ui_hover": "res://assets/audio/sfx/ui/UI_Click_1.wav",
	"hurt": "res://assets/audio/sfx/damage/swipe.wav"
}

var bgm_paths: Dictionary = {
	"battle_theme": "res://assets/audio/bgm/Go!_Fight!_Win!.mp3",
	"battle": "res://assets/audio/bgm/battle_general.mp3",
	"ferrum": "res://assets/audio/bgm/Ferrum_Env.mp3",
	"cobalt": "res://assets/audio/bgm/Cobalt_Env.mp3",
	"neon": "res://assets/audio/bgm/Neon_Env.mp3",
	"rest": "res://assets/audio/bgm/The_Rest.mp3",
	"shop": "res://assets/audio/bgm/The_Lab.mp3",
	"main_menu": "res://assets/audio/bgm/main_menu.mp3",
	"aurum": "res://assets/audio/bgm/Aurum_Gold_Env.mp3",
	"event": "res://assets/audio/bgm/event_node.mp3",
	"intro_theme": "res://assets/audio/bgm/story.mp3",
	"end": "res://assets/audio/bgm/end.mp3"
}

func _get_or_load_stream(database: Dictionary, key: String, path_by_name: Dictionary) -> AudioStream:
	if database.has(key):
		return database[key]

	if not path_by_name.has(key):
		push_warning("SoundManager: Audio '%s' tidak ditemukan di path database!" % key)
		return null

	var stream = load(path_by_name[key]) as AudioStream
	if stream == null:
		push_warning("SoundManager: Gagal memuat audio '%s' dari '%s'" % [key, path_by_name[key]])
		return null

	database[key] = stream
	return stream

func _ready() -> void:
	for i in range(MAX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
		
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)

func set_master_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func set_bgm_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func set_sfx_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func play_sfx(sound_name: String, pitch_variance: float = 0.0) -> void:
	var stream_to_play = _get_or_load_stream(sfx_database, sound_name, sfx_paths)
	if stream_to_play == null:
		return

	for player in sfx_players:
		if not player.playing:
			_play_on_player(player, stream_to_play, pitch_variance)
			return

	_play_on_player(sfx_players[0], stream_to_play, pitch_variance)

func _play_on_player(player: AudioStreamPlayer, stream: AudioStream, variance: float) -> void:
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - variance, 1.0 + variance) if variance > 0.0 else 1.0
	player.play()

func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	var new_stream = _get_or_load_stream(bgm_database, track_name, bgm_paths)
	if new_stream == null:
		return

	if current_bgm_track == track_name and bgm_player.playing:
		return

	current_bgm_track = track_name

	if bgm_player.playing and fade_duration > 0.0:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration / 2.0)
		tween.tween_callback(func():
			bgm_player.stream = new_stream
			bgm_player.play()
		)
		tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration / 2.0)
	else:
		bgm_player.stream = new_stream
		bgm_player.volume_db = 0.0
		bgm_player.play()

func stop_bgm(fade_duration: float = 1.0) -> void:
	if not bgm_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
	tween.tween_callback(bgm_player.stop)
	current_bgm_track = ""

func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func set_bgm_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_sfx_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("SoundManager: Bus audio '%s' tidak ditemukan!" % bus_name)
		return

	var is_muted: bool = linear_value <= 0.0001
	AudioServer.set_bus_mute(bus_index, is_muted)

	if not is_muted:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))
