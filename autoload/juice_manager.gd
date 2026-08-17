extends Node

const DEFAULT_SHAKE_INTENSITY: float = 0.5
const DEFAULT_SHAKE_DURATION: float = 0.3

func shake_camera(intensity: float = DEFAULT_SHAKE_INTENSITY, duration: float = DEFAULT_SHAKE_DURATION) -> void:
	EventBus.camera_shake_requested.emit(intensity, duration)

func shake_camera_custom(intensity: float, duration: float) -> void:
	EventBus.camera_shake_requested.emit(intensity, duration)
