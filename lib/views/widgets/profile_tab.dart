// views/widgets/profile_tab.dart
// ---------------------------------------------------------------------------
// The PROFILE tab: shows connected device info, disconnect button,
// clear console, theme toggle (persisted), and app version.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/ble_controller.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/config/theme_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bleCtrl = context.watch<BleController>();
    final udsCtrl = context.watch<UdsController>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deviceName = bleCtrl.connectedDevice?.advName ?? 'Unknown';
    final deviceMac = bleCtrl.connectedDevice?.remoteId.toString() ?? '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Device info card ──────────────────────────────────────────────
        Card(
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
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/Logo.png', fit: BoxFit.cover),
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
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    udsCtrl.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: udsCtrl.isConnected
                          ? const Color(0xFF10B981)
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
          child: Column(
            children: [
              // Disconnect
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bluetooth_disabled_rounded,
                    color: Color(0xFFF43F5E),
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
                    Navigator.pushReplacementNamed(context, '/scan');
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Color(0xFFF59E0B),
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
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
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
    );
  }
}
