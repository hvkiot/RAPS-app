// Main UDS dashboard with a TabBar (Read · Write · Profile).
// Uses TabBarView to keep all three tabs alive and switch between them.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/views/screens/device_scan_screen.dart';
import 'package:uds/views/widgets/read_tab.dart';
import 'package:uds/views/widgets/write_tab.dart';

class UdsScreen extends StatefulWidget {
  const UdsScreen({super.key});

  @override
  State<UdsScreen> createState() => _UdsScreenState();
}

class _UdsScreenState extends State<UdsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UdsController _udsController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _udsController = context.read<UdsController>();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _udsController.clearConsole();
        _udsController
            .resetWriteStatus(); // 🔄 Reset write button on tab switch
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _udsController.addListener(_onConnectionChanged);

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
    _tabController.dispose();
    _udsController.removeListener(_onConnectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uds = context.watch<UdsController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: AppBar(
          elevation: 0,
          leading: IconButton(
            tooltip: 'Profile',
            padding: const EdgeInsets.only(bottom: 0),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: Icon(Icons.account_circle_rounded, size: 32),
          ),
          centerTitle: true,
          title: const Text(
            'RAPS SERVICE TOOL',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Column(
              children: [
                // 🟢 ECU STATUS INDICATOR
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ECU STATUS: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white60,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          uds.isEcuOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: uds.isEcuOnline
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ConnectionStatusDot(isConnected: uds.isEcuOnline),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorWeight: 4,
                  indicatorColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  dividerColor: Colors.white24,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                  tabs: const [
                    Tab(
                      text: 'READ',
                      icon: Icon(Icons.download_rounded, size: 24),
                    ),
                    Tab(
                      text: 'WRITE',
                      icon: Icon(Icons.upload_rounded, size: 24),
                    ),
                  ],
                  enableFeedback: null,
                ),
              ],
            ),
          ),
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

            // ── Tab body (TabBarView replaces IndexedStack) ─────────────
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: const [ReadTab(), WriteTab()],
              ),
            ),
          ],
        ),
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
