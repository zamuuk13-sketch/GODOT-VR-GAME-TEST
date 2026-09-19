class_name HandTrackingProvider
extends Node

signal tracking_updated(hands: Dictionary)
signal tracking_lost
signal tracking_fps_changed(fps: float)
signal provider_status_changed(status: String)

const TARGET_TRACKING_FPS := 60.0

var tracking_fps := 0.0
var _frames := 0
var _fps_timer := 0.0
var _last_hands: Dictionary = {}

func start() -> void:
	provider_status_changed.emit("provider_not_connected")

func stop() -> void:
	_last_hands.clear()
	tracking_lost.emit()

func _process(delta: float) -> void:
	_fps_timer += delta
	if _fps_timer >= 1.0:
		tracking_fps = float(_frames) / _fps_timer
		_frames = 0
		_fps_timer = 0.0
		tracking_fps_changed.emit(tracking_fps)

func submit_tracking_result(hands: Dictionary) -> void:
	_last_hands = hands
	_frames += 1
	tracking_updated.emit(hands)

func get_hands() -> Dictionary:
	return _last_hands

func is_at_target_fps() -> bool:
	return tracking_fps >= TARGET_TRACKING_FPS - 2.0
