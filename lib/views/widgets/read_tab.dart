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
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SELECT IDENTIFIER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: uds.selectedReadDid,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    items: UdsController.readOnlyDids.keys.map((name) {
                      final hex = UdsController.readOnlyDids[name]!;
                      return DropdownMenuItem(
                        value: name,
                        child: Text(
                          '$hex – $name',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: uds.isLoading
                        ? null
                        : (val) {
                            if (val != null) uds.setSelectedReadDid(val);
                          },
                  ),
                ],
              ),
            ),
          ),

          // ── Console (Expanded – takes remaining space) ─────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LogConsole(entries: uds.consoleEntries),
            ),
          ),

          // ── Read button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: uds.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(uds.isLoading ? 'READING…' : 'READ DID'),
                onPressed: uds.isLoading
                    ? null
                    : () {
                        final hex = UdsController
                            .readOnlyDids[uds.selectedReadDid];
                        if (hex != null) uds.readDid(hex);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
