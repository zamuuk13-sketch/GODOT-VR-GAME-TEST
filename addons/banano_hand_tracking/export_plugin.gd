@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "BananoHandTracking"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_name() -> String:
		return PLUGIN_NAME

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["banano_hand_tracking/BananoHandTracking-debug.aar"])
		return PackedStringArray(["banano_hand_tracking/BananoHandTracking-release.aar"])

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"com.google.mediapipe:tasks-vision:0.10.29",
			"androidx.camera:camera-camera2:1.4.2",
			"androidx.camera:camera-lifecycle:1.4.2",
			"androidx.camera:camera-core:1.4.2",
			"androidx.core:core-ktx:1.15.0",
			"androidx.lifecycle:lifecycle-process:2.8.7"
		])
