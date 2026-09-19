extends Node
class_name AndroidHandTrackingAdapter

signal hands_updated(hands: Dictionary)
signal tracking_fps_changed(fps: float)
signal tracking_started
signal tracking_stopped

var plugin = null
var active := false

func _ready() -> void:
	if not OS.has_feature("android"):
		return
	if Engine.has_singleton("BananoHandTracking"):
		plugin = Engine.get_singleton("BananoHandTracking")

func start() -> bool:
	if plugin == null:
		return false
	var ok: bool = plugin.startTracking()
	active = ok
	if ok:
		tracking_started.emit()
	return ok

func stop() -> void:
	if plugin:
		plugin.stopTracking()
	active = false
	tracking_stopped.emit()

func request_camera_permission() -> bool:
	if plugin == null:
		return false
	return bool(plugin.requestCameraPermission())

func has_camera_permission() -> bool:
	if plugin == null:
		return false
	return bool(plugin.isCameraPermissionGranted())

func get_last_error() -> String:
	if plugin == null:
		return "PLUGIN_UNAVAILABLE"
	return str(plugin.getLastError())

func get_tracking_fps() -> float:
	if plugin == null:
		return 0.0
	return float(plugin.getTrackingFps())

func _process(_delta: float) -> void:
	if plugin == null or not active:
		return
	var json_text: String = plugin.getLatestHandsJson()
	var parsed = JSON.parse_string(json_text)
	if parsed is Dictionary:
		hands_updated.emit(parsed)
	tracking_fps_changed.emit(get_tracking_fps())

func is_available() -> bool:
	return plugin != null
