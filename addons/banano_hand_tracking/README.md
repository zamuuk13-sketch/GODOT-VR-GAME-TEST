# Banano Hand Tracking

Godot 4 Android plugin v2 for local hand tracking.

The plugin exposes the singleton BananoHandTracking to GDScript and uses CameraX + MediaPipe Hand Landmarker on the Android device.

## Export

Use Godot's Gradle Android export. The EditorExportPlugin supplies the local AAR plus its Maven dependencies.

Generated AAR files are produced by the repository GitHub Actions build and placed beside this README.

## Runtime API

- startTracking()
- stopTracking()
- isTracking()
- getLatestHandsJson()
- getTrackingFps()

The hand_landmarker.task model is packaged inside the AAR build.