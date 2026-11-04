package com.pranav.device_bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts the focus monitor after a reboot or app update. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                try {
                    FocusMonitorService.sync(context)
                } catch (_: Exception) {
                    // Background start can be refused on some OEMs; the app restarts it on next open.
                }
            }
        }
    }
}
