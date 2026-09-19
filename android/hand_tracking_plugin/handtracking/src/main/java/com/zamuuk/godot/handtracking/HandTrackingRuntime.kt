package com.zamuuk.godot.handtracking

import android.app.Activity
import android.graphics.Bitmap
import android.os.SystemClock
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
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
            .setRunningMode(RunningMode.VIDEO)
            .build()

        landmarker = HandLandmarker.createFromOptions(activity, options)

        val future = ProcessCameraProvider.getInstance(activity)
        future.addListener({
            provider = future.get()
            bindRearCamera(activity)
            running.set(true)
        }, ContextCompat.getMainExecutor(activity))

        return true
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
            val result = landmarker?.detectForVideo(mpImage, timestamp)
            if (result != null) {
                latest.set(resultToJson(result))
                updateFps()
            }
        } finally {
            image.close()
        }
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
            hands.append("{\"hand\":").append(handIndex).append(",\"landmarks\":[")
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
    }

    fun isTracking(): Boolean = running.get()

    fun latestHandsJson(): String = latest.get()

    fun trackingFps(): Double = fps
}
