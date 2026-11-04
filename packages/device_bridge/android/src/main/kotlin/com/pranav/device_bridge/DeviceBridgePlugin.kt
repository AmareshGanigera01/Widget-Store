package com.pranav.device_bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class DeviceBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var executor: ExecutorService? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        executor = Executors.newSingleThreadExecutor()
        channel = MethodChannel(binding.binaryMessenger, "com.pranav.device_bridge")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor?.shutdown()
        executor = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(UsageCalculator.hasAccess(context))
            "openUsageAccessSettings" -> {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    // Newer Android versions jump straight to this app's toggle.
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                try {
                    context.startActivity(intent)
                } catch (_: Exception) {
                    context.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
                result.success(null)
            }
            "launchableApps" -> background(result) { launchableApps() }
            "focusStats" -> {
                val packages = call.argument<List<String>>("packages")?.toSet() ?: emptySet()
                val start = call.argument<String>("studyStart") ?: "18:00"
                val end = call.argument<String>("studyEnd") ?: "21:00"
                background(result) {
                    val s = UsageCalculator.compute(context, packages, start, end)
                    mapOf("minutes" to s.minutes, "studyOpens" to s.studyOpens)
                }
            }
            "syncFocusTimers" -> {
                val raw = call.arguments as? List<*> ?: emptyList<Any>()
                val timers = raw.filterIsInstance<Map<*, *>>().map { FocusTimer.fromMap(it) }
                FocusStore.saveTimers(context, timers)
                try {
                    FocusMonitorService.sync(context)
                    CricketWidgetProvider.refresh(context)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("service_start_failed", e.message, null)
                }
            }
            "pendingCapture" -> result.success(pendingCapture())
            "appLabel" -> result.success(appLabel(call.argument<String>("package")))
            else -> result.notImplemented()
        }
    }

    private fun <T> background(result: MethodChannel.Result, block: () -> T) {
        val ex = executor ?: return result.error("detached", "Engine detached", null)
        ex.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("native_error", e.message, null) }
            }
        }
    }

    private fun launchableApps(): List<Map<String, String>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val infos = if (Build.VERSION.SDK_INT >= 33) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION") pm.queryIntentActivities(intent, 0)
        }
        return infos
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { it.first != context.packageName }
            .distinctBy { it.first }
            .sortedBy { it.second.lowercase() }
            .map { mapOf("package" to it.first, "label" to it.second) }
    }

    private fun appLabel(pkg: String?): String? {
        if (pkg.isNullOrBlank()) return null
        return try {
            val pm = context.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
        } catch (_: Exception) {
            null
        }
    }

    private fun pendingCapture(): Map<String, String?>? {
        val a = activity ?: return null
        val intent = a.intent ?: return null
        val text = when (intent.action) {
            Intent.ACTION_PROCESS_TEXT -> intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            Intent.ACTION_SEND -> intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
            else -> null
        } ?: return null
        val source = a.callingPackage ?: a.referrer?.takeIf { it.scheme == "android-app" }?.host
        return mapOf("text" to text.take(MAX_CAPTURE_CHARS), "source" to source)
    }

    companion object {
        /** Keeps AI requests and DB rows bounded. */
        private const val MAX_CAPTURE_CHARS = 20_000
    }
}
