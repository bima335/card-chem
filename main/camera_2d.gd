class_name ShakeCamera2D
extends Camera2D

@export var max_offset: Vector2 = Vector2(30.0, 30.0)
@export var max_rotation: float = 0.05
@export var noise_speed: float = 30.0

var trauma: float = 0.0
var current_decay_rate: float = 1.5
var time_elapsed: float = 0.0

var noise: FastNoiseLite = FastNoiseLite.new()
var initial_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	make_current()
	initial_offset = offset
	_setup_noise()
	_connect_signals()


func _setup_noise() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.5


func _connect_signals() -> void:
	if EventBus.has_signal("camera_shake_requested"):
		EventBus.camera_shake_requested.connect(add_shake)


func _process(delta: float) -> void:
	if trauma <= 0.0:
		if offset != initial_offset or rotation != 0.0:
			offset = initial_offset
			rotation = 0.0
		return

	time_elapsed += delta * noise_speed
	trauma = maxf(0.0, trauma - (current_decay_rate * delta))
	
	_apply_shake()


func _apply_shake() -> void:
	var shake_power: float = trauma * trauma
	
	var sample_x: float = noise.get_noise_2d(0.0, time_elapsed)
	var sample_y: float = noise.get_noise_2d(100.0, time_elapsed)
	var sample_rot: float = noise.get_noise_2d(200.0, time_elapsed)
	
	offset.x = initial_offset.x + (sample_x * max_offset.x * shake_power)
	offset.y = initial_offset.y + (sample_y * max_offset.y * shake_power)
	rotation = sample_rot * max_rotation * shake_power


func add_shake(intensity: float, duration: float) -> void:
	var safe_duration: float = maxf(duration, 0.05)
	current_decay_rate = 1.0 / safe_duration
	trauma = clampf(trauma + intensity, 0.0, 1.0)
