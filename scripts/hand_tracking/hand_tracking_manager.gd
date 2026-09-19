class_name HandTrackingManager
extends Node

signal hand_tracking_updated(hands: Dictionary)
signal tracking_fps_changed(fps: float)
signal camera_status_changed(status: String)

@export var target_fps := 60
@export var prefer_rear_camera := true
@export var auto_start_on_android := true
@export var permission_retry_interval := 0.75

var provider: HandTrackingProvider
var android_adapter: AndroidHandTrackingAdapter
var camera_ready := false
var _permission_retry := 0.0

func _ready() -> void:
	provider = HandTrackingProvider.new()
	add_child(provider)
	provider.tracking_updated.connect(_on_tracking_updated)
	provider.tracking_fps_changed.connect(_on_tracking_fps_changed)

	android_adapter = AndroidHandTrackingAdapter.new()
	add_child(android_adapter)
	android_adapter.hands_updated.connect(_on_tracking_updated)
	android_adapter.tracking_fps_changed.connect(_on_tracking_fps_changed)

	if OS.has_feature("android"):
		if android_adapter.is_available():
			camera_status_changed.emit("android_hand_tracking_plugin_ready")
			if auto_start_on_android:
				call_deferred("start_tracking")
		else:
			camera_status_changed.emit("android_plugin_not_loaded")
	else:
		camera_status_changed.emit("desktop_no_android_provider")

func _process(delta: float) -> void:
	if not OS.has_feature("android") or camera_ready:
		return
	if not auto_start_on_android or not android_adapter or not android_adapter.is_available():
		return

	_permission_retry += delta
	if _permission_retry >= permission_retry_interval:
		_permission_retry = 0.0
		start_tracking()

func start_tracking() -> bool:
	if android_adapter and android_adapter.is_available():
		camera_ready = android_adapter.start()
		if camera_ready:
			camera_status_changed.emit("rear_camera_tracking_started")
		else:
			camera_status_changed.emit("camera_permission_or_runtime_error")
		return camera_ready
	camera_status_changed.emit("android_plugin_unavailable")
	return false

func stop_tracking() -> void:
	if android_adapter:
		android_adapter.stop()
	camera_ready = false
	camera_status_changed.emit("tracking_stopped")

func _on_tracking_updated(hands: Dictionary) -> void:
	hand_tracking_updated.emit(hands)

func _on_tracking_fps_changed(fps: float) -> void:
	tracking_fps_changed.emit(fps)

func get_tracking_fps() -> float:
	if android_adapter and android_adapter.plugin:
		return float(android_adapter.plugin.getTrackingFps())
	return 0.0

func is_camera_ready() -> bool:
	return camera_ready
