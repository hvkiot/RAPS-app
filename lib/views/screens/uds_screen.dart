// views/screens/uds_screen.dart
// ---------------------------------------------------------------------------
// Main UDS dashboard with a BottomNavigationBar (Read · Write · Profile).
// Uses IndexedStack to keep all three tabs alive so console logs persist
// when switching between tabs.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uds/config/app_config.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/views/screens/device_scan_screen.dart';
import 'package:uds/views/widgets/read_tab.dart';
import 'package:uds/views/widgets/write_tab.dart';
import 'package:uds/views/widgets/profile_tab.dart';

class UdsScreen extends StatefulWidget {
  const UdsScreen({super.key});

  @override
  State<UdsScreen> createState() => _UdsScreenState();
}

class _UdsScreenState extends State<UdsScreen> {
  int _currentIndex = 0;
  late UdsController _udsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _udsController = context.read<UdsController>();
      _udsController.addListener(_onConnectionChanged); // <--- Attach listener

      // 🚀 Trigger initial status fetch if already connected
      if (_udsController.isConnected) {
        _udsController.fetchStatus();
      }
    });
  }

  void _onConnectionChanged() {
    if (!mounted) return;

    // Check both the controller and the mounted status
    if (!_udsController.isConnected) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DeviceScanScreen()),
        (route) => false,
      );
    } else {
      // 🟢 Automatically sync status when connection is re-established
      // The controller's internal flag will prevent infinite loops.
      _udsController.fetchStatus();
    }
  }

  @override
  void dispose() {
    _udsController.removeListener(_onConnectionChanged); // <--- Stop listening
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uds = context.watch<UdsController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('RAPS SERVICE TOOL'),
            const Spacer(),
            // 🟢 ECU STATUS INDICATOR
            Text(
              uds.isEcuOnline ? " ECU ONLINE" : " ECU OFFLINE",
              style: TextStyle(
                color: uds.isEcuOnline
                    ? AppConfig.emerald500
                    : AppConfig.rose500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Pulsing connection status dot
            _ConnectionStatusDot(isConnected: uds.isConnected),
            const SizedBox(width: 8),
            Text(
              uds.isConnected ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: uds.isConnected ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Loading indicator at top (below AppBar) ──────────────────
            if (uds.isLoading)
              LinearProgressIndicator(
                backgroundColor: theme.dividerColor,
                color: theme.colorScheme.primary,
                minHeight: 3,
              ),

            // ── Error banner ─────────────────────────────────────────────
            if (uds.error != null)
              _ErrorBanner(
                message: uds.error!,
                onDismiss: () {
                  // Show via SnackBar instead (non-critical)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(uds.error!)));
                },
              ),

            // ── Tab body (IndexedStack keeps all tabs alive) ─────────────
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [ReadTab(), WriteTab(), ProfileTab()],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom navigation bar ─────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.download_rounded),
            activeIcon: Icon(Icons.download_rounded),
            label: 'Read',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_rounded),
            activeIcon: Icon(Icons.upload_rounded),
            label: 'Write',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Pulsing green connection dot in the AppBar ───────────────────────────────
class _ConnectionStatusDot extends StatefulWidget {
  final bool isConnected;
  const _ConnectionStatusDot({required this.isConnected});

  @override
  State<_ConnectionStatusDot> createState() => _ConnectionStatusDotState();
}

class _ConnectionStatusDotState extends State<_ConnectionStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);

    return FadeTransition(
      opacity: widget.isConnected
          ? _controller.drive(Tween(begin: 0.4, end: 1.0))
          : const AlwaysStoppedAnimation(0.3),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isConnected ? green : Colors.grey,
          boxShadow: widget.isConnected
              ? [
                  BoxShadow(
                    color: green.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ── Inline error banner ──────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const _ErrorBanner({required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
