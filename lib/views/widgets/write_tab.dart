// views/widgets/write_tab.dart
// ---------------------------------------------------------------------------
// The WRITE tab of the UDS dashboard. Contains a DID dropdown, text/hex mode
// toggle, value input field, an Expanded LogConsole, and a Write button.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uds/controllers/uds_controller.dart';
import 'package:uds/utils/hex_formatter.dart';
import 'package:uds/views/widgets/log_console.dart';

class WriteTab extends StatefulWidget {
  const WriteTab({super.key});

  @override
  State<WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<WriteTab> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// Byte-length required for the currently selected writable DID.
  int _requiredLength(UdsController uds) {
    final hex = UdsController.writableDids[uds.selectedWriteDid];
    if (hex == null) return 0;
    return getRequiredLength(hex);
  }

  @override
  Widget build(BuildContext context) {
    final uds = context.watch<UdsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reqLen = _requiredLength(uds);
    final selectedHex = UdsController.writableDids[uds.selectedWriteDid] ?? "";
    bool isNumeric = isNumericDid(selectedHex);

    bool canWrite = false;
    String? lengthError;

    if (uds.writeInputText.isNotEmpty) {
      if (uds.currentInputMode == 'DEC') {
        canWrite = true; // Decimals can be any length (backend handles it)
      } else {
        int requiredChars = uds.currentInputMode == 'TEXT'
            ? reqLen
            : reqLen * 2;
        if (uds.writeInputText.length < requiredChars) {
          lengthError =
              'Must be exactly $requiredChars characters (Current: ${uds.writeInputText.length})';
        } else {
          canWrite = true; // Length is perfectly matched!
        }
      }
    }

    return AbsorbPointer(
      absorbing: uds.isLoading,
      child: Column(
        children: [
          // ── DID dropdown + mode toggle + input field inside a Card ─────
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Label
                  Text(
                    'TARGET IDENTIFIER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: uds.selectedWriteDid,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    items: UdsController.writableDids.keys.map((name) {
                      final hex = UdsController.writableDids[name]!;
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
                            if (val != null) {
                              uds.setSelectedWriteDid(val);
                              _valueController.clear();
                            }
                          },
                  ),
                  const SizedBox(height: 14),

                  // Text / Hex toggle
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'TEXT',
                        label: const Text('TEXT'),
                        enabled: !isNumeric,
                      ),
                      const ButtonSegment(value: 'HEX', label: Text('HEX')),
                      ButtonSegment(
                        value: 'DEC',
                        label: Text('DEC'),
                        enabled: isNumeric,
                      ),
                    ],
                    selected: {uds.currentInputMode},
                    onSelectionChanged: (sel) {
                      uds.setInputMode(sel.first);
                      _valueController.clear();
                    },
                  ),
                  const SizedBox(height: 14),

                  // Value input
                  TextField(
                    controller: _valueController,
                    keyboardType: uds.currentInputMode == 'DEC'
                        ? TextInputType.number
                        : TextInputType.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: uds.currentInputMode == 'TEXT'
                          ? 'Enter Text (max $reqLen chars)'
                          : uds.currentInputMode == 'DEC'
                          ? 'Enter Decimal Number (e.g. 15000)'
                          : 'Enter HEX (max ${reqLen * 2} chars)',
                      hintText: uds.currentInputMode == 'TEXT'
                          ? 'e.g. CCM1100S-123'
                          : uds.currentInputMode == 'DEC'
                          ? 'e.g. 1000'
                          : 'e.g. 03E8',
                      errorText: lengthError,
                    ),
                    maxLength: uds.currentInputMode == 'TEXT'
                        ? reqLen
                        : uds.currentInputMode == 'DEC'
                        ? null // No strict char limit for DEC math, the backend handles padding
                        : reqLen * 2,

                    // 🛑 Force strict input rules
                    inputFormatters: [
                      if (uds.currentInputMode == 'HEX') HexInputFormatter(),
                      if (uds.currentInputMode == 'DEC')
                        FilteringTextInputFormatter
                            .digitsOnly, // ONLY allow 0-9
                    ],
                    onChanged: (val) => uds.setWriteInputText(val),
                  ),
                ],
              ),
            ),
          ),

          // ── Console (Expanded) ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LogConsole(entries: uds.consoleEntries),
            ),
          ),

          // ── Write button + status LED ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E), // rose
                    ),
                    icon: uds.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload_rounded),
                    label: Text(uds.isLoading ? 'WRITING…' : 'WRITE DID'),
                    onPressed: (uds.isLoading || !canWrite)
                        ? null
                        : () {
                            final hexDid = UdsController
                                .writableDids[uds.selectedWriteDid];
                            if (hexDid != null) {
                              uds.writeDid(hexDid, _valueController.text);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 16),
                // Write-OK LED
                _WriteOkLed(isActive: uds.writeSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing "WRITE OK" LED indicator ─────────────────────────────────────────
class _WriteOkLed extends StatefulWidget {
  final bool isActive;
  const _WriteOkLed({required this.isActive});

  @override
  State<_WriteOkLed> createState() => _WriteOkLedState();
}

class _WriteOkLedState extends State<_WriteOkLed>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color(0xFF10B981);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.isActive
            ? FadeTransition(
                opacity: _ctrl,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green,
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
        const SizedBox(width: 8),
        Text(
          'WRITE OK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}
