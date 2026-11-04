import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Starts/stops the floating overlay from the main app.
class OverlayController {
  // Overlay bubble size in dp (matches overlay_app.dart)
  static const bubbleSize = 64;
  
  static Future<bool> isActive() => FlutterOverlayWindow.isActive();

  /// Returns false if the user didn't grant "Display over other apps".
  static Future<bool> show() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      final granted = await FlutterOverlayWindow.requestPermission() ?? false;
      if (!granted) return false;
    }
    if (await FlutterOverlayWindow.isActive()) return true;
    await FlutterOverlayWindow.showOverlay(
      width: bubbleSize,
      height: bubbleSize,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      positionGravity: PositionGravity.auto,
      overlayTitle: 'Widget Market overlay',
      overlayContent: 'Tap the bubble to open your widgets',
      notificationIcon: 'ic_stat_custom',
      dismissConfig: const OverlayDismissConfig(),
    );
    return true;
  }

  static Future<void> close() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
