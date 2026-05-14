// views/screens/profile_screen.dart
// ---------------------------------------------------------------------------
// The PROFILE screen: shows connected device info, disconnect button,
// clear console, theme toggle (persisted), and app version.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/ble_controller.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/config/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bleCtrl = context.watch<BleController>();
    final udsCtrl = context.watch<UdsController>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deviceName = bleCtrl.connectedDevice?.advName ?? 'Unknown';
    final deviceMac = bleCtrl.connectedDevice?.remoteId.toString() ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE & SETTINGS'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Device info card ──────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Bluetooth icon with status ring
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: udsCtrl.isConnected
                            ? theme.colorScheme.secondary
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.bluetooth_connected_rounded, size: 36),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    deviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceMac,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: udsCtrl.isConnected
                          ? theme.colorScheme.secondary.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      udsCtrl.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: udsCtrl.isConnected
                            ? theme.colorScheme.secondary
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Actions card ──────────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                // Disconnect
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bluetooth_disabled_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  title: const Text('Disconnect'),
                  subtitle: Text(
                    'Return to device scanner',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await bleCtrl.disconnect();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/scan',
                        (r) => false,
                      );
                    }
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),

                // Clear console
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.amber,
                    ),
                  ),
                  title: const Text('Clear Console'),
                  subtitle: Text(
                    'Remove all log entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  onTap: () {
                    udsCtrl.clearConsole();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Console cleared')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Settings card ─────────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                // Theme toggle
                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    isDark ? 'Switch to light theme' : 'Switch to dark theme',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── App version ───────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'RAPS Service Tool  v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.black26,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
