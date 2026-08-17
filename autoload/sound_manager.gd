extends Node

const MAX_POOL_SIZE: int = 12
const BGM_DUCK_AMOUNT_DB: float = 10.0
var _bgm_is_ducked: bool = false 

var sfx_players: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var _active_voice_playlist: String = ""
var current_bgm_track: String = ""

var sfx_database: Dictionary = {
	"card_hover": preload("res://assets/audio/sfx/cards/Select/GP_Select_3.wav"),
	"enemy_select": preload("res://assets/audio/sfx/ui/UI_Select_1.wav"),
	"ui_click": preload("res://assets/audio/sfx/ui/UI_Click_2.wav"),
	"ui_hover": preload("res://assets/audio/sfx/ui/UI_Click_1.wav")
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
	"end": preload("res://assets/audio/bgm/end.mp3"),
	"hurt": preload("res://assets/audio/sfx/damage/swipe.wav")
}

var voice_database: Dictionary = {
	"cobalt_intro": preload("res://assets/audio/voiceline/cobalt/Intro_Cobalt.mp3"),
	"cobalt_end": preload("res://assets/audio/voiceline/cobalt/end_cobalt.mp3"),
	"ferrum_intro": preload("res://assets/audio/voiceline/ferrum/intro_ferrum.mp3"),
	"ferrum_end": preload("res://assets/audio/voiceline/ferrum/end_ferrum.mp3"),
	"aurum_intro": preload("res://assets/audio/voiceline/aurum/intro_aurum.mp3"),
	"aurum_end": preload("res://assets/audio/voiceline/aurum/end_aurum.mp3"),
	"neon_intro": preload("res://assets/audio/voiceline/neon/intro_neon.mp3"),
	"neon_end": preload("res://assets/audio/voiceline/neon/end_neon.mp3"),
}

var voice_playlists: Dictionary = {
	"cobalt_main": [
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_01.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_02.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_03.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_04.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_05.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_06.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_07.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_08.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_09.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_10.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_11.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_12.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_13.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_14.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_15.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_16.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_17.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_18.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_19.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_20.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_21.mp3"),
		preload("res://assets/audio/voiceline/cobalt/main_cobalt_22.mp3"),
	],
	"ferrum_main": [
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_01.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_02.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_03.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_04.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_05.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_06.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_07.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_08.mp3"),
	preload("res://assets/audio/voiceline/ferrum/main_ferrum_09.mp3"),
	],
	"aurum_main": [
	preload("res://assets/audio/voiceline/aurum/main_aurum_01.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_02.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_03.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_04.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_05.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_06.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_07.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_08.mp3"),
	preload("res://assets/audio/voiceline/aurum/main_aurum_09.mp3")
	],
	"neon_main": [
	preload("res://assets/audio/voiceline/neon/main_neon_01.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_02.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_03.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_04.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_05.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_06.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_07.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_08.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_09.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_10.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_11.mp3"),
	preload("res://assets/audio/voiceline/neon/main_neon_12.mp3")
	]
}



func _ready() -> void:
	for i in range(MAX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
		
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	add_child(bgm_player)
	
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "SFX"
	add_child(voice_player)

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
	player.pitch_scale = randf_range(1.0 - variance, 1.0 + variance) if variance > 0.0 else 1.0
	player.play()

func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	if not bgm_database.has(track_name):
		push_warning("SoundManager: BGM '" + track_name + "' tidak ditemukan!")
		return
		
	if current_bgm_track == track_name and bgm_player.playing:
		return 
		
	current_bgm_track = track_name
	var new_stream = bgm_database[track_name]
	
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

func play_voice_once(track_name: String, on_finished: Callable = Callable()) -> void:
	if not voice_database.has(track_name):
		push_warning("SoundManager: Voice '" + track_name + "' tidak ditemukan!")
		return
	_active_voice_playlist = ""
	voice_player.stream = voice_database[track_name]
	_duck_bgm()
	voice_player.play()
	voice_player.finished.connect(_unduck_bgm, CONNECT_ONE_SHOT)
	if on_finished.is_valid():
		voice_player.finished.connect(on_finished, CONNECT_ONE_SHOT)

func play_random_voice_playlist(playlist_name: String) -> void:
	if not voice_playlists.has(playlist_name):
		push_warning("SoundManager: Voice playlist '" + playlist_name + "' tidak ditemukan!")
		return
	_active_voice_playlist = playlist_name
	if not voice_player.finished.is_connected(_on_voice_finished):
		voice_player.finished.connect(_on_voice_finished)
	var tracks: Array = voice_playlists[playlist_name]
	voice_player.stream = tracks.pick_random()
	_duck_bgm()
	voice_player.play()

func _on_voice_finished() -> void:
	_unduck_bgm()
	if _active_voice_playlist != "":
		var delay: float = randf_range(12.0, 20.0)
		await get_tree().create_timer(delay).timeout
		if _active_voice_playlist != "":
			play_random_voice_playlist(_active_voice_playlist)

func stop_voice() -> void:
	_active_voice_playlist = ""
	if voice_player.finished.is_connected(_on_voice_finished):
		voice_player.finished.disconnect(_on_voice_finished)
	voice_player.stop()
	_unduck_bgm()
	
func _duck_bgm(duration: float = 0.25) -> void:
	if _bgm_is_ducked:
		return
	_bgm_is_ducked = true
	var bus_idx = AudioServer.get_bus_index("Music")
	var current_db = AudioServer.get_bus_volume_db(bus_idx)
	var tween = create_tween()
	tween.tween_method(func(db): AudioServer.set_bus_volume_db(bus_idx, db), current_db, current_db - BGM_DUCK_AMOUNT_DB, duration)

func _unduck_bgm(duration: float = 0.25) -> void:
	if not _bgm_is_ducked:
		return
	_bgm_is_ducked = false
	var bus_idx = AudioServer.get_bus_index("Music")
	var current_db = AudioServer.get_bus_volume_db(bus_idx)
	var tween = create_tween()
	tween.tween_method(func(db): AudioServer.set_bus_volume_db(bus_idx, db), current_db, current_db + BGM_DUCK_AMOUNT_DB, duration)

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
