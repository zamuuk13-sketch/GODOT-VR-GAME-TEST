extends CanvasLayer

@export var manager_path: NodePath
var manager: HandTrackingManager
var label: Label

func _ready() -> void:
	manager = get_node_or_null(manager_path) as HandTrackingManager
	label = Label.new()
	label.position = Vector2(24, 24)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)

	if manager:
		manager.tracking_fps_changed.connect(_on_fps)
		manager.camera_status_changed.connect(_on_camera_status)
		_update_text()

func _on_fps(_fps: float) -> void:
	_update_text()

func _on_camera_status(_status: String) -> void:
	_update_text()

func _update_text() -> void:
	if not manager:
		label.text = "HAND TRACKING\nmanager unavailable"
		return
	label.text = "HAND TRACKING\nCamera: %s\nTracking FPS: %.1f / 60" % [
		"OK" if manager.is_camera_ready() else "WAITING",
		manager.get_tracking_fps()
	]
