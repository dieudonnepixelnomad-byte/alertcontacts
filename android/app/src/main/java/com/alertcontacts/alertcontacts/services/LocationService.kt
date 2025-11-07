package com.alertcontacts.alertcontacts.services

import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
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
import android.content.pm.ServiceInfo
import android.os.Build
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

class LocationService : Service() {

    private val binder = LocationBinder()
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var eventSink: EventChannel.EventSink? = null
    private var isActivityBound = false
    private val httpClient = OkHttpClient()
    private val gson = Gson()

    companion object {
        private const val LOCATION_UPDATE_INTERVAL = 10000L // 10 seconds
        private const val FASTEST_LOCATION_UPDATE_INTERVAL = 5000L // 5 seconds
        private const val OFFLINE_CACHE_KEY = "offline_location_points"
        private const val API_BASE_URL = "https://mobile.alertcontacts.net/api" // Assurez-vous que c'est la bonne URL
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
                val newPoints = locationResult.locations.map { location ->
                    Log.d("LocationService", "New location: ${location.latitude}, ${location.longitude}")
                    mapOf(
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
                }

                if (isActivityBound && eventSink != null) {
                    newPoints.forEach { eventSink?.success(it) }
                } else {
                    // L'activité n'est pas liée, envoyer directement au backend
                    val pointsToSend = getAndClearCachedPoints().toMutableList()
                    pointsToSend.addAll(newPoints)
                    sendLocationsToBackend(pointsToSend)
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

        val notificationsEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
        val locationPermissionGranted = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (notificationsEnabled && locationPermissionGranted) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            } else {
                startForeground(1, notification)
            }
        }

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

    private fun sendLocationsToBackend(points: List<Map<String, Any?>>) {
        if (points.isEmpty()) return

        val token = getBearerToken()
        if (token == null) {
            Log.w("LocationService", "Bearer token not found, caching points.")
            points.forEach { cacheLocationPoint(it) }
            return
        }

        val json = gson.toJson(points) // L'API attend une liste de points
        val requestBody = json.toRequestBody("application/json; charset=utf-8".toMediaType())

        val request = Request.Builder()
            .url("$API_BASE_URL/locations/batch")
            .addHeader("Authorization", "Bearer $token")
            .post(requestBody)
            .build()

        httpClient.newCall(request).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: IOException) {
                Log.e("LocationService", "Failed to send locations to backend: ${e.message}")
                // En cas d'échec, mettre en cache pour une tentative ultérieure
                points.forEach { cacheLocationPoint(it) }
            }

            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                if (!response.isSuccessful) {
                    Log.e("LocationService", "Backend returned an error for batch: ${response.code}")
                    points.forEach { cacheLocationPoint(it) }
                } else {
                    Log.d("LocationService", "Location points batch sent to backend successfully.")
                }
                response.close()
            }
        })
    }

    fun setActivityBound(isBound: Boolean) {
        this.isActivityBound = isBound
        if (isBound && eventSink != null) {
            // Lorsque l'activité se reconnecte, on envoie les points mis en cache
            flushCacheToSink(eventSink!!)
        }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        if (sink != null) {
            flushCacheToSink(sink)
        }
    }

    private fun getBearerToken(): String? {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // La clé est préfixée par "flutter." par le plugin shared_preferences
        return prefs.getString("flutter.bearer_token", null)
    }

    private fun cacheLocationPoint(point: Map<String, Any?>) {
        val prefs = getSharedPreferences("AlertContactPrefs", Context.MODE_PRIVATE)
        val cachedPoints = prefs.getStringSet(OFFLINE_CACHE_KEY, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        cachedPoints.add(Gson().toJson(point))
        prefs.edit().putStringSet(OFFLINE_CACHE_KEY, cachedPoints).apply()
    }

    private fun getAndClearCachedPoints(): List<Map<String, Any?>> {
        val prefs = getSharedPreferences("AlertContactPrefs", Context.MODE_PRIVATE)
        val cachedPointsJson = prefs.getStringSet(OFFLINE_CACHE_KEY, null) ?: return emptyList()
        if (cachedPointsJson.isEmpty()) return emptyList()

        val points = cachedPointsJson.map { gson.fromJson(it, Map::class.java) as Map<String, Any?> }
        prefs.edit().remove(OFFLINE_CACHE_KEY).apply()
        return points
    }

    private fun flushCacheToSink(sink: EventChannel.EventSink) {
        val cachedPoints = getAndClearCachedPoints()
        if (cachedPoints.isNotEmpty()) {
            cachedPoints.forEach { point ->
                sink.success(point)
            }
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