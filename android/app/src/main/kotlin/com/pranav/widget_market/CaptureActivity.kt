package com.pranav.widget_market

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

/**
 * Lightweight activity launched from other apps' text-selection menu or share
 * sheet. Runs the `captureMain` Dart entrypoint over a transparent window so
 * it looks like a bottom sheet on top of the source app.
 */
class CaptureActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "captureMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent
}
