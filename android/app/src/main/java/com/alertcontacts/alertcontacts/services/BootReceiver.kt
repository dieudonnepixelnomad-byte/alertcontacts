package com.alertcontacts.alertcontacts.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Intent(context, LocationService::class.java).also { 
                context.startForegroundService(it)
            }
        }
    }
}