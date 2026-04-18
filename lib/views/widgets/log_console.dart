// views/widgets/log_console.dart
// ---------------------------------------------------------------------------
// A scrollable, color-coded diagnostic console that displays ConsoleEntry
// items with timestamps, status icons, hex data, and ASCII decoded values.
// Auto-scrolls to the bottom whenever a new entry is added.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:uds/models/console_entry.dart';

class LogConsole extends StatefulWidget {
  final List<ConsoleEntry> entries;

  const LogConsole({super.key, required this.entries});

  @override
  State<LogConsole> createState() => _LogConsoleState();
}

class _LogConsoleState extends State<LogConsole> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LogConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll when new entries arrive
    if (widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Console background – black in dark mode, light grey in light mode
    final bgColor = isDark ? Colors.black : const Color(0xFFEEEEEE);
    final emptyTextColor = isDark ? Colors.white24 : Colors.black26;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: widget.entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.terminal_rounded, size: 32, color: emptyTextColor),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for ECU response…',
                    style: TextStyle(
                      color: emptyTextColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: widget.entries.length,
              itemBuilder: (context, index) {
                return _ConsoleEntryTile(entry: widget.entries[index]);
              },
            ),
    );
  }
}

// ── Individual log entry row ─────────────────────────────────────────────────
class _ConsoleEntryTile extends StatelessWidget {
  final ConsoleEntry entry;
  const _ConsoleEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            '[${entry.timeString}] ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: isDark ? Colors.white24 : Colors.black38,
            ),
          ),

          // Status icon
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 1),
            child: Icon(entry.icon, size: 14, color: entry.color),
          ),

          // Message + hex + ASCII
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary message
                Text(
                  entry.message,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: entry.color,
                  ),
                ),

                // Hex data (if present)
                if (entry.hexData != null && entry.hexData!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      'HEX: ${entry.hexData}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                  ),

                // ASCII decoded value (if present)
                if (entry.asciiValue != null && entry.asciiValue!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: SelectableText(
                      'VAL: ${entry.asciiValue}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable error banner (kept for backward compatibility) ──────────────────
Widget buildErrorBanner(String message) {
  return Builder(builder: (context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
