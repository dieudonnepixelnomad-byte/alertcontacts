package com.alertcontacts.alertcontacts

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterFragmentActivity() {
    private val DEEP_LINK_CHANNEL = "alertcontact/deep_links"
    private var deepLinkMethodChannel: MethodChannel? = null
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        deepLinkMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        deepLinkMethodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(initialLink)
                initialLink = null
            } else {
                result.notImplemented()
            }
        }
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
}
