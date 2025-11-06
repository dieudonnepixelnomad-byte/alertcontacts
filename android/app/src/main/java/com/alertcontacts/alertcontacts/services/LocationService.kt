package com.alertcontacts.alertcontacts.services

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import android.content.Context
import com.google.gson.Gson
import android.os.Binder
import android.content.IntentFilter
import android.os.BatteryManager
import android.app.ActivityManager

class LocationService : Service() {

    private val binder = LocationBinder()
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private const val LOCATION_UPDATE_INTERVAL = 10000L // 10 seconds
        private const val FASTEST_LOCATION_UPDATE_INTERVAL = 5000L // 5 seconds
        private const val OFFLINE_CACHE_KEY = "offline_location_points"
    }

    inner class LocationBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.locations.forEach { location ->
                    Log.d("LocationService", "New location: ${location.latitude}, ${location.longitude}")
                    val point = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "accuracy" to location.accuracy,
                        "altitude" to location.altitude,
                        "speed" to location.speed,
                        "bearing" to location.bearing,
                        "source" to location.provider,
                        "isForeground" to isAppInForeground(),
                        "batteryLevel" to getBatteryLevel(),
                        "captured_at_device" to System.currentTimeMillis()
                    )

                    if (eventSink != null) {
                        eventSink?.success(point)
                    } else {
                        cacheLocationPoint(point)
                    }
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, "location")
            .setContentTitle("Suivi de la localisation actif")
            .setContentText("AlertContact vous protège en arrière-plan.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()

        startForeground(1, notification)
        startLocationUpdates()

        return START_STICKY
    }

    private fun startLocationUpdates() {
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, LOCATION_UPDATE_INTERVAL)
            .setWaitForAccurateLocation(false)
            .setMinUpdateIntervalMillis(FASTEST_LOCATION_UPDATE_INTERVAL)
            .build()

        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
        } catch (e: SecurityException) {
            Log.e("LocationService", "Location permission not granted.")
        }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        if (sink != null) {
            flushCacheToSink(sink)
        }
    }

    private fun cacheLocationPoint(point: Map<String, Any?>) {
        val prefs = getSharedPreferences("AlertContactPrefs", Context.MODE_PRIVATE)
        val cachedPoints = prefs.getStringSet(OFFLINE_CACHE_KEY, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        cachedPoints.add(Gson().toJson(point))
        prefs.edit().putStringSet(OFFLINE_CACHE_KEY, cachedPoints).apply()
    }

    private fun flushCacheToSink(sink: EventChannel.EventSink) {
        val prefs = getSharedPreferences("AlertContactPrefs", Context.MODE_PRIVATE)
        val cachedPoints = prefs.getStringSet(OFFLINE_CACHE_KEY, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        if (cachedPoints.isNotEmpty()) {
            cachedPoints.forEach {
                val point = Gson().fromJson(it, Map::class.java)
                sink.success(point)
            }
            prefs.edit().remove(OFFLINE_CACHE_KEY).apply()
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level == -1 || scale == -1) -1 else (level.toFloat() / scale.toFloat() * 100.0f).toInt()
    }

    private fun isAppInForeground(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        return appProcesses.any { it.processName == packageName && it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND }
    }

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }
}