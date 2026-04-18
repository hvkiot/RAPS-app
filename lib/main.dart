// main.dart
// ---------------------------------------------------------------------------
// Entry point – sets up MultiProvider (BleService → BleController,
// UdsController, ThemeProvider) and applies dark/light theme from
// ThemeProvider.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'controllers/ble_controller.dart';
import 'controllers/uds_controller.dart';
import 'config/theme_provider.dart';
import 'views/screens/device_scan_screen.dart';
import 'views/screens/uds_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // Core BLE service (non-ChangeNotifier)
        Provider(create: (_) => BleService()),

        // BLE controller – depends on BleService
        ChangeNotifierProxyProvider<BleService, BleController>(
          create: (context) => BleController(context.read<BleService>()),
          update: (context, bleService, previous) =>
              previous ?? BleController(bleService),
        ),

        // UDS controller – depends on BleService
        ChangeNotifierProxyProvider<BleService, UdsController>(
          create: (context) => UdsController(context.read<BleService>()),
          update: (context, bleService, previous) =>
              previous ?? UdsController(bleService),
        ),

        // Theme provider – persists dark/light choice
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const RapsApp(),
    ),
  );
}

class RapsApp extends StatefulWidget {
  const RapsApp({super.key});

  @override
  State<RapsApp> createState() => _RapsAppState();
}

class _RapsAppState extends State<RapsApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register the observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("📱 App Lifecycle State: $state");

    // 🚀 IMPROVEMENT: We ONLY disconnect when the app is fully CLOSED (detached).
    // Previously, we disconnected on 'paused', which killed the session when
    // you switched to another app to check logs.
    if (state == AppLifecycleState.detached) {
      final uds = Provider.of<UdsController>(context, listen: false);

      debugPrint("🔌 App closing: Disconnecting BLE...");
      uds.shutdownConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp when theme changes
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'RAPS Service Tool',
      debugShowCheckedModeBanner: false,

      // Theme setup – toggled via ThemeProvider
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Navigation routes
      initialRoute: '/scan',
      routes: {
        '/scan': (context) => const DeviceScanScreen(),
        '/uds': (context) => const UdsScreen(),
      },
    );
  }
}
