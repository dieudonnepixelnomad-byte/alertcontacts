package com.alertcontacts.alertcontacts

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import com.alertcontacts.alertcontacts.services.LocationService
import io.flutter.plugin.common.EventChannel
import android.content.ServiceConnection
import android.os.IBinder
import android.content.ComponentName
import android.content.Context

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL = "com.alertcontacts.alertcontacts/location"
    private val EVENT_CHANNEL = "com.alertcontacts.alertcontacts/location_stream"
    private var locationService: LocationService? = null
    private var isServiceBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationService.LocationBinder
            locationService = binder.getService()
            isServiceBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            locationService = null
            isServiceBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "startLocationService") {
                val intent = Intent(this, LocationService::class.java)
                startService(intent)
                bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
                result.success(null)
            } else if (call.method == "stopLocationService") {
                if (isServiceBound) {
                    unbindService(serviceConnection)
                    isServiceBound = false
                }
                stopService(Intent(this, LocationService::class.java))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    locationService?.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    locationService?.setEventSink(null)
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isServiceBound) {
            unbindService(serviceConnection)
            isServiceBound = false
        }
    }
}
