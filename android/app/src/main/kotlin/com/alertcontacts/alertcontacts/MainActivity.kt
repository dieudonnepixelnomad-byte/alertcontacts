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
    private val DEEP_LINK_CHANNEL = "alertcontact/deep_links"
    private var deepLinkMethodChannel: MethodChannel? = null
    private var initialLink: String? = null

    private val METHOD_CHANNEL = "com.alertcontacts.alertcontacts/location"
    private val EVENT_CHANNEL = "com.alertcontacts.alertcontacts/location_stream"
    private var locationService: LocationService? = null
    private var isServiceBound = false
    private var eventSink: EventChannel.EventSink? = null

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationService.LocationBinder
            locationService = binder.getService()
            isServiceBound = true
            locationService?.setActivityBound(true)
            // Une fois le service connecté, on lui passe le "pont" de communication s'il existe déjà.
            eventSink?.let {
                locationService?.setEventSink(it)
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            locationService?.setActivityBound(false)
            locationService = null
            isServiceBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Configuration du MethodChannel pour les deep links
        deepLinkMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        deepLinkMethodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(initialLink)
                initialLink = null // Le lien ne doit être consommé qu'une seule fois
            } else {
                result.notImplemented()
            }
        }

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
                    // On stocke le "pont" et on tente de le passer au service s'il est déjà connecté.
                    eventSink = events
                    locationService?.setEventSink(eventSink)
                }

                override fun onCancel(arguments: Any?) {
                    // On détruit le pont
                    locationService?.setEventSink(null)
                    eventSink = null
                }
            }
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val appLinkAction = intent?.action
        val appLinkData = intent?.data
        if (Intent.ACTION_VIEW == appLinkAction && appLinkData != null) {
            val link = appLinkData.toString()
            if (deepLinkMethodChannel != null) {
                deepLinkMethodChannel?.invokeMethod("onDeepLink", link)
            } else {
                initialLink = link
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isServiceBound) {
            locationService?.setActivityBound(false)
            unbindService(serviceConnection)
            isServiceBound = false
        }
    }
}
