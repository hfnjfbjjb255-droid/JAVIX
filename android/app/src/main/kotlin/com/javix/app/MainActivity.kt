package com.javix.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "jarvis/native"
    private val permissionRequestCode = 7107

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestAllPermissions" -> {
                        requestAllPermissions()
                        result.success(true)
                    }
                    "permissionStatus" -> result.success(permissionStatus())
                    "batteryPercent" -> result.success(batteryPercent())
                    "location" -> result.success(lastKnownLocation())
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestAllPermissions() {
        val requested = mutableListOf<String>()
        fun add(permission: String) {
            if (Build.VERSION.SDK_INT >= 23 && checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                requested.add(permission)
            }
        }

        add(Manifest.permission.RECORD_AUDIO)
        add(Manifest.permission.CAMERA)
        add(Manifest.permission.ACCESS_FINE_LOCATION)
        add(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (Build.VERSION.SDK_INT >= 33) {
            add(Manifest.permission.POST_NOTIFICATIONS)
            add(Manifest.permission.READ_MEDIA_IMAGES)
            add(Manifest.permission.READ_MEDIA_VIDEO)
            add(Manifest.permission.READ_MEDIA_AUDIO)
        } else if (Build.VERSION.SDK_INT >= 23) {
            add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        if (Build.VERSION.SDK_INT >= 31) {
            add(Manifest.permission.BLUETOOTH_SCAN)
            add(Manifest.permission.BLUETOOTH_CONNECT)
            add(Manifest.permission.BLUETOOTH_ADVERTISE)
        }

        if (requested.isNotEmpty() && Build.VERSION.SDK_INT >= 23) {
            requestPermissions(requested.toTypedArray(), permissionRequestCode)
        }
    }

    private fun permissionStatus(): Map<String, Boolean> {
        val out = mutableMapOf<String, Boolean>()
        fun put(key: String, permission: String) {
            out[key] = Build.VERSION.SDK_INT < 23 || checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        }
        put("microphone", Manifest.permission.RECORD_AUDIO)
        put("camera", Manifest.permission.CAMERA)
        put("location", Manifest.permission.ACCESS_FINE_LOCATION)
        if (Build.VERSION.SDK_INT >= 33) {
            put("photos", Manifest.permission.READ_MEDIA_IMAGES)
            put("videos", Manifest.permission.READ_MEDIA_VIDEO)
            put("audioFiles", Manifest.permission.READ_MEDIA_AUDIO)
            put("notifications", Manifest.permission.POST_NOTIFICATIONS)
        } else {
            put("storage", Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        if (Build.VERSION.SDK_INT >= 31) {
            put("bluetooth", Manifest.permission.BLUETOOTH_CONNECT)
            put("bluetoothScan", Manifest.permission.BLUETOOTH_SCAN)
        }
        return out
    }

    private fun batteryPercent(): Int? {
        val manager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val value = manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return if (value in 0..100) value else null
    }

    private fun lastKnownLocation(): Map<String, Double>? {
        if (Build.VERSION.SDK_INT >= 23 && checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return null
        }
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        var best: Location? = null
        for (provider in providers) {
            try {
                val loc = manager.getLastKnownLocation(provider) ?: continue
                if (best == null || loc.time > best!!.time) best = loc
            } catch (_: SecurityException) {
                return null
            }
        }
        return best?.let { mapOf("latitude" to it.latitude, "longitude" to it.longitude) }
    }
}
