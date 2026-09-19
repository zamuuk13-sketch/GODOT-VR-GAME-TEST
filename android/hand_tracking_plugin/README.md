# BananoHandTracking Android plugin

This module is the native Android side of Stage 3.

## What it does

- Uses the rear Android camera through CameraX.
- Runs Google's MediaPipe Hand Landmarker locally on-device.
- Tracks up to 2 hands.
- Produces 21 landmarks per detected hand.
- Reports left/right classification.
- Keeps only the newest camera frame to reduce latency.
- Measures actual landmark-processing FPS.
- Exposes the result to Godot through the Android v2 plugin API.

MediaPipe's Android Hand Landmarker supports live camera processing and uses tracking in video/live-stream modes to reduce latency. The official Android guide uses the com.google.mediapipe:tasks-vision dependency.

## Model

Run from PowerShell:

    .\download_hand_model.ps1

This downloads the official Hand Landmarker task bundle into:

    handtracking/src/main/assets/hand_landmarker.task

The model is local; no network connection is needed during inference.

## Build

The Android plugin is a Gradle Android library. Build it with:

    gradlew.bat :handtracking:assembleRelease

The resulting AAR is:

    handtracking/build/outputs/aar/handtracking-release.aar

Godot Android plugin v2 uses the Gradle build pipeline and packages the generated Android library into the Android export.

## Important

The repository currently contains the plugin source and build configuration, but not the generated AAR or model binary. This keeps generated/binary artifacts out of Git.

The next integration step is packaging the generated AAR into the Godot Android export. This Stage 3 implementation deliberately does not touch the 3D GLB models.
