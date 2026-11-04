import 'package:device_bridge/device_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/theme.dart';
import 'capture_sheet.dart';

/// UI for CaptureActivity: a bottom sheet over the app the text came from.
class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      home: const _CaptureHost(),
    );
  }
}

class _CaptureHost extends StatefulWidget {
  const _CaptureHost();

  @override
  State<_CaptureHost> createState() => _CaptureHostState();
}

class _CaptureHostState extends State<_CaptureHost> {
  CapturedText? _capture;
  String? _sourceLabel;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await DeviceBridge.pendingCapture();
    if (c == null) {
      _close();
      return;
    }
    final label = c.sourceApp == null ? null : await DeviceBridge.appLabel(c.sourceApp!);
    setState(() {
      _capture = c;
      _sourceLabel = label ?? c.sourceApp;
      _loaded = true;
    });
  }

  void _close() => SystemNavigator.pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Taps on the sheet shouldn't close it.
            child: SafeArea(
              child: Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: !_loaded
                    ? const Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_note),
                                const SizedBox(width: 8),
                                Text('Send to Notebook', style: Theme.of(context).textTheme.labelLarge),
                                const Spacer(),
                                if (_sourceLabel != null)
                                  Flexible(
                                    child: Text('from $_sourceLabel',
                                        style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                            ),
                          ),
                          CaptureSheet(text: _capture!.text, sourceApp: _sourceLabel, onDone: (_) => _close()),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
