package com.pranav.device_bridge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews

/** Static home screen dashboard: runs and wickets left for one cricket timer. */
class CricketWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        fun refresh(c: Context) {
            val manager = AppWidgetManager.getInstance(c)
            val ids = manager.getAppWidgetIds(ComponentName(c, CricketWidgetProvider::class.java))
            if (ids.isNotEmpty()) render(c, manager, ids)
        }

        private fun render(c: Context, manager: AppWidgetManager, ids: IntArray) {
            val views = RemoteViews(c.packageName, R.layout.cricket_widget)
            val t = FocusStore.homeTimer(c)
            if (t == null) {
                views.setTextViewText(R.id.cw_title, "Cricket Focus")
                views.setTextViewText(R.id.cw_runs, "—")
                views.setTextViewText(R.id.cw_detail, "Set a Cricket Timer in Widget Market")
                views.setProgressBar(R.id.cw_progress, 1, 0, false)
            } else {
                val s = FocusStore.score(c, t.id)
                    ?: Score.of(t, UsageCalculator.compute(c, t.packages.toSet(), t.studyStart, t.studyEnd))
                views.setTextViewText(R.id.cw_title, t.name)
                views.setTextViewText(R.id.cw_runs, if (s.allOut()) "ALL OUT" else "${s.runsLeft}")
                views.setTextViewText(
                    R.id.cw_detail,
                    if (s.allOut()) "Resets at midnight" else "runs left · ${s.wicketsLeft}/${t.wickets} wickets",
                )
                views.setProgressBar(R.id.cw_progress, t.dailyRuns, s.runsLeft, false)
            }
            c.packageManager.getLaunchIntentForPackage(c.packageName)?.let {
                views.setOnClickPendingIntent(
                    R.id.cw_root,
                    PendingIntent.getActivity(c, 1, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
                )
            }
            manager.updateAppWidget(ids, views)
        }
    }
}
