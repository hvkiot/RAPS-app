// main.dart
// ---------------------------------------------------------------------------
// Entry point – sets up MultiProvider (BleService → BleController,
// UdsController, ThemeProvider) and applies dark/light theme from
// ThemeProvider.
// ---------------------------------------------------------------------------

import 'dart:async';

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
  Timer? _backgroundDisconnectTimer;
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

    final uds = Provider.of<UdsController>(context, listen: false);

    if (state == AppLifecycleState.paused) {
      // ⏳ Start a "Grace Period" timer (e.g., 2 minutes)
      // This keeps the connection alive if you're just switching apps briefly.
      debugPrint("⏳ App backgrounded: Starting 2-minute disconnect timer...");
      _backgroundDisconnectTimer = Timer(const Duration(minutes: 2), () {
        debugPrint("🔌 Background timeout reached: Auto-disconnecting...");
        uds.shutdownConnection();
      });
    } else if (state == AppLifecycleState.resumed) {
      // 🛑 Cancel the timer if the user comes back quickly
      if (_backgroundDisconnectTimer?.isActive ?? false) {
        debugPrint("✅ User returned: Disconnect timer cancelled.");
        _backgroundDisconnectTimer?.cancel();
      }
    } else if (state == AppLifecycleState.detached) {
      // 🚨 Final emergency cleanup
      debugPrint("🔌 App closing: Immediate cleanup.");
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
