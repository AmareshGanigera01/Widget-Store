package com.pranav.device_bridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

object FocusNotifications {
    const val CH_MONITOR = "focus_monitor"
    const val CH_ALERTS = "focus_alerts"
    const val CH_ALL_OUT = "focus_all_out"

    const val ID_MONITOR = 7301
    private const val ID_ALERT_BASE = 7400

    fun ensureChannels(c: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = c.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CH_MONITOR, "Cricket score (ongoing)", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Shows runs and wickets left while the focus monitor runs."
                setShowBadge(false)
            },
        )
        nm.createNotificationChannel(
            NotificationChannel(CH_ALERTS, "Cricket warnings", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Low runs and lost wickets."
            },
        )
        nm.createNotificationChannel(
            NotificationChannel(CH_ALL_OUT, "All Out alarm", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Rings when you are all out."
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build(),
                )
                enableVibration(true)
            },
        )
    }

    private fun builder(c: Context, channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(c, channel)
        else @Suppress("DEPRECATION") Notification.Builder(c)

    private fun openApp(c: Context): PendingIntent? {
        val intent = c.packageManager.getLaunchIntentForPackage(c.packageName) ?: return null
        return PendingIntent.getActivity(c, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    fun monitor(c: Context, title: String, text: String): Notification =
        builder(c, CH_MONITOR)
            .setSmallIcon(R.drawable.ic_stat_cricket)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openApp(c))
            .build()

    fun updateMonitor(c: Context, title: String, text: String) {
        c.getSystemService(NotificationManager::class.java).notify(ID_MONITOR, monitor(c, title, text))
    }

    /** [slot] keeps one visible alert per timer and kind. */
    fun alert(c: Context, timerId: String, slot: Int, title: String, text: String, alarm: Boolean) {
        val n = builder(c, if (alarm) CH_ALL_OUT else CH_ALERTS)
            .setSmallIcon(R.drawable.ic_stat_cricket)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setAutoCancel(true)
            .setContentIntent(openApp(c))
            .apply { if (alarm) setCategory(Notification.CATEGORY_ALARM) }
            .build()
        // Insistent = keeps ringing until the user opens or dismisses it.
        if (alarm) n.flags = n.flags or Notification.FLAG_INSISTENT
        val id = ID_ALERT_BASE + (timerId.hashCode() and 0xFFFF) * 4 + slot
        c.getSystemService(NotificationManager::class.java).notify(id, n)
    }
}
