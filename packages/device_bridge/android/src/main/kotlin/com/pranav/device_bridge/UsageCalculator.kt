package com.pranav.device_bridge

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import java.util.Calendar

data class UsageStats(val minutes: Int, val studyOpens: Int)

/**
 * Derives today's foreground time and study-hour opens for a set of packages
 * from raw usage events. Events are used instead of aggregated buckets because
 * buckets don't align with local midnight.
 */
object UsageCalculator {
    // UsageEvents.Event constants, inlined so they work below API 29.
    private const val RESUMED = 1
    private const val PAUSED = 2
    private const val SCREEN_NON_INTERACTIVE = 16
    private const val KEYGUARD_SHOWN = 17
    private const val DEVICE_SHUTDOWN = 26

    /** Returning to the same app within this window is not a new "open". */
    private const val REOPEN_GRACE_MS = 30_000L

    fun hasAccess(context: Context): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun startOfToday(now: Long = System.currentTimeMillis()): Long =
        Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    private fun minutesOfDay(hhmm: String): Int {
        val parts = hhmm.split(":")
        val h = parts.getOrNull(0)?.toIntOrNull() ?: 0
        val m = parts.getOrNull(1)?.toIntOrNull() ?: 0
        return (h.coerceIn(0, 23) * 60) + m.coerceIn(0, 59)
    }

    fun compute(
        context: Context,
        packages: Set<String>,
        studyStart: String,
        studyEnd: String,
        now: Long = System.currentTimeMillis(),
    ): UsageStats {
        if (packages.isEmpty() || !hasAccess(context)) return UsageStats(0, 0)

        val dayStart = startOfToday(now)
        val ss = dayStart + minutesOfDay(studyStart) * 60_000L
        val se = dayStart + minutesOfDay(studyEnd) * 60_000L
        // A window like 22:00–02:00 wraps past midnight.
        fun inStudy(t: Long) = if (se > ss) t in ss until se else t >= ss || t < se

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(dayStart, now)
        val e = UsageEvents.Event()

        var fgPkg: String? = null
        var fgStart = 0L
        var pausedAt: Long? = null
        var totalMs = 0L
        var opens = 0
        val lastLeft = HashMap<String, Long>()

        fun closeSession(at: Long) {
            val pkg = fgPkg ?: return
            if (pkg in packages) totalMs += (at - fgStart).coerceAtLeast(0)
            lastLeft[pkg] = at
            fgPkg = null
            pausedAt = null
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            val ts = e.timeStamp
            when (e.eventType) {
                RESUMED -> {
                    val pkg = e.packageName
                    if (pkg == fgPkg) {
                        // Activity switch inside the same app.
                        pausedAt = null
                    } else {
                        closeSession(pausedAt ?: ts)
                        val left = lastLeft[pkg]
                        if (pkg in packages && inStudy(ts) && (left == null || ts - left > REOPEN_GRACE_MS)) {
                            opens++
                        }
                        fgPkg = pkg
                        fgStart = ts
                    }
                }
                PAUSED -> if (e.packageName == fgPkg) pausedAt = ts
                SCREEN_NON_INTERACTIVE, KEYGUARD_SHOWN, DEVICE_SHUTDOWN -> closeSession(pausedAt ?: ts)
            }
        }
        // Still in the foreground right now.
        if (fgPkg != null) closeSession(pausedAt ?: now)

        return UsageStats((totalMs / 60_000L).toInt(), opens)
    }
}
