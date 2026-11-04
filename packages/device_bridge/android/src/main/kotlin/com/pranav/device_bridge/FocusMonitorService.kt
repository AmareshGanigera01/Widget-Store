package com.pranav.device_bridge

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import java.util.concurrent.Executors

/**
 * Foreground service that re-scores every cricket timer once a minute,
 * keeps the ongoing score notification and home widget fresh, and fires
 * wicket / low-runs / All Out alerts.
 */
class FocusMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()

    private val tick = object : Runnable {
        override fun run() {
            worker.execute { check() }
            handler.postDelayed(this, INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        FocusNotifications.ensureChannels(this)
        val n = FocusNotifications.monitor(this, "Cricket Focus", "Starting the innings…")
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(FocusNotifications.ID_MONITOR, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(FocusNotifications.ID_MONITOR, n)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Re-score immediately whenever the timer config changes.
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        worker.shutdownNow()
        super.onDestroy()
    }

    private fun check() {
        val timers = FocusStore.timers(this)
        if (timers.isEmpty()) {
            stopSelf()
            return
        }
        if (!UsageCalculator.hasAccess(this)) {
            FocusNotifications.updateMonitor(this, "Cricket Focus paused", "Open Widget Market and grant Usage access to start scoring.")
            return
        }
        val lines = ArrayList<String>()
        for (t in timers) {
            val score = Score.of(t, UsageCalculator.compute(this, t.packages.toSet(), t.studyStart, t.studyEnd))
            FocusStore.saveScore(this, t.id, score)
            processAlerts(this, t, score)
            lines += if (score.allOut()) "${t.name}: ALL OUT" else
                "${t.name}: ${score.runsLeft}/${t.dailyRuns} runs · ${score.wicketsLeft} wkt${if (score.wicketsLeft == 1) "" else "s"} left"
        }
        FocusNotifications.updateMonitor(this, "🏏 Defending today's runs", lines.joinToString("\n"))
        CricketWidgetProvider.refresh(this)
    }

    companion object {
        private const val INTERVAL_MS = 60_000L
        private const val LOW_RUNS = 30

        fun sync(c: Context) {
            val intent = Intent(c, FocusMonitorService::class.java)
            if (FocusStore.timers(c).isEmpty()) {
                c.stopService(intent)
                return
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) c.startForegroundService(intent) else c.startService(intent)
        }

        fun processAlerts(c: Context, t: FocusTimer, s: Score) {
            val a = FocusStore.alerts(c, t.id)
            val lost = t.wickets - s.wicketsLeft
            if (lost > a.optInt("wkts", 0) && s.wicketsLeft > 0) {
                FocusNotifications.alert(
                    c, t.id, 0, "☝️ Wicket!",
                    "You opened a tracked app during study hours. ${s.wicketsLeft} wicket${if (s.wicketsLeft == 1) "" else "s"} left. Back to the crease!",
                    alarm = false,
                )
            }
            a.put("wkts", lost)
            if (!s.allOut() && s.runsLeft <= LOW_RUNS && !a.optBoolean("low")) {
                FocusNotifications.alert(
                    c, t.id, 1, "⚠️ Only ${s.runsLeft} runs left",
                    "You're close to being all out on ${t.name}. Time to put the phone down.",
                    alarm = false,
                )
                a.put("low", true)
            }
            if (s.allOut() && !a.optBoolean("out")) {
                val why = if (s.wicketsLeft <= 0) "You lost all ${t.wickets} wickets." else "All ${t.dailyRuns} runs are gone."
                FocusNotifications.alert(c, t.id, 2, "🏏 ALL OUT!", "$why The innings resets at midnight.", alarm = t.allOutAlarm)
                a.put("out", true)
            }
            FocusStore.saveAlerts(c, t.id, a)
        }
    }
}
