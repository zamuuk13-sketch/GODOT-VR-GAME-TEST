package com.zamuuk.godot.handtracking

import android.app.Activity
import android.os.SystemClock
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class HandTrackingRuntime(private val plugin: HandTrackingPlugin) {
    private val running = AtomicBoolean(false)
    private val latest = AtomicReference("{}")
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()

    private var frameCount = 0
    private var fpsStartMs = 0L
    private var fps = 0.0
    private var landmarker: HandLandmarker? = null
    private var provider: ProcessCameraProvider? = null

    fun start(activity: Activity): Boolean {
        if (running.get()) return true

        return try {
            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("hand_landmarker.task")
                        .build()
                )
                .setNumHands(2)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setResultListener { result, _ ->
                    latest.set(resultToJson(result))
                    updateFps()
                }
                .setErrorListener { error ->
                    latest.set("{}")
                    plugin.emitTrackingError(error.message ?: "MediaPipe tracking error")
                }
                .build()

            landmarker = HandLandmarker.createFromOptions(activity, options)

            val future = ProcessCameraProvider.getInstance(activity)
            future.addListener({
                try {
                    provider = future.get()
                    bindRearCamera(activity)
                    resetFps()
                    running.set(true)
                } catch (error: Exception) {
                    running.set(false)
                    plugin.emitTrackingError(error.message ?: "Camera initialization failed")
                }
            }, ContextCompat.getMainExecutor(activity))

            true
        } catch (error: Exception) {
            running.set(false)
            landmarker?.close()
            landmarker = null
            plugin.emitTrackingError(error.message ?: "Hand tracking initialization failed")
            false
        }
    }

    private fun bindRearCamera(activity: Activity) {
        val cameraProvider = provider ?: return

        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()

        analysis.setAnalyzer(executor) { image ->
            processFrame(image)
        }

        cameraProvider.unbindAll()
        cameraProvider.bindToLifecycle(
            activity,
            CameraSelector.DEFAULT_BACK_CAMERA,
            analysis
        )
    }

    private fun processFrame(image: ImageProxy) {
        try {
            val bitmap = image.toBitmap()
            val mpImage = BitmapImageBuilder(bitmap).build()
            val timestamp = SystemClock.uptimeMillis()
            landmarker?.detectAsync(mpImage, timestamp)
        } catch (error: Exception) {
            plugin.emitTrackingError(error.message ?: "Frame processing failed")
        } finally {
            image.close()
        }
    }

    private fun resetFps() {
        frameCount = 0
        fpsStartMs = SystemClock.uptimeMillis()
        fps = 0.0
    }

    private fun updateFps() {
        val now = SystemClock.uptimeMillis()
        if (fpsStartMs == 0L) fpsStartMs = now

        frameCount++
        val elapsed = now - fpsStartMs
        if (elapsed >= 1000L) {
            fps = frameCount * 1000.0 / elapsed.toDouble()
            frameCount = 0
            fpsStartMs = now
        }
    }

    private fun resultToJson(result: HandLandmarkerResult): String {
        val hands = StringBuilder("[")
        result.landmarks().forEachIndexed { handIndex, landmarks ->
            if (handIndex > 0) hands.append(",")
            val handedness = result.handednesses()
                .getOrNull(handIndex)
                ?.firstOrNull()
                ?.categoryName() ?: "Unknown"

            hands.append("{\"hand\":").append(handIndex)
                .append(",\"label\":\"").append(handedness)
                .append("\",\"landmarks\":[")

            landmarks.forEachIndexed { i, point ->
                if (i > 0) hands.append(",")
                hands.append("{\"x\":").append(point.x())
                    .append(",\"y\":").append(point.y())
                    .append(",\"z\":").append(point.z()).append("}")
            }

            hands.append("]}")
        }

        hands.append("]")
        return "{\"hands\":$hands}"
    }

    fun stop() {
        running.set(false)
        provider?.unbindAll()
        provider = null
        landmarker?.close()
        landmarker = null
        latest.set("{}")
        resetFps()
    }

    fun isTracking(): Boolean = running.get()

    fun latestHandsJson(): String = latest.get()

    fun trackingFps(): Double = fps
}
