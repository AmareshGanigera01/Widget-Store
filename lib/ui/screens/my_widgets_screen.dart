import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/installed_widget.dart';
import '../../models/widget_type.dart';
import '../../state/app_state.dart';
import '../components/widget_preview.dart';
import '../../services/overlay_controller.dart';
import '../icons.dart';
import 'widget_editor_screen.dart';
import 'widget_live_screen.dart';

String placementLabel(WidgetPlacement p) => switch (p) {
      WidgetPlacement.none => 'Not placed',
      WidgetPlacement.homeScreen => 'Home screen',
      WidgetPlacement.overlay => 'Overlay',
    };

class MyWidgetsScreen extends StatelessWidget {
  const MyWidgetsScreen({super.key});

  Future<void> _createBlank(BuildContext context) async {
    final type = await showModalBottomSheet<WidgetType>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Build a widget from scratch')),
            for (final t in WidgetType.values)
              ListTile(
                leading: Icon(iconFor(t.iconKey)),
                title: Text(t.label),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    final navigator = Navigator.of(context);
    final w = await context.read<MyWidgetsState>().createBlank(type);
    navigator.push(MaterialPageRoute(builder: (_) => WidgetEditorScreen(widgetId: w.id)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyWidgetsState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createBlank(context),
        icon: const Icon(Icons.add),
        label: const Text('Build'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('My Widgets'), actions: [_OverlayToggle()]),
          if (state.loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (state.widgets.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No widgets yet.\nGet one from the Marketplace or tap Build.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: state.widgets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final w = state.widgets[i];
                  return Card.outlined(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => WidgetLiveScreen(widgetId: w.id)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: w.enabled ? 1 : 0.5,
                              child: WidgetPreview(type: w.type, config: w.config, compact: true),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Text(w.name, style: Theme.of(context).textTheme.titleMedium)),
                                Text(
                                  w.enabled ? placementLabel(w.placement) : 'Paused',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Starts or stops the floating overlay bubble.
class _OverlayToggle extends StatefulWidget {
  const _OverlayToggle();

  @override
  State<_OverlayToggle> createState() => _OverlayToggleState();
}

class _OverlayToggleState extends State<_OverlayToggle> with WidgetsBindingObserver {
  bool _active = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final active = await OverlayController.isActive();
    if (mounted) setState(() => _active = active);
  }

  Future<void> _toggle() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_active) {
      await OverlayController.close();
    } else {
      final ok = await OverlayController.show();
      if (!ok) {
        messenger.showSnackBar(const SnackBar(content: Text('Allow "Display over other apps" to use the overlay.')));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Overlay on. Tap the bubble from any app.')));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _active ? 'Turn off overlay' : 'Turn on overlay',
      isSelected: _active,
      icon: const Icon(Icons.picture_in_picture_alt_outlined),
      selectedIcon: const Icon(Icons.picture_in_picture_alt),
      onPressed: _toggle,
    );
  }
}
