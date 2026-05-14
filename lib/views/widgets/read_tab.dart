// views/widgets/read_tab.dart
// ---------------------------------------------------------------------------
// The READ tab of the UDS dashboard. Contains a DID dropdown, an Expanded
// LogConsole, and a Read button at the bottom. All interactive widgets are
// disabled while UdsController.isLoading is true.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/views/widgets/log_console.dart';

class ReadTab extends StatelessWidget {
  const ReadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uds = context.watch<UdsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AbsorbPointer(
      absorbing: uds.isLoading,
      child: Column(
        children: [
          // ── DID dropdown inside a Card ──────────────────────────────────
          Card(
            margin: const EdgeInsets.all(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT IDENTIFIER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: uds.selectedReadDid,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                    items: UdsController.readOnlyDids.keys.map((name) {
                      final hex = UdsController.readOnlyDids[name]!;
                      return DropdownMenuItem(
                        value: name,
                        child: Text('$hex – $name'),
                      );
                    }).toList(),
                    onChanged: uds.isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              uds.setSelectedReadDid(val);
                              // 🚀 Auto-trigger read on selection
                              final hex = UdsController.readOnlyDids[val];
                              if (hex != null) uds.readDid(hex);
                            }
                          },
                  ),
                  if (uds.isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      minHeight: 2,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Console (Expanded) ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: LogConsole(entries: uds.consoleEntries),
            ),
          ),
        ],
      ),
    );
  }
}
