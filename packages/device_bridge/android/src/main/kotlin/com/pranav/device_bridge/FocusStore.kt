package com.pranav.device_bridge

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class FocusTimer(
    val id: String,
    val name: String,
    val dailyRuns: Int,
    val wickets: Int,
    val packages: List<String>,
    val studyStart: String,
    val studyEnd: String,
    val allOutAlarm: Boolean,
    val home: Boolean,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id).put("name", name).put("dailyRuns", dailyRuns).put("wickets", wickets)
        .put("packages", JSONArray(packages)).put("studyStart", studyStart).put("studyEnd", studyEnd)
        .put("allOutAlarm", allOutAlarm).put("home", home)

    companion object {
        fun fromJson(o: JSONObject): FocusTimer {
            val pk = o.optJSONArray("packages") ?: JSONArray()
            return FocusTimer(
                id = o.getString("id"),
                name = o.optString("name", "Cricket Timer"),
                dailyRuns = o.optInt("dailyRuns", 300).coerceAtLeast(1),
                wickets = o.optInt("wickets", 3).coerceAtLeast(1),
                packages = List(pk.length()) { pk.getString(it) },
                studyStart = o.optString("studyStart", "18:00"),
                studyEnd = o.optString("studyEnd", "21:00"),
                allOutAlarm = o.optBoolean("allOutAlarm", true),
                home = o.optBoolean("home", false),
            )
        }

        @Suppress("UNCHECKED_CAST")
        fun fromMap(m: Map<*, *>): FocusTimer = FocusTimer(
            id = m["id"] as String,
            name = (m["name"] as? String) ?: "Cricket Timer",
            dailyRuns = ((m["dailyRuns"] as? Number)?.toInt() ?: 300).coerceAtLeast(1),
            wickets = ((m["wickets"] as? Number)?.toInt() ?: 3).coerceAtLeast(1),
            packages = (m["packages"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
            studyStart = (m["studyStart"] as? String) ?: "18:00",
            studyEnd = (m["studyEnd"] as? String) ?: "21:00",
            allOutAlarm = (m["allOutAlarm"] as? Boolean) ?: true,
            home = (m["home"] as? Boolean) ?: false,
        )
    }
}

data class Score(val day: String, val runsLeft: Int, val wicketsLeft: Int, val minutes: Int) {
    fun allOut() = runsLeft <= 0 || wicketsLeft <= 0

    companion object {
        fun of(t: FocusTimer, s: UsageStats) = Score(
            day = FocusStore.today(),
            runsLeft = (t.dailyRuns - s.minutes).coerceAtLeast(0),
            wicketsLeft = (t.wickets - s.studyOpens).coerceAtLeast(0),
            minutes = s.minutes,
        )
    }
}

/** SharedPreferences-backed state shared by the service, widget and plugin. */
object FocusStore {
    private const val PREFS = "device_bridge_focus"

    private fun prefs(c: Context) = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun today(): String = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())

    fun saveTimers(c: Context, timers: List<FocusTimer>) {
        val arr = JSONArray().apply { timers.forEach { put(it.toJson()) } }
        prefs(c).edit().putString("timers", arr.toString()).apply()
    }

    fun timers(c: Context): List<FocusTimer> {
        val raw = prefs(c).getString("timers", null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            List(arr.length()) { FocusTimer.fromJson(arr.getJSONObject(it)) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun homeTimer(c: Context): FocusTimer? = timers(c).let { list -> list.firstOrNull { it.home } ?: list.firstOrNull() }

    fun saveScore(c: Context, id: String, s: Score) {
        val o = JSONObject().put("day", s.day).put("runs", s.runsLeft).put("wkts", s.wicketsLeft).put("min", s.minutes)
        prefs(c).edit().putString("score:$id", o.toString()).apply()
    }

    /** Returns today's last computed score, or null if stale/missing. */
    fun score(c: Context, id: String): Score? {
        val raw = prefs(c).getString("score:$id", null) ?: return null
        return try {
            val o = JSONObject(raw)
            val s = Score(o.getString("day"), o.getInt("runs"), o.getInt("wkts"), o.getInt("min"))
            if (s.day == today()) s else null
        } catch (_: Exception) {
            null
        }
    }

    /** Per-day alert bookkeeping so each alert fires once. Resets at midnight. */
    fun alerts(c: Context, id: String): JSONObject {
        val raw = prefs(c).getString("alerts:$id", null)
        val o = try { raw?.let { JSONObject(it) } } catch (_: Exception) { null }
        return if (o != null && o.optString("day") == today()) o else JSONObject().put("day", today())
    }

    fun saveAlerts(c: Context, id: String, o: JSONObject) {
        prefs(c).edit().putString("alerts:$id", o.toString()).apply()
    }
}
