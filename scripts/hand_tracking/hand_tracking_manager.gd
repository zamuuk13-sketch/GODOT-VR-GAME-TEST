class_name HandTrackingManager
extends Node

signal hand_tracking_updated(hands: Dictionary)
signal tracking_fps_changed(fps: float)
signal camera_status_changed(status: String)

@export var target_fps := 60
@export var prefer_rear_camera := true

var provider: HandTrackingProvider
var camera_feed: CameraFeed
var camera_index := -1
var camera_ready := false

func _ready() -> void:
	provider = HandTrackingProvider.new()
	add_child(provider)
	provider.tracking_updated.connect(_on_tracking_updated)
	provider.tracking_fps_changed.connect(_on_tracking_fps_changed)
	_start_camera_discovery()
	provider.start()

func _start_camera_discovery() -> void:
	CameraServer.monitoring_feeds = true
	var feeds := CameraServer.feeds
	if feeds.is_empty():
		camera_status_changed.emit("no_camera_feed")
		return

	var selected := _select_camera(feeds)
	if selected == null:
		camera_status_changed.emit("camera_not_selected")
		return

	camera_feed = selected
	camera_index = feeds.find(selected)
	camera_feed.feed_is_active = true
	camera_ready = true
	camera_status_changed.emit("rear_camera_selected" if prefer_rear_camera else "camera_selected")

func _select_camera(feeds: Array[CameraFeed]) -> CameraFeed:
	if feeds.is_empty():
		return null

	if prefer_rear_camera:
		for feed in feeds:
			var label := (feed.get_name() + " " + feed.get_description()).to_lower()
			if "back" in label or "rear" in label:
				return feed
	return feeds.back()

func _on_tracking_updated(hands: Dictionary) -> void:
	hand_tracking_updated.emit(hands)

func _on_tracking_fps_changed(fps: float) -> void:
	tracking_fps_changed.emit(fps)

func get_camera_feed() -> CameraFeed:
	return camera_feed

func is_camera_ready() -> bool:
	return camera_ready

func get_tracking_fps() -> float:
	return provider.tracking_fps if provider else 0.0
