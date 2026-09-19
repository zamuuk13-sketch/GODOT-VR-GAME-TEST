package com.zamuuk.godot.handtracking

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class HandTrackingPlugin(godot: Godot?) : GodotPlugin(godot) {
    private val tracker = HandTrackingRuntime(this)
    @Volatile private var lastError: String = ""

    override fun getPluginName(): String = "BananoHandTracking"

    private fun activityOrNull(): Activity? = getActivity()

    @UsedByGodot
    fun isCameraPermissionGranted(): Boolean {
        val activity = activityOrNull() ?: return false
        return ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    @UsedByGodot
    fun requestCameraPermission(): Boolean {
        val activity = activityOrNull() ?: return false
        if (isCameraPermissionGranted()) return true
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.CAMERA), 7001)
        lastError = "CAMERA_PERMISSION_REQUESTED"
        return false
    }

    @UsedByGodot
    fun startTracking(): Boolean {
        val activity = activityOrNull() ?: run {
            lastError = "GODOT_ACTIVITY_UNAVAILABLE"
            return false
        }

        if (!isCameraPermissionGranted()) {
            requestCameraPermission()
            return false
        }

        lastError = ""
        return tracker.start(activity)
    }

    @UsedByGodot
    fun stopTracking() {
        tracker.stop()
    }

    @UsedByGodot
    fun isTracking(): Boolean = tracker.isTracking()

    @UsedByGodot
    fun getLatestHandsJson(): String = tracker.latestHandsJson()

    @UsedByGodot
    fun getTrackingFps(): Double = tracker.trackingFps()

    @UsedByGodot
    fun getLastError(): String = lastError

    fun emitTrackingError(message: String) {
        lastError = message
    }
}
