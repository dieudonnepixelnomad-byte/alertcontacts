package com.alertcontacts.alertcontacts.services

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.work.Worker
import androidx.work.WorkerParameters

class LocationWatchdogWorker(
    private val appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val hasLocation = ContextCompat.checkSelfPermission(
            appContext, android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasLocation) {
            Log.d("LocationWatchdog", "Location permission not granted — skipping")
            return Result.success()
        }

        if (isLocationServiceRunning()) {
            Log.d("LocationWatchdog", "LocationService is running — nothing to do")
            return Result.success()
        }

        Log.i("LocationWatchdog", "LocationService not running — restarting")
        val serviceIntent = Intent(appContext, LocationService::class.java)
        ContextCompat.startForegroundService(appContext, serviceIntent)

        return Result.success()
    }

    private fun isLocationServiceRunning(): Boolean {
        val manager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        return manager.getRunningServices(Integer.MAX_VALUE)
            .any { it.service.className == LocationService::class.java.name }
    }
}
