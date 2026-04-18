// views/screens/device_scan_screen.dart
// ---------------------------------------------------------------------------
// Scans for BLE peripherals, displays them in a polished list, and navigates
// to UdsScreen on successful connection (replacing the back stack).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/ble_controller.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Auto-start scanning when screen opens IF services are ON
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleController>();
      if (ble.isBluetoothOn && ble.isLocationEnabled) {
        ble.startScan();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleController = context.watch<BleController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isBluetoothOn = bleController.isBluetoothOn;
    final isLocationOn = bleController.isLocationEnabled;
    final arePermissionsGranted = bleController.arePermissionsGranted;
    final servicesRequired =
        !isBluetoothOn || !isLocationOn || !arePermissionsGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text("RAPS SERVICE TOOL"),
        centerTitle: true,
        actions: [
          if (bleController.isScanning && !servicesRequired)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!servicesRequired)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Rescan',
              onPressed: () => bleController.startScan(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (servicesRequired)
              Expanded(
                child: _ServicesRequiredView(
                  isBluetoothOn: isBluetoothOn,
                  isLocationOn: isLocationOn,
                  arePermissionsGranted: arePermissionsGranted,
                  onTurnOnBluetooth: () => bleController.turnOnBluetooth(),
                  onOpenLocationSettings: () =>
                      bleController.openLocationSettings(),
                  onGrantPermissions: () =>
                      bleController.checkAndRequestPermissions(),
                ),
              )
            else ...[
              // ── Scanning indicator ────────────────────────────────────────
              if (bleController.isScanning)
                LinearProgressIndicator(
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  color: theme.colorScheme.primary,
                ),

              // ── Error banner ──────────────────────────────────────────────
              if (bleController.errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bleController.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Hero section ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _pulseController.drive(
                        Tween(begin: 0.4, end: 1.0),
                      ),
                      child: Image.asset(
                        'assets/Logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      bleController.isScanning
                          ? 'Scanning for devices…'
                          : bleController.scannedDevices.isEmpty
                          ? 'No devices found'
                          : '${bleController.scannedDevices.length} device(s) found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Device list ───────────────────────────────────────────────
              Expanded(
                child: bleController.scannedDevices.isEmpty
                    ? Center(
                        child: Text(
                          bleController.isScanning
                              ? 'Listening for BLE advertisements…'
                              : 'Tap refresh to scan again',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: bleController.scannedDevices.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final device = bleController.scannedDevices[index];
                          final isConnecting =
                              bleController.status ==
                              ConnectionStatus.connecting;

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.bluetooth_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                device.name.isNotEmpty
                                    ? device.name
                                    : 'Unknown Device',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                device.id,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                              trailing: isConnecting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                    ),
                              onTap: isConnecting
                                  ? null
                                  : () async {
                                      await bleController.connect(device);
                                      if (context.mounted &&
                                          bleController.status ==
                                              ConnectionStatus.connected) {
                                        // Replace back-stack so Back exits the app
                                        if (context.mounted) {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/uds',
                                          );
                                        }
                                      }
                                    },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServicesRequiredView extends StatelessWidget {
  final bool isBluetoothOn;
  final bool isLocationOn;
  final bool arePermissionsGranted;
  final VoidCallback onTurnOnBluetooth;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onGrantPermissions;

  const _ServicesRequiredView({
    required this.isBluetoothOn,
    required this.isLocationOn,
    required this.arePermissionsGranted,
    required this.onTurnOnBluetooth,
    required this.onOpenLocationSettings,
    required this.onGrantPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: ListView(
        children: [
          Image.asset(
            'assets/Logo.png',
            height: 100,
            opacity: const AlwaysStoppedAnimation(0.5),
          ),
          const SizedBox(height: 32),
          Text(
            'Services Required',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To scan for RAPS hardware, both Bluetooth and Location must be enabled and permissions granted.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 40),
          _ServiceTile(
            title: 'Permissions',
            subtitle: arePermissionsGranted ? 'Granted' : 'Denied',
            isOn: arePermissionsGranted,
            buttonLabel: 'GRANT',
            onPressed: onGrantPermissions,
          ),
          const SizedBox(height: 16),
          _ServiceTile(
            title: 'Bluetooth',
            subtitle: isBluetoothOn ? 'Enabled' : 'Disabled',
            isOn: isBluetoothOn,
            buttonLabel: 'TURN ON',
            onPressed: onTurnOnBluetooth,
          ),
          const SizedBox(height: 16),
          _ServiceTile(
            title: 'Location Service',
            subtitle: isLocationOn ? 'Enabled' : 'Disabled',
            isOn: isLocationOn,
            buttonLabel: 'SETTINGS',
            onPressed: onOpenLocationSettings,
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOn;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ServiceTile({
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isOn ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isOn
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (!isOn)
              TextButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
