package com.zamuuk.godot.handtracking

import android.app.Activity
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class HandTrackingPlugin(godot: Godot?) : GodotPlugin(godot) {
    private val tracker = HandTrackingRuntime(this)

    override fun getPluginName(): String = "BananoHandTracking"

    @UsedByGodot
    fun startTracking(): Boolean {
        return tracker.start(getActivity())
    }

    @UsedByGodot
    fun stopTracking() {
        tracker.stop()
    }

    @UsedByGodot
    fun isTracking(): Boolean {
        return tracker.isTracking()
    }

    @UsedByGodot
    fun getLatestHandsJson(): String {
        return tracker.latestHandsJson()
    }

    @UsedByGodot
    fun getTrackingFps(): Double {
        return tracker.trackingFps()
    }
}
