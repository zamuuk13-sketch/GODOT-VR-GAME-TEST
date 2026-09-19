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

    override fun getPluginName(): String = "BananoHandTracking"

    @UsedByGodot
    fun startTracking(): Boolean {
        val activity: Activity = getActivity() ?: return false
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.CAMERA), 7001)
            return false
        }
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
}
