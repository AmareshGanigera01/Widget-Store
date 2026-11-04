import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reminder_service.dart';
import '../state/app_state.dart';
import 'screens/marketplace_screen.dart';
import 'screens/my_widgets_screen.dart';
import 'screens/notebooks_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final AppLifecycleListener _lifecycle;

  static const _pages = [MarketplaceScreen(), MyWidgetsScreen(), NotebooksScreen()];

  @override
  void initState() {
    super.initState();
    // The overlay and capture sheet write to the same database; refresh when
    // the user comes back to the app.
    _lifecycle = AppLifecycleListener(onResume: () {
      context.read<MyWidgetsState>().load();
      context.read<NotebooksState>().load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderService>().requestNotificationPermission();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Marketplace'),
          NavigationDestination(icon: Icon(Icons.widgets_outlined), selectedIcon: Icon(Icons.widgets), label: 'My Widgets'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Notebooks'),
        ],
      ),
    );
  }
}
