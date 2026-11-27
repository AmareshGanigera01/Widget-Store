import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'capture/capture_app.dart';
import 'data/app_database.dart';
import 'data/repository_factory.dart';
import 'data/repositories.dart';
import 'overlay/overlay_app.dart';
import 'services/auth_service.dart';
import 'services/reminder_service.dart';
import 'services/runtime_sync.dart';
import 'state/app_state.dart';
import 'ui/home_shell.dart';
import 'ui/screens/login_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.instance();

  // Check if we already have a saved JWT token from a previous login
  final savedToken = await AuthService().getToken();

  // Configuration: switch to API backend for marketplace
  // Set to false to use local SQLite only, true to use FastAPI backend
  const useApiBackend = bool.fromEnvironment('USE_API_BACKEND', defaultValue: false);
  const envAuthToken = String.fromEnvironment('API_AUTH_TOKEN', defaultValue: '');
  
  final activeToken = savedToken ?? (envAuthToken.isEmpty ? null : envAuthToken);

  final factory = RepositoryFactory(
    useApiBackend: useApiBackend,
    apiAuthToken: activeToken,
  );

  final progress = factory.createProgressRepository(db);
  final reminders = ReminderService(progress);
  final market = MarketplaceState(factory.createMarketplaceRepository(db));
  final myWidgets = MyWidgetsState(factory.createWidgetRepository(db), RuntimeSync(reminders));
  final notebooks = NotebooksState(factory.createNotebookRepository(db));
  
  // Loaded in the background; screens show a spinner until ready.
  market.load();
  myWidgets.load();
  notebooks.load();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: progress),
        Provider.value(value: reminders),
        ChangeNotifierProvider.value(value: market),
        ChangeNotifierProvider.value(value: myWidgets),
        ChangeNotifierProvider.value(value: notebooks),
      ],
      child: WidgetMarketApp(isLoggedIn: activeToken != null),
    ),
  );
}

/// Entry point for the floating overlay (started by flutter_overlay_window).
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

/// Entry point for CaptureActivity ("Send to Notebook" from other apps).
@pragma('vm:entry-point')
void captureMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CaptureApp());
}

class WidgetMarketApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const WidgetMarketApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Market',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      home: isLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}