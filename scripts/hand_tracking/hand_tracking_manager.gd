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
var camera_status := "starting"
var last_error := ""
var hand_count := 0
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
			camera_status = "android_plugin_ready"
			camera_status_changed.emit(camera_status)
			if auto_start_on_android:
				call_deferred("start_tracking")
		else:
			camera_status = "android_plugin_not_loaded"
			camera_status_changed.emit(camera_status)
	else:
		camera_status = "desktop_no_android_provider"
		camera_status_changed.emit(camera_status)

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
	if not android_adapter or not android_adapter.is_available():
		camera_status = "android_plugin_unavailable"
		camera_status_changed.emit(camera_status)
		return false

	if not android_adapter.has_camera_permission():
		android_adapter.request_camera_permission()
		camera_status = "camera_permission_requested"
		camera_status_changed.emit(camera_status)
		return false

	camera_ready = android_adapter.start()
	camera_status = "rear_camera_tracking_started" if camera_ready else "camera_start_failed"
	last_error = android_adapter.get_last_error()
	camera_status_changed.emit(camera_status)
	return camera_ready

func stop_tracking() -> void:
	if android_adapter:
		android_adapter.stop()
	camera_ready = false
	camera_status = "tracking_stopped"
	camera_status_changed.emit(camera_status)

func _on_tracking_updated(hands: Dictionary) -> void:
	var list = hands.get("hands", [])
	hand_count = list.size() if list is Array else 0
	hand_tracking_updated.emit(hands)

func _on_tracking_fps_changed(fps: float) -> void:
	tracking_fps_changed.emit(fps)

func get_tracking_fps() -> float:
	if android_adapter:
		return android_adapter.get_tracking_fps()
	return 0.0

func is_camera_ready() -> bool:
	return camera_ready

func get_status() -> String:
	return camera_status

func get_last_error() -> String:
	return last_error if last_error != "" else android_adapter.get_last_error() if android_adapter else ""
